#!/usr/bin/env python3
"""Migrate official design files to deterministic, lossless JSON arrays.

Only --apply removes originals, after every staged record has been checked.
All original IDs must match their filenames to preserve Godot load order.
"""
import argparse
import json
import tempfile
from pathlib import Path
from pack_voxel_catalog import compact

GROUPS = {
    "units": [f"{tech}_{weight}" for tech in ("is", "clan")
              for weight in ("light", "medium", "heavy", "assault")],
    "vehicles": ["tracked", "hover", "wheeled", "other"],
    "battle_armor": ["is", "clan"],
}


def group_for(kind, record):
    tech = "clan" if record.get("tech_base") == "clan" else "is"
    if kind == "units":
        tons = record["tonnage"]
        weight = ("light" if tons <= 35 else "medium" if tons <= 55
                  else "heavy" if tons <= 75 else "assault")
        return f"{tech}_{weight}"
    if kind == "vehicles":
        return {"t": "tracked", "h": "hover", "w": "wheeled"}.get(
            record["vehicle"].get("motive"), "other")
    return tech


def stage(root, out):
    manifests = {}
    for kind, groups in GROUPS.items():
        source = root / kind
        paths = sorted(source.glob("*.json"))
        records = {}
        buckets = {name: [] for name in groups}
        if not paths:
            raise ValueError(f"empty source: {source}")
        for path in paths:
            raw = compact(path.read_text(encoding="utf-8"))
            record = json.loads(raw)
            if not isinstance(record, dict) or record["id"] != path.stem:
                raise ValueError(f"record ID or format mismatch: {path}")
            if path.stem in records:
                raise ValueError(f"duplicate record: {path}")
            records[path.stem] = raw
            buckets[group_for(kind, record)].append((path.stem, raw))
        target = out / kind
        target.mkdir(parents=True)
        seen = {}
        for group, items in buckets.items():
            shard = target / (group + ".json")
            shard.write_text("[\n" + ",\n".join(raw for _, raw in sorted(items)) +
                             "\n]\n", encoding="utf-8")
            raw_lines = shard.read_text(encoding="utf-8").splitlines()[1:-1]
            decoded = json.loads(shard.read_bytes())
            if len(decoded) != len(items):
                raise ValueError(f"incorrect shard count: {shard}")
            for line, record in zip(raw_lines, decoded):
                key = record["id"]
                if key in seen or group_for(kind, record) != group:
                    raise ValueError(f"duplicate or misclassified: {key}")
                seen[key] = line.removesuffix(",")
        if seen != records or sorted(seen) != [p.stem for p in paths]:
            raise ValueError(f"lossy migration or load order change: {kind}")
        manifests[kind] = paths
        print(f"UNIT_PACK_OK|{kind}|records={len(records)}|files={len(groups)}")
    return manifests


def migrate(root, apply):
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp)
        manifests = stage(root, out)
        if apply:
            for kind, paths in manifests.items():
                for path in paths:
                    path.unlink()
                for shard in sorted((out / kind).glob("*.json")):
                    (root / kind / shard.name).write_bytes(shard.read_bytes())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("data"))
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    migrate(args.root, args.apply)
