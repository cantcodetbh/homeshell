#!/usr/bin/env python3
import colorsys
import json
import math
import os
import random
import sys
import time
import warnings
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / "state" / "wallpaper-intel.json"
WALL_DIR = Path.home() / "Pictures" / "wallpapers"
SUFFIXES = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
warnings.filterwarnings("ignore", category=DeprecationWarning)


def image_metrics(path):
    try:
        from PIL import Image
        img = Image.open(path).convert("RGB")
        img.thumbnail((96, 64))
        pixels = list(img.getdata())
    except Exception:
        pixels = []

    if not pixels:
        return {
            "hue": 0.0,
            "saturation": 0.0,
            "value": 0.0,
            "mood": "unknown",
            "tags": filename_tags(path),
        }

    hue_x = 0.0
    hue_y = 0.0
    sat_total = 0.0
    val_total = 0.0
    weight_total = 0.0
    for r, g, b in pixels:
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        weight = max(0.05, s * v)
        hue_x += math.cos(h * math.tau) * weight
        hue_y += math.sin(h * math.tau) * weight
        sat_total += s * weight
        val_total += v * weight
        weight_total += weight

    hue = (math.atan2(hue_y, hue_x) / math.tau) % 1.0 if weight_total else 0.0
    saturation = sat_total / weight_total if weight_total else 0.0
    value = val_total / weight_total if weight_total else 0.0
    tags = filename_tags(path)
    mood = mood_label(hue, saturation, value, tags)
    return {
        "hue": round(hue, 4),
        "saturation": round(saturation, 4),
        "value": round(value, 4),
        "mood": mood,
        "tags": tags,
    }


def filename_tags(path):
    words = Path(path).stem.lower().replace("_", "-").split("-")
    stop = {"a", "an", "and", "the", "of", "in", "on", "with", "wide"}
    return [word for word in words if len(word) > 2 and word not in stop][:5]


def mood_label(hue, saturation, value, tags):
    tag_text = " ".join(tags)
    if any(word in tag_text for word in ("rain", "rainy", "storm", "dusk", "night")):
        return "moody"
    if any(word in tag_text for word in ("city", "street", "subway", "station")):
        return "urban"
    if any(word in tag_text for word in ("forest", "mountain", "valley", "desert", "seaside")):
        return "landscape"
    if value < 0.32:
        return "low light"
    if saturation < 0.22:
        return "muted"
    if hue < 0.10 or hue > 0.90:
        return "warm"
    if 0.45 < hue < 0.70:
        return "cool"
    return "balanced"


def hue_distance(a, b):
    diff = abs(a - b)
    return min(diff, 1.0 - diff)


def distance(first, second):
    return (
        hue_distance(first.get("hue", 0), second.get("hue", 0)) * 2.5
        + abs(first.get("saturation", 0) - second.get("saturation", 0)) * 0.9
        + abs(first.get("value", 0) - second.get("value", 0)) * 0.7
    )


def load_state():
    try:
        data = json.loads(STATE.read_text())
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def save_state(data):
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def wallpapers():
    if not WALL_DIR.exists():
        return []
    return sorted(path for path in WALL_DIR.iterdir() if path.is_file() and path.suffix.lower() in SUFFIXES)


def ensure_catalog(paths):
    data = load_state()
    catalog = data.get("catalog", {}) if isinstance(data.get("catalog"), dict) else {}
    changed = False
    for path in paths:
        key = str(path)
        try:
            stat_key = f"{path.stat().st_mtime_ns}:{path.stat().st_size}"
        except Exception:
            stat_key = ""
        item = catalog.get(key, {})
        if item.get("stat") != stat_key:
            metrics = image_metrics(path)
            catalog[key] = {"stat": stat_key, **metrics}
            changed = True
    valid = {str(path) for path in paths}
    for key in list(catalog.keys()):
        if key not in valid:
            del catalog[key]
            changed = True
    data["catalog"] = catalog
    if changed:
        save_state(data)
    return data


def choose(mode, current=""):
    paths = wallpapers()
    if not paths:
        raise SystemExit("no wallpapers found")
    data = ensure_catalog(paths)
    catalog = data.get("catalog", {})
    current = current if current and Path(current).exists() else str(paths[0])
    if mode == "next":
        try:
            current_idx = paths.index(Path(current))
        except ValueError:
            current_idx = 0
        return str(paths[(current_idx + 1) % len(paths)])

    if mode == "random":
        recent = data.get("recent", []) if isinstance(data.get("recent"), list) else []
        recent_set = set(recent[-10:])
        candidates = [path for path in paths if str(path) != current and str(path) not in recent_set]
        if not candidates:
            candidates = [path for path in paths if str(path) != current]
        if not candidates:
            return current
        return str(random.choice(candidates))

    current_metrics = catalog.get(current, image_metrics(current))
    recent = data.get("recent", []) if isinstance(data.get("recent"), list) else []
    recent_set = set(recent[-5:])

    scored = []
    for idx, path in enumerate(paths):
        key = str(path)
        metrics = catalog.get(key, {})
        if key == current:
            continue
        score = distance(metrics, current_metrics)
        if key in recent_set:
            score -= 0.45
        if metrics.get("mood") == current_metrics.get("mood"):
            score -= 0.22
        if mode == "next":
            try:
                current_idx = paths.index(Path(current))
            except ValueError:
                current_idx = 0
            forward = (idx - current_idx) % len(paths)
            score += max(0, 1.0 - (forward / max(1, len(paths)))) * 0.08
        scored.append((score, key, metrics))

    if not scored:
        return current
    scored.sort(reverse=True, key=lambda item: item[0])
    return scored[0][1]


def record(path):
    paths = wallpapers()
    data = ensure_catalog(paths)
    catalog = data.get("catalog", {})
    key = str(Path(path))
    recent = data.get("recent", []) if isinstance(data.get("recent"), list) else []
    recent = [item for item in recent if item != key][-11:] + [key]
    data["recent"] = recent
    data["last_reason"] = reason_for(key, catalog, recent)
    data["updated_at"] = int(time.time())
    save_state(data)
    return data["last_reason"]


def reason_for(path, catalog, recent):
    item = catalog.get(path, {})
    tags = item.get("tags", [])
    bits = []
    if item.get("mood"):
        bits.append(item["mood"])
    if tags:
        bits.append(", ".join(tags[:3]))
    if len(recent) > 1:
        prev = recent[-2]
        prev_item = catalog.get(prev, {})
        gap = distance(item, prev_item) if prev_item else 0
        if gap > 0.45:
            bits.append("different from last")
    return " | ".join(bits) if bits else "analysed"


def status(current=""):
    paths = wallpapers()
    data = ensure_catalog(paths)
    catalog = data.get("catalog", {})
    current = str(Path(current)) if current else ""
    return {
        "reason": data.get("last_reason", reason_for(current, catalog, data.get("recent", []))) if current else "",
        "current": catalog.get(current, {}),
        "recent": data.get("recent", [])[-5:] if isinstance(data.get("recent"), list) else [],
    }


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "status"
    current = sys.argv[2] if len(sys.argv) > 2 else ""
    if mode in {"next", "random"}:
        print(choose(mode, current))
    elif mode == "record":
        print(record(current))
    elif mode == "status":
        print(json.dumps(status(current), separators=(",", ":")))
    elif mode == "catalog":
        ensure_catalog(wallpapers())
    else:
        raise SystemExit("usage: wallpaper-intel.py [next|random|record|status|catalog] [current]")


if __name__ == "__main__":
    main()
