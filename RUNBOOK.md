# Runbook

## Static Check

```bash
./scripts/check
```

This verifies required commands, Python syntax, JSON-producing scripts, shell script syntax, a short Quickshell smoke run, and `hyprctl configerrors` when Hyprland is reachable.

## Parallel Test

```bash
./scripts/launch
quickshell list --all
```

Check the corner bars, drawer positioning, wallpaper colors, text fit, hover states, and click actions.

## Wallpaper Palette Test

```bash
./scripts/wallpaper next
./scripts/wallpaper pick
```

Wallpaper commands read from `~/Pictures/wallpapers`.

## Theme Watcher

```bash
./scripts/watch-wallpaper-theme
```

The watcher follows this project's `state/wallpaper` file and the wallpaper directory. It does not depend on any external rice cache.

## Live Apply

```bash
./scripts/apply-live
```

The apply script snapshots relevant live config before changing it. Use `./scripts/revert-live` if anything feels wrong.
