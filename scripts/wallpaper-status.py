#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]
wall_dir = Path.home() / "Pictures" / "wallpapers"
state_file = PROJECT_DIR / "state" / "wallpaper"
suffixes = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}

items = []
if wall_dir.exists():
    for path in sorted(wall_dir.iterdir(), key=lambda item: item.stat().st_mtime, reverse=True):
        if path.is_file() and path.suffix.lower() in suffixes:
            items.append(str(path))

current = ""
try:
    current = state_file.read_text().strip()
except Exception:
    pass

if not current and items:
    current = items[0]

payload = {
    "directory": str(wall_dir),
    "current": current,
    "count": len(items),
    "items": items[:24],
    "intelligence": {"reason": "", "current": {}, "recent": []},
}
try:
    intel = subprocess.run(
        [str(PROJECT_DIR / "scripts" / "wallpaper-intel.py"), "status", current],
        text=True,
        capture_output=True,
        timeout=3,
    )
    if intel.returncode == 0:
        payload["intelligence"] = json.loads(intel.stdout)
except Exception:
    pass
print(json.dumps(payload, separators=(",", ":")))
