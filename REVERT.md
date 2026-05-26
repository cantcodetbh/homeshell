# Revert

Preferred revert:

```bash
./scripts/revert-live
```

Manual fallback:

```bash
./scripts/stop
hyprctl reload
```

Snapshots created by `scripts/apply-live` are stored under `snapshots/`, which is intentionally ignored by git.
