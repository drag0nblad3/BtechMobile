#!/usr/bin/env python3
"""Stage a lossless indexed voxel catalog; never delete authoring files.

Run from the checkout: python3 tools/pack_voxel_catalog.py --output /tmp/voxel-catalog
After auditing consumers, copy the verified output to data/voxels/_catalog.
Each index entry is [shard filename, UTF-8 byte offset, byte length].
"""
import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

# Match strings before whitespace, so text, escape sequences, number lexemes
# and object insertion order are retained exactly (apart from whitespace).
TOKENS = re.compile(r'"(?:\\.|[^"\\])*"|[ \t\r\n]+')
SUPPORT = {"assets", "vehicles", "battle_armor"}


def compact(text):
    return TOKENS.sub(lambda m: m.group() if m.group().startswith('"') else "", text)


def shard_for(key):
    path = Path(key)
    if len(path.parts) > 1:
        if len(path.parts) != 2 or path.parts[0] not in SUPPORT:
            raise ValueError(f"unexpected voxel directory: {key}")
        return path.parts[0] + ".json"
    ch = path.name[0].lower()
    if not ("a" <= ch <= "z"):
        return "mechs-other.json"
    start = ord("a") + ((ord(ch) - ord("a")) // 2) * 2
    return f"mechs-{chr(start)}{chr(start + 1)}.json"


def source_files(root):
    files = list(root.glob("*.json"))
    for group in SUPPORT:
        files.extend((root / group).glob("*.json"))
    return sorted(files, key=lambda p: p.relative_to(root).as_posix())


def verify(root, out, expected):
    index = json.loads((out / "index.json").read_bytes())
    if index["version"] != 1 or set(index["entries"]) != set(expected):
        raise ValueError("catalog index coverage mismatch")
    grouped = defaultdict(set)
    for key, (name, offset, size) in index["entries"].items():
        grouped[name].add(key)
        with (out / name).open("rb") as f:
            f.seek(offset)
            record = f.read(size)
        # Reconstruct exact compacted source bytes (not just object equality).
        source = compact((root / key).read_text(encoding="utf-8")).encode("utf-8")
        header = b'{"path":' + json.dumps(key, ensure_ascii=False).encode("utf-8") + b',"recipe":'
        if record != header + source + b"}":
            raise ValueError(f"lossy or misindexed record: {key}")
        parsed = json.loads(record)
        if parsed["path"] != key or not isinstance(parsed["recipe"], dict):
            raise ValueError(f"invalid recipe: {key}")
    for name, keys in grouped.items():
        records = json.loads((out / name).read_bytes())
        if [r["path"] for r in records] != sorted(keys):
            raise ValueError(f"invalid shard ordering or coverage: {name}")


def pack(root, out):
    root = root.resolve()
    out = out.resolve()
    if out == root or out.exists():
        raise ValueError("output must be a new staging directory")
    files = source_files(root)
    if not files:
        raise ValueError(f"no voxel recipes found in {root}")
    groups = defaultdict(list)
    for path in files:
        key = path.relative_to(root).as_posix()
        groups[shard_for(key)].append((key, path))
    out.mkdir(parents=True)
    entries = {}
    for name, items in sorted(groups.items()):
        with (out / name).open("wb") as f:
            f.write(b"[\n")
            for i, (key, path) in enumerate(items):
                if i:
                    f.write(b",\n")
                text = compact(path.read_text(encoding="utf-8"))
                parsed = json.loads(text)
                if not isinstance(parsed, dict):
                    raise ValueError(f"not a recipe dictionary: {key}")
                record = ('{"path":' + json.dumps(key, ensure_ascii=False)
                          + ',"recipe":' + text + "}").encode("utf-8")
                entries[key] = [name, f.tell(), len(record)]
                f.write(record)
            f.write(b"\n]\n")
    with (out / "index.json").open("w", encoding="utf-8", newline="\n") as f:
        f.write('{"version":1,"entries":{\n')
        for i, key in enumerate(sorted(entries)):
            if i:
                f.write(",\n")
            f.write(json.dumps(key, ensure_ascii=False) + ":" +
                    json.dumps(entries[key], separators=(",", ":")))
        f.write("\n}}\n")
    verify(root, out, entries)
    return len(entries), len(groups) + 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("data/voxels"))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    records, files = pack(args.root, args.output)
    print(f"VOXEL_PACK_OK|recipes={records}|files={files}|source_unchanged=1")


if __name__ == "__main__":
    main()
