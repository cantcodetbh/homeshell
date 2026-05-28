#!/usr/bin/env python3
import json
import sys
import calendar
import os
import re
import shutil
import subprocess
import time
from datetime import datetime
from pathlib import Path


HOME = Path.home()
PROJECT_DIR = Path(__file__).resolve().parents[1]
CACHE_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "qs-homeshell"
CACHE_DIR.mkdir(parents=True, exist_ok=True)
WEATHER_PREVIEW_PATH = PROJECT_DIR / "state" / "weather-preview.json"


def hyprland_env():
    env = os.environ.copy()
    if env.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return env

    runtime_dir = Path(env.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    hypr_root = runtime_dir / "hypr"
    instances = []
    try:
        for item in hypr_root.iterdir():
            socket = item / ".socket.sock"
            if socket.exists():
                instances.append((socket.stat().st_mtime, item.name))
    except Exception:
        return env

    if instances:
        instances.sort(reverse=True)
        env["HYPRLAND_INSTANCE_SIGNATURE"] = instances[0][1]
    return env


def run(cmd, timeout=2, env=None):
    if shutil.which(cmd[0]) is None:
        return ""
    try:
        proc = subprocess.run(cmd, text=True, capture_output=True, timeout=timeout, env=env)
    except Exception:
        return ""
    if proc.returncode != 0:
        return ""
    return proc.stdout.strip()


def run_json(cmd, fallback, timeout=2):
    env = hyprland_env() if cmd and cmd[0] == "hyprctl" else None
    out = run(cmd, timeout=timeout, env=env)
    if not out:
        return fallback
    try:
        return json.loads(out)
    except Exception:
        return fallback


def cached_json(name, max_age, producer):
    path = CACHE_DIR / f"{name}.json"
    try:
        if path.exists() and time.time() - path.stat().st_mtime < max_age:
            return json.loads(path.read_text())
    except Exception:
        pass
    value = producer()
    try:
        path.write_text(json.dumps(value, separators=(",", ":")))
    except Exception:
        pass
    return value


def strip_markup(text):
    return re.sub(r"<[^>]+>", "", text or "").strip()


def normalize_class(value):
    if isinstance(value, list):
        return " ".join(str(item) for item in value)
    return str(value or "")


def quickshell_weather_icon(raw_text, tooltip):
    text = f"{raw_text} {tooltip}".lower()
    if "thunder" in text or "storm" in text:
        return ""
    if any(word in text for word in ("snow", "sleet", "ice", "blizzard")):
        return ""
    if any(word in text for word in ("heavy rain", "moderate rain", "shower")):
        return ""
    if any(word in text for word in ("light rain", "drizzle", "rain")):
        return ""
    if any(word in text for word in ("fog", "mist", "haze")):
        return ""
    if "cloud" in text or "overcast" in text:
        return "☁"
    if "clear" in text or "sunny" in text or "sun" in text:
        return "☀"
    return ""


def first_text(value, default=""):
    if isinstance(value, list) and value:
        item = value[0]
        if isinstance(item, dict):
            return str(item.get("value", default))
    return default


def is_daytime(astronomy):
    try:
        sunrise = time.strptime(str(astronomy.get("sunrise", "06:00 AM")), "%I:%M %p")
        sunset = time.strptime(str(astronomy.get("sunset", "06:00 PM")), "%I:%M %p")
        now = time.localtime()
        now_minutes = now.tm_hour * 60 + now.tm_min
        sunrise_minutes = sunrise.tm_hour * 60 + sunrise.tm_min
        sunset_minutes = sunset.tm_hour * 60 + sunset.tm_min
        return sunrise_minutes <= now_minutes < sunset_minutes
    except Exception:
        hour = time.localtime().tm_hour
        return 7 <= hour < 19


def weather_icon_name(code, desc, day):
    code = str(code or "")
    desc = str(desc or "").lower()
    if code == "113":
        return "clear-day" if day else "clear-night"
    if code == "116":
        return "partly-cloudy-day" if day else "partly-cloudy-night"
    if code in {"119"}:
        return "cloudy"
    if code in {"122"}:
        return "overcast"
    if code in {"143", "248", "260"} or any(word in desc for word in ("fog", "mist")):
        return "fog"
    if code in {"176", "263", "266", "293", "296", "353"}:
        return "drizzle"
    if code in {"179", "182", "185", "281", "284", "311", "314", "317", "350", "362", "365", "374", "377"}:
        return "sleet"
    if code in {"227", "230", "320", "323", "326", "329", "332", "335", "338", "368", "371", "392", "395"}:
        return "snow"
    if code in {"200", "386", "389"} or "thunder" in desc:
        return "thunderstorms-rain" if "rain" in desc else "thunderstorms"
    if code in {"299", "302", "305", "308", "356", "359"} or "rain" in desc:
        return "rain"
    return "not-available"


def moon_icon_name(phase):
    key = re.sub(r"\s+", " ", str(phase or "")).strip().lower()
    return {
        "new moon": "moon-new",
        "waxing crescent": "moon-waxing-crescent",
        "first quarter": "moon-first-quarter",
        "waxing gibbous": "moon-waxing-gibbous",
        "full moon": "moon-full",
        "waning gibbous": "moon-waning-gibbous",
        "last quarter": "moon-last-quarter",
        "waning crescent": "moon-waning-crescent",
    }.get(key, "moon-new")


def forecast_days(raw):
    days = []
    weather_days = raw.get("weather", []) if isinstance(raw, dict) else []
    for item in weather_days[1:4]:
        if not isinstance(item, dict):
            continue
        hourly = item.get("hourly", [])
        sample = hourly[4] if isinstance(hourly, list) and len(hourly) > 4 else (hourly[0] if isinstance(hourly, list) and hourly else {})
        desc = first_text(sample.get("weatherDesc"), "weather") if isinstance(sample, dict) else "weather"
        rain = str(sample.get("chanceofrain", "")) if isinstance(sample, dict) else ""
        snow = str(sample.get("chanceofsnow", "")) if isinstance(sample, dict) else ""
        precip = ""
        if snow and snow != "0":
            precip = f"snow {snow}%"
        elif rain and rain != "0":
            precip = f"rain {rain}%"
        else:
            precip = "dry"
        try:
            day = datetime.strptime(str(item.get("date", "")), "%Y-%m-%d").strftime("%a").lower()
        except Exception:
            day = str(item.get("date", "day"))
        high = str(item.get("maxtempC", "--"))
        low = str(item.get("mintempC", "--"))
        days.append({
            "day": day,
            "temp": f"{low}-{high}°",
            "detail": f"{desc.strip()} | {precip}",
        })
    return days


def weather_detail_text(tooltip, forecast):
    lines = [line for line in str(tooltip or "").splitlines() if line.strip()]
    if forecast:
        lines.append("")
        for item in forecast:
            lines.append(f"{item.get('day', 'day')} {item.get('temp', '--')} - {item.get('detail', 'weather')}")
    return "\n".join(lines)


def hyprland_status():
    workspaces_raw = run_json(["hyprctl", "workspaces", "-j"], [])
    active = run_json(["hyprctl", "activeworkspace", "-j"], {})
    window = run_json(["hyprctl", "activewindow", "-j"], {})
    clients = run_json(["hyprctl", "clients", "-j"], [])
    active_id = active.get("id") if isinstance(active, dict) else None
    active_address = window.get("address") if isinstance(window, dict) else ""
    clients_by_workspace = {}
    for client in clients if isinstance(clients, list) else []:
        workspace = client.get("workspace", {}) if isinstance(client, dict) else {}
        wid = workspace.get("id") if isinstance(workspace, dict) else None
        if not isinstance(wid, int) or wid < 1:
            continue
        title = re.sub(r"^[\u2800-\u28ff]\s*", "", str(client.get("title") or client.get("class") or "")).strip()
        address = str(client.get("address") or "")
        clients_by_workspace.setdefault(wid, []).append({
            "title": title[:80] if title else "untitled",
            "class": str(client.get("class") or "app")[:32],
            "address": address,
            "active": bool(address and address == active_address),
            "x": int((client.get("at") or [0, 0])[0] or 0),
            "y": int((client.get("at") or [0, 0])[1] or 0),
            "w": max(1, int((client.get("size") or [640, 360])[0] or 640)),
            "h": max(1, int((client.get("size") or [640, 360])[1] or 360)),
            "floating": bool(client.get("floating")),
            "fullscreen": bool(client.get("fullscreen")),
        })
    seen = set()
    workspaces = []
    for item in workspaces_raw if isinstance(workspaces_raw, list) else []:
        wid = item.get("id")
        if not isinstance(wid, int) or wid < 1:
            continue
        seen.add(wid)
        workspaces.append({
            "id": wid,
            "name": str(item.get("name") or wid),
            "windows": int(item.get("windows") or 0),
            "clients": clients_by_workspace.get(wid, []),
            "active": wid == active_id,
            "urgent": bool(item.get("urgent")),
        })
    for wid in range(1, 6):
        if wid not in seen:
            workspaces.append({"id": wid, "name": str(wid), "windows": 0, "clients": clients_by_workspace.get(wid, []), "active": wid == active_id, "urgent": False})
    workspaces.sort(key=lambda item: item["id"])
    title = ""
    if isinstance(window, dict):
        title = window.get("title") or window.get("class") or ""
    title = re.sub(r"^[\u2800-\u28ff]\s*", "", title).strip()
    return {
        "workspaces": workspaces[:9],
        "window": title[:96] if title else "HomeShell",
    }


def audio_status():
    mute = run(["pactl", "get-sink-mute", "@DEFAULT_SINK@"])
    volume = run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"])
    muted = "yes" in mute.lower()
    match = re.search(r"(\d+)%", volume)
    pct = int(match.group(1)) if match else 0
    if muted:
        icon = ""
    elif pct < 33:
        icon = ""
    elif pct < 67:
        icon = ""
    else:
        icon = ""
    return {"text": f"{icon} {pct}%", "icon": icon, "muted": muted, "volume": pct}


def network_status():
    out = run(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev", "status"])
    interfaces = []
    for line in out.splitlines():
        parts = line.split(":", 3)
        if len(parts) < 4:
            continue
        dev, kind, state, conn = parts
        if kind not in {"loopback"} and state.startswith("connected"):
            interfaces.append({"device": dev, "kind": kind, "state": state, "connection": conn})
    vpn_items = [item for item in interfaces if item["kind"] in {"tun", "wireguard"} or "tailscale" in item["device"].lower()]
    for line in out.splitlines():
        parts = line.split(":", 3)
        if len(parts) < 4:
            continue
        dev, kind, state, conn = parts
        if state != "connected":
            continue
        ip_out = run(["ip", "-4", "-o", "addr", "show", "dev", dev])
        match = re.search(r"\binet\s+([0-9.]+)/", ip_out)
        ip_addr = match.group(1) if match else ""
        route = run(["ip", "route", "show", "default"])
        gateway = ""
        route_match = re.search(r"\bvia\s+([0-9.]+)", route)
        if route_match:
            gateway = route_match.group(1)
        dns = run(["sh", "-lc", "resolvectl dns 2>/dev/null | sed -n '1p' | cut -d: -f2- | xargs"], timeout=1)
        if kind == "wifi":
            signal = run(["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID", "dev", "wifi"])
            sig = ""
            ssid = conn
            for row in signal.splitlines():
                if row.startswith("*:"):
                    bits = row.split(":", 2)
                    sig = bits[1] if len(bits) > 1 else ""
                    ssid = bits[2] if len(bits) > 2 else conn
                    break
            return {
                "text": f"󰤨   {sig}%" if sig else f"󰤨   {ssid}",
                "kind": kind,
                "detail": ssid,
                "device": dev,
                "connection": conn,
                "ip": ip_addr,
                "gateway": gateway,
                "dns": dns,
                "signal": sig,
                "interfaces": interfaces[:8],
                "vpn": vpn_items[:4],
            }
        if kind == "ethernet":
            return {
                "text": f"󰈀  {ip_addr or dev}",
                "kind": kind,
                "detail": conn or dev,
                "device": dev,
                "connection": conn,
                "ip": ip_addr,
                "gateway": gateway,
                "dns": dns,
                "interfaces": interfaces[:8],
                "vpn": vpn_items[:4],
            }
    return {"text": "Offline", "kind": "offline", "detail": "", "interfaces": interfaces[:8], "vpn": []}


def clipboard_status():
    out = run(["cliphist", "list"], timeout=1)
    items = []
    for line in out.splitlines()[:12]:
        ident, _, preview = line.partition("\t")
        if not ident:
            continue
        preview = strip_markup(preview).replace("\n", " ").strip()
        items.append({
            "id": ident,
            "preview": preview[:96] if preview else "clipboard item",
        })
    return {"count": len(items), "items": items}


def transfer_status():
    now = time.time()
    total_rx = total_tx = 0
    try:
        for line in Path("/proc/net/dev").read_text().splitlines()[2:]:
            name, values = line.split(":", 1)
            dev = name.strip()
            if dev == "lo" or dev.startswith(("veth", "br-", "docker")):
                continue
            parts = values.split()
            total_rx += int(parts[0])
            total_tx += int(parts[8])
    except Exception:
        pass
    cache = CACHE_DIR / "net-rate.json"
    rx_rate = tx_rate = 0
    try:
        old = json.loads(cache.read_text())
        elapsed = max(0.5, now - float(old.get("time", now)))
        rx_rate = max(0, round((total_rx - int(old.get("rx", total_rx))) / elapsed))
        tx_rate = max(0, round((total_tx - int(old.get("tx", total_tx))) / elapsed))
    except Exception:
        pass
    try:
        cache.write_text(json.dumps({"time": now, "rx": total_rx, "tx": total_tx}))
    except Exception:
        pass
    downloads_dir = HOME / "Downloads"
    recent = []
    if downloads_dir.exists():
        files = [p for p in downloads_dir.iterdir() if p.is_file()]
        for path in sorted(files, key=lambda p: p.stat().st_mtime, reverse=True)[:6]:
            recent.append({"name": path.name[:72], "path": str(path), "age": time.strftime("%H:%M", time.localtime(path.stat().st_mtime))})
    return {"rx": rx_rate, "tx": tx_rate, "rx_text": human_bytes(rx_rate) + "/s", "tx_text": human_bytes(tx_rate) + "/s", "downloads": recent}


def human_bytes(value):
    value = float(value or 0)
    for unit in ("B", "KB", "MB", "GB"):
        if value < 1024 or unit == "GB":
            return f"{value:.0f}{unit}" if unit == "B" else f"{value:.1f}{unit}"
        value /= 1024


def calendar_status():
    today = datetime.now()
    weeks = []
    for week in calendar.Calendar(firstweekday=0).monthdayscalendar(today.year, today.month):
        weeks.append([{"day": day, "today": day == today.day} for day in week])
    return {"month": today.strftime("%B %Y").lower(), "today": today.strftime("%a %d %b").lower(), "weeks": weeks}


def process_status():
    out = run(["ps", "-eo", "pid,comm,%cpu,%mem", "--sort=-%cpu"], timeout=1)
    rows = []
    for line in out.splitlines()[1:8]:
        parts = line.split(None, 3)
        if len(parts) < 4:
            continue
        rows.append({"pid": parts[0], "name": parts[1][:28], "cpu": parts[2], "mem": parts[3]})
    return {"items": rows}


def power_profile_status():
    profile = run(["powerprofilesctl", "get"], timeout=1) or "unknown"
    profiles = []
    out = run(["powerprofilesctl", "list"], timeout=1)
    for line in out.splitlines():
        clean = line.replace("*", "").strip()
        if clean.endswith(":"):
            profiles.append(clean[:-1])
    governor = ""
    try:
        governor = Path("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor").read_text().strip()
    except Exception:
        pass
    return {"profile": profile, "profiles": profiles[:4], "governor": governor}


def screenshot_status():
    roots = [HOME / "Pictures", HOME / "Pictures" / "Screenshots"]
    shots = []
    for root in roots:
        if not root.exists():
            continue
        for path in root.glob("screenshot_*"):
            if path.is_file() and path.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}:
                shots.append(path)
    items = []
    for path in sorted(set(shots), key=lambda p: p.stat().st_mtime, reverse=True)[:8]:
        items.append({"name": path.name[:72], "path": str(path), "time": time.strftime("%H:%M", time.localtime(path.stat().st_mtime))})
    return {"count": len(items), "items": items}


def memory_percent():
    values = {}
    try:
        for line in Path("/proc/meminfo").read_text().splitlines():
            key, value = line.split(":", 1)
            values[key] = int(value.strip().split()[0])
        total = values.get("MemTotal", 1)
        available = values.get("MemAvailable", 0)
        return round((1 - available / total) * 100)
    except Exception:
        return 0


def cpu_load():
    try:
        load = os.getloadavg()[0]
        cores = os.cpu_count() or 1
        return min(999, round(load / cores * 100))
    except Exception:
        return 0


def disk_percent():
    try:
        usage = shutil.disk_usage("/")
        return round(usage.used / usage.total * 100)
    except Exception:
        return 0


def language_status():
    devices = run_json(["hyprctl", "devices", "-j"], {})
    keyboards = devices.get("keyboards", []) if isinstance(devices, dict) else []
    chosen = {}
    for item in keyboards:
        if item.get("main"):
            chosen = item
            break
    if not chosen and keyboards:
        chosen = keyboards[0]
    layout = str(chosen.get("layout") or chosen.get("active_keymap") or "").upper()
    short = layout[:2] if layout else "K"
    return {"text": short, "detail": chosen.get("active_keymap", "")}


def battery_status():
    supplies = sorted(Path("/sys/class/power_supply").glob("BAT*"))
    if not supplies:
        return {"text": "", "present": False}
    bat = supplies[0]
    cap = (bat / "capacity").read_text().strip() if (bat / "capacity").exists() else "?"
    status = (bat / "status").read_text().strip() if (bat / "status").exists() else ""
    return {"text": f"BAT {cap}%", "present": True, "status": status}


def weather_status():
    if shutil.which("curl") is None:
        return {"text": "", "tooltip": "", "icon": ""}
    location = os.environ.get("BATTLEARCH_WEATHER_LOCATION", "")
    query = f"wttr.in/{location}" if location else "wttr.in"
    out = run(["curl", "-fsS", f"https://{query}?format=j1"], timeout=5)
    try:
        data = json.loads(out)
    except Exception:
        return {"text": "", "tooltip": "", "icon": ""}
    current = data.get("current_condition", [{}])[0] if isinstance(data, dict) else {}
    astronomy = data.get("weather", [{}])[0].get("astronomy", [{}])[0] if isinstance(data, dict) else {}
    desc = first_text(current.get("weatherDesc"), "")
    day = is_daytime(astronomy if isinstance(astronomy, dict) else {})
    icon_name = weather_icon_name(current.get("weatherCode", ""), desc, day)
    moon_phase = str(astronomy.get("moon_phase", "")) if isinstance(astronomy, dict) else ""
    moon_icon = moon_icon_name(moon_phase)
    forecast = forecast_days(data)
    temp = str(current.get("temp_C", "")).strip()
    feels = str(current.get("FeelsLikeC", "")).strip()
    place = first_text(data.get("nearest_area", [{}])[0].get("areaName"), "") if isinstance(data, dict) else ""
    raw_text = f"{temp}°" if temp else ""
    tooltip = "\n".join(item for item in [place, desc, f"Feels like {feels}°" if feels else ""] if item)
    status = {
        "text": raw_text,
        "icon": quickshell_weather_icon(raw_text, tooltip),
        "icon_name": icon_name,
        "icon_path": str(PROJECT_DIR / "theme" / "meteocons" / f"{icon_name}.svg"),
        "tooltip": tooltip,
        "detail": weather_detail_text(tooltip, forecast),
        "condition": desc,
        "class": icon_name,
        "sun": {
            "rise": str(astronomy.get("sunrise", "")) if isinstance(astronomy, dict) else "",
            "set": str(astronomy.get("sunset", "")) if isinstance(astronomy, dict) else "",
        },
        "forecast": forecast,
        "moon": {
            "phase": moon_phase,
            "illumination": str(astronomy.get("moon_illumination", "")) if isinstance(astronomy, dict) else "",
            "rise": str(astronomy.get("moonrise", "")) if isinstance(astronomy, dict) else "",
            "set": str(astronomy.get("moonset", "")) if isinstance(astronomy, dict) else "",
            "icon_name": moon_icon,
            "icon_path": str(PROJECT_DIR / "theme" / "meteocons" / f"{moon_icon}.svg"),
        },
    }
    try:
        preview = json.loads(WEATHER_PREVIEW_PATH.read_text())
        preview_icon = str(preview.get("icon_name", "")).strip()
        if preview_icon:
            status.update({
                "text": str(preview.get("text", "preview")),
                "icon": str(preview.get("icon", status["icon"])),
                "icon_name": preview_icon,
                "icon_path": str(PROJECT_DIR / "theme" / "meteocons" / f"{preview_icon}.svg"),
                "tooltip": str(preview.get("tooltip", f"Preview: {preview_icon}")),
                "class": str(preview.get("class", preview_icon)),
                "preview": True,
            })
    except Exception:
        pass
    return status


def updates_status():
    def produce():
        if shutil.which("checkupdates") is None:
            return {"text": "", "class": "", "available": False}
        out = run(["checkupdates"], timeout=8)
        count = len([line for line in out.splitlines() if line.strip()])
        text = str(count)
        return {
            "text": text,
            "class": "red" if count > 0 else "green",
            "tooltip": f"{count} package updates",
            "available": count > 0,
        }
    return cached_json("updates", 900, produce)

def notifications_status():
    return {"count": 0, "dnd": False, "native": True}


def wallpaper_status():
    out = run(["python3", str(PROJECT_DIR / "scripts" / "wallpaper-status.py")], timeout=3)
    try:
        return json.loads(out)
    except Exception:
        return {"directory": str(HOME / "Pictures" / "wallpapers"), "current": "", "count": 0, "items": []}


def theme_status(current_wallpaper=""):
    path = PROJECT_DIR / "theme" / "current.json"
    candidates_path = PROJECT_DIR / "state" / "theme-candidates.json"
    fallback = {
        "wallpaper": "",
        "selected_index": -1,
        "override": {},
        "candidates": [],
        "colors": {
            "base": "#15110f",
            "base_alt": "#241b18",
            "text": "#efe4dc",
            "muted": "#cdbeb4",
            "accent": "#a8c5c9",
            "amber": "#d7a86e",
            "red": "#b85f4d",
            "teal": "#7fa8a2",
        },
    }
    def load_theme():
        try:
            loaded = json.loads(path.read_text())
            return loaded if isinstance(loaded, dict) else {}
        except Exception:
            return {}

    def sync_wallpaper(wallpaper):
        if not wallpaper or not Path(wallpaper).is_file():
            return False
        stamp = CACHE_DIR / "theme-wallpaper-sync.stamp"
        try:
            if stamp.exists() and time.time() - stamp.stat().st_mtime < 4:
                return False
            stamp.write_text(str(time.time()))
        except Exception:
            pass
        try:
            proc = subprocess.run(
                [str(PROJECT_DIR / "scripts" / "sync-theme"), wallpaper],
                text=True,
                capture_output=True,
                timeout=30,
            )
            try:
                (CACHE_DIR / "theme-wallpaper-sync.log").write_text(
                    f"returncode={proc.returncode}\nstdout={proc.stdout}\nstderr={proc.stderr}\n"
                )
            except Exception:
                pass
            return proc.returncode == 0
        except Exception:
            return False

    data = load_theme()
    if current_wallpaper and str(data.get("wallpaper", "")) != current_wallpaper and sync_wallpaper(current_wallpaper):
        data = load_theme()
    if not data:
        return fallback
    colors = data.get("colors", {}) if isinstance(data, dict) else {}
    if not isinstance(colors, dict):
        return fallback
    merged = fallback["colors"].copy()
    for key, value in colors.items():
        if isinstance(value, str) and re.match(r"^#[0-9a-fA-F]{6}$", value):
            merged[key] = value
    result = {"wallpaper": str(data.get("wallpaper", "")), "colors": merged, "selected_index": -1, "selected_id": "", "override": {}, "candidates": []}

    def load_candidates():
        try:
            candidates_data = json.loads(candidates_path.read_text())
            if isinstance(candidates_data, dict) and str(candidates_data.get("wallpaper", "")) == result["wallpaper"]:
                selected_index = int(candidates_data.get("selected_index", -1))
                selected_id = str(candidates_data.get("selected_id", selected_index if selected_index >= 0 else ""))
                override = candidates_data.get("override", {}) if isinstance(candidates_data.get("override", {}), dict) else {}
                candidates = candidates_data.get("candidates", [])
                if isinstance(candidates, list):
                    selected_reason = str(candidates_data.get("selected_reason", ""))
                    return selected_index, selected_id, override, candidates, selected_reason
        except Exception:
            pass
        return -1, "", {}, [], ""

    def repair_candidates():
        wallpaper = result["wallpaper"]
        if not wallpaper or not Path(wallpaper).is_file():
            return False
        stamp = CACHE_DIR / "theme-candidate-repair.stamp"
        try:
            if stamp.exists() and time.time() - stamp.stat().st_mtime < 20:
                return False
            stamp.write_text(str(time.time()))
        except Exception:
            pass
        try:
            proc = subprocess.run(
                [str(PROJECT_DIR / "scripts" / "sync-theme"), wallpaper],
                text=True,
                capture_output=True,
                timeout=30,
            )
            try:
                (CACHE_DIR / "theme-candidate-repair.log").write_text(
                    f"returncode={proc.returncode}\nstdout={proc.stdout}\nstderr={proc.stderr}\n"
                )
            except Exception:
                pass
            return proc.returncode == 0
        except Exception:
            return False

    selected_index, selected_id, override, candidates, selected_reason = load_candidates()
    if not candidates and repair_candidates():
        selected_index, selected_id, override, candidates, selected_reason = load_candidates()

    result["selected_index"] = selected_index
    result["selected_id"] = selected_id
    result["override"] = override
    result["candidates"] = candidates
    result["selected_reason"] = selected_reason
    return result


def hypridle_status():
    script = HOME / ".config" / "hypr" / "scripts" / "hypridle.sh"
    if not script.exists():
        return {"text": "", "active": False, "available": False}
    out = run([str(script), "status"], timeout=3)
    if not out:
        return {"text": "", "active": False, "available": True}
    try:
        data = json.loads(out)
    except Exception:
        text = strip_markup(out)
        return {"text": text[:6] or "", "active": "notactive" not in text.lower(), "available": True}
    class_name = normalize_class(data.get("class", ""))
    text = strip_markup(str(data.get("text", "")))
    return {
        "text": "",
        "detail": text,
        "class": class_name,
        "active": "notactive" not in class_name,
        "available": True,
    }


def main():
    fast_mode = "--fast" in sys.argv
    hypr = hyprland_status()
    payload = {
        "ts": int(time.time()),
        "time": time.strftime("%H:%M %a"),
        "window": hypr["window"],
        "workspaces": hypr["workspaces"],
        "audio": audio_status(),
        "network": network_status(),
        "clipboard": clipboard_status(),
        "transfer": transfer_status(),
        "calendar": calendar_status(),
        "processes": process_status(),
        "power_profile": power_profile_status(),
        "screenshots": screenshot_status(),
        "notifications": notifications_status(),
        "hardware": {
            "cpu": cpu_load(),
            "memory": memory_percent(),
            "disk": disk_percent(),
            "language": language_status(),
        },
        "battery": battery_status(),
    }
    if not fast_mode:
        payload["weather"] = weather_status()
        payload["wallpaper"] = wallpaper_status()
        payload["theme"] = theme_status(payload["wallpaper"].get("current", ""))
        payload["updates"] = updates_status()
        payload["hypridle"] = hypridle_status()
    else:
        payload["theme"] = theme_status()
    print(json.dumps(payload))


if __name__ == "__main__":
    main()
