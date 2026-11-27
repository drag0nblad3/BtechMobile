#!/usr/bin/env python3
"""Stage a lossless indexed voxel catalog; never delete authoring files.

Run from the checkout: python3 tools/pack_voxel_catalog.py --output /tmp/voxel-catalog
After auditing consumers, copy the verified output to data/voxels/_catalog.
Each index entry is [shard filename, UTF-8 byte offset, byte length].
"""
import argparse
import difflib
import fnmatch
import json
import os
import re
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

# Match strings before whitespace, so text, escape sequences, number lexemes
# and object insertion order are retained exactly (apart from whitespace).
TOKENS = re.compile(r'"(?:\\.|[^"\\])*"|[ \t\r\n]+')
SUPPORT = {"assets", "vehicles", "battle_armor"}


def compact(text):
    return TOKENS.sub(lambda m: m.group() if m.group().startswith('"') else "", text)


def shard_for(key, recipes):
    """Follow explicit source links; never guess from an arbitrary prefix."""
    path = Path(key)
    if len(path.parts) > 1:
        if len(path.parts) != 2 or path.parts[0] not in SUPPORT:
            raise ValueError(f"unexpected voxel directory: {key}")
        return path.parts[0] + ".json"
    seen = set()
    current = key
    while True:
        if current in seen:
            raise ValueError(f"cyclic source chain: {key}")
        seen.add(current)
        source = recipes[current].get("source")
        if not source:
            break
        prefix = "res://data/voxels/"
        if not isinstance(source, str) or not source.startswith(prefix):
            raise ValueError(f"unexpected source reference: {source!r}")
        current = source[len(prefix):]
        if current not in recipes:
            raise ValueError(f"missing source: {key} -> {current}")
        if "/" in current:
            raise ValueError(f"cross-category source: {key} -> {current}")
    stem = Path(current).stem
    # These are explicit pipeline suffixes, not arbitrary variant suffixes.
    for suffix in ("_shape", "_voxel"):
        if stem.endswith(suffix):
            stem = stem[:-len(suffix)]
            break
    return "mech-" + stem + ".json"


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
    recipes = {}
    for path in files:
        key = path.relative_to(root).as_posix()
        parsed = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(parsed, dict):
            raise ValueError(f"not a recipe dictionary: {key}")
        recipes[key] = parsed
    for path in files:
        key = path.relative_to(root).as_posix()
        groups[shard_for(key, recipes)].append((key, path))
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



def load_index(catalog):
    index = json.loads((catalog / "index.json").read_bytes())
    if index.get("version") != 1 or not isinstance(index.get("entries"), dict):
        raise ValueError("unsupported catalog index")
    return index["entries"]


def logical_key(key):
    return key.removeprefix("res://data/voxels/")


def read_record(catalog, key, entries=None):
    key = logical_key(key)
    entries = load_index(catalog) if entries is None else entries
    name, offset, length = entries[key]
    if Path(name).name != name or not name.endswith(".json"):
        raise ValueError(f"invalid shard filename: {name}")
    with (catalog / name).open("rb") as f:
        f.seek(offset)
        raw = f.read(length)
    record = json.loads(raw)
    if record.get("path") != key or not isinstance(record.get("recipe"), dict):
        raise ValueError(f"invalid or stale index entry: {key}; run reindex")
    return record["recipe"], raw


def locate_part(recipe, name):
    """Find one authored part or variant overlay, never silently edit its base."""
    matches = []
    for field, identity in (("parts", "name"), ("part_overlays", "part")):
        for i, part in enumerate(recipe.get(field, [])):
            if part.get(identity) == name:
                matches.append((field, i, identity))
    if len(matches) != 1:
        hint = f"; edit source {recipe['source']} for inherited geometry" if "source" in recipe else ""
        raise ValueError(f"expected one authored part {name!r}, found {len(matches)}{hint}")
    return matches[0]


def extract(catalog, key, part=None):
    recipe, _ = read_record(catalog, key)
    if part is None:
        return recipe
    field, i, _ = locate_part(recipe, part)
    return recipe[field][i]


def pretty(data):
    return json.dumps(data, ensure_ascii=False, indent=2, allow_nan=False) + "\n"


def diff(catalog, key, candidate, part=None):
    original = extract(catalog, key, part)
    return "".join(difflib.unified_diff(
        pretty(original).splitlines(keepends=True),
        pretty(candidate).splitlines(keepends=True),
        fromfile=key + (":" + part if part else ""),
        tofile="replacement"))


def encode_record(key, raw_recipe):
    return ('{"path":' + json.dumps(key, ensure_ascii=False) +
            ',"recipe":' + raw_recipe + "}").encode("utf-8")


def write_atomic(path, data):
    # One file at a time; index can be rebuilt after an interrupted update.
    fd, tmp = tempfile.mkstemp(prefix=".voxel-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def index_bytes(entries):
    lines = ['{"version":1,"entries":{\n']
    for i, key in enumerate(sorted(entries)):
        if i:
            lines.append(",\n")
        lines.append(json.dumps(key, ensure_ascii=False) + ":" +
                     json.dumps(entries[key], separators=(",", ":")))
    lines.append("\n}}\n")
    return "".join(lines).encode("utf-8")


def scan_shard(path):
    """Validate one-object-per-line arrays and recover byte offsets."""
    entries = {}
    data = path.read_bytes()
    records = json.loads(data)
    if not isinstance(records, list):
        raise ValueError(f"invalid shard: {path}")
    offset = 0
    for line in data.splitlines(keepends=True):
        body = line.rstrip(b"\r\n")
        if body not in (b"[", b"]"):
            raw = body.removesuffix(b",")
            rec = json.loads(raw)
            key = rec["path"]
            if key in entries or not isinstance(rec.get("recipe"), dict):
                raise ValueError(f"invalid or duplicate record: {key}")
            entries[key] = [path.name, offset, len(raw)]
        offset += len(line)
    if list(entries) != sorted(entries) or len(entries) != len(records):
        raise ValueError(f"unsorted or malformed shard: {path}")
    return entries


def reindex(catalog):
    entries = {}
    for path in sorted(catalog.glob("*.json")):
        if path.name == "index.json":
            continue
        group = scan_shard(path)
        if entries.keys() & group.keys():
            raise ValueError(f"duplicate logical path in {path}")
        entries.update(group)
    if not entries:
        raise ValueError("empty voxel catalog")
    write_atomic(catalog / "index.json", index_bytes(entries))
    return len(entries)


def replace_record(catalog, key, candidate, part=None):
    """Rewrite only one chassis shard; keep unrelated record bytes unchanged."""
    key = logical_key(key)
    entries = load_index(catalog)
    original, _ = read_record(catalog, key, entries)
    if not isinstance(candidate, dict):
        raise ValueError("replacement must be a dictionary")
    if part is None:
        updated = candidate
    else:
        field, i, identity = locate_part(original, part)
        if candidate.get(identity) != part:
            raise ValueError(f"part identity must remain {part!r}")
        original[field][i] = candidate
        updated = original
    # Source changes may move a recipe to another chassis; require full repack.
    before, _ = read_record(catalog, key, entries)
    if before.get("source") != updated.get("source"):
        raise ValueError("source changes require a complete repack")
    if before.get("id") != updated.get("id"):
        raise ValueError("recipe id changes require a complete repack")
    shard = entries[key][0]
    shard_path = catalog / shard
    actual = scan_shard(shard_path)
    if actual != {k: v for k, v in entries.items() if v[0] == shard}:
        raise ValueError("stale index; run reindex first")
    new_record = encode_record(key, compact(pretty(updated)))
    chunks = [b"[\n"]
    cursor = len(chunks[0])
    group = {}
    for i, other in enumerate(sorted(actual)):
        if i:
            chunks.append(b",\n")
            cursor += 2
        raw = new_record if other == key else read_record(catalog, other, entries)[1]
        group[other] = [shard, cursor, len(raw)]
        chunks.append(raw)
        cursor += len(raw)
    chunks.append(b"\n]\n")
    data = b"".join(chunks)
    json.loads(data)
    entries.update(group)
    write_atomic(shard_path, data)
    write_atomic(catalog / "index.json", index_bytes(entries))
    if extract(catalog, key) != updated:
        raise ValueError("replacement verification failed")
    return shard



def verify_packed(catalog):
    """Read-only validation of offsets, record ownership and source chains."""
    indexed = load_index(catalog)
    scanned = {}
    for path in sorted(catalog.glob("*.json")):
        if path.name == "index.json":
            continue
        records = scan_shard(path)
        if scanned.keys() & records.keys():
            raise ValueError(f"duplicate logical paths: {path}")
        scanned.update(records)
    if scanned != indexed:
        raise ValueError("catalog index differs from physical shard records")
    recipes = {key: read_record(catalog, key, indexed)[0] for key in indexed}
    for key in indexed:
        if indexed[key][0] != shard_for(key, recipes):
            raise ValueError(f"incorrect chassis grouping: {key}")
    return len(indexed), len(set(v[0] for v in indexed.values())) + 1


def logical_paths(root, directory="", pattern="*.json"):
    """Legacy-compatible nonrecursive logical paths, including loose overrides."""
    folder = root / directory
    found = set(folder.glob(pattern))
    catalog = root / "_catalog"
    if (catalog / "index.json").is_file():
        for key in load_index(catalog):
            path = root / key
            if path.parent == folder and fnmatch.fnmatchcase(path.name, pattern):
                found.add(path)
    return sorted(found)


def read_recipe(root, path):
    if path.is_file():
        return json.loads(path.read_bytes())
    return extract(root / "_catalog", path.relative_to(root).as_posix())


def write_recipe(root, path, recipe):
    """Update an existing record; do not silently recreate loose originals."""
    catalog = root / "_catalog"
    key = path.relative_to(root).as_posix()
    if path.is_file() or not (catalog / "index.json").is_file():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(pretty(recipe), encoding="utf-8")
    else:
        replace_record(catalog, key, recipe)


def unpack(catalog, out):
    """Extract exact compacted recipe bytes for older batch authoring tools."""
    if out.exists():
        raise ValueError("unpack output must be a new directory")
    entries = load_index(catalog)
    verify_packed(catalog)
    out.mkdir(parents=True)
    for key in sorted(entries):
        rel = Path(key)
        if rel.is_absolute() or ".." in rel.parts or "\\" in key:
            raise ValueError(f"invalid logical path: {key}")
        _, raw = read_record(catalog, key, entries)
        header = b'{"path":' + json.dumps(key, ensure_ascii=False).encode("utf-8") + b',"recipe":'
        if not raw.startswith(header) or not raw.endswith(b"}"):
            raise ValueError(f"invalid record wrapper: {key}")
        target = out / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw[len(header):-1] + b"\n")
    return len(entries)


def repack(root, out):
    """Stage a complete catalog including loose authoring overrides/new records."""
    with tempfile.TemporaryDirectory() as tmp:
        source = Path(tmp) / "recipes"
        unpack(root / "_catalog", source)
        for path in source_files(root):
            target = source / path.relative_to(root)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(path.read_bytes())
        return pack(source, out)


def edit_main(argv):
    parser = argparse.ArgumentParser(description="Inspect and edit packed voxel recipes")
    sub = parser.add_subparsers(dest="command", required=True)
    for command in ("list", "parts", "extract", "replace", "diff", "reindex", "verify", "unpack", "repack"):
        p = sub.add_parser(command)
        p.add_argument("--catalog", type=Path, default=Path("data/voxels/_catalog"))
        if command in ("parts", "extract", "replace", "diff"):
            p.add_argument("key")
        if command in ("extract", "replace", "diff"):
            p.add_argument("--part")
        if command in ("replace", "diff"):
            p.add_argument("input", type=Path)
        if command in ("extract", "unpack", "repack"):
            p.add_argument("--output", type=Path, required=command != "extract")
    args = parser.parse_args(argv)
    catalog = args.catalog
    if args.command == "list":
        for key, entry in sorted(load_index(catalog).items()):
            print(f"{key}\t{entry[0]}")
    elif args.command == "parts":
        recipe = extract(catalog, args.key)
        for field, identity in (("parts", "name"), ("part_overlays", "part")):
            for part in recipe.get(field, []):
                print(f"{field}\t{part[identity]}")
        if "source" in recipe:
            print(f"source\t{recipe['source']}")
    elif args.command == "extract":
        text = pretty(extract(catalog, args.key, args.part))
        if args.output:
            args.output.write_text(text, encoding="utf-8")
        else:
            print(text, end="")
    elif args.command == "diff":
        print(diff(catalog, args.key, json.loads(args.input.read_bytes()), args.part), end="")
    elif args.command == "replace":
        shard = replace_record(catalog, args.key, json.loads(args.input.read_bytes()), args.part)
        print(f"VOXEL_REPLACE_OK|{logical_key(args.key)}|{shard}")
    elif args.command == "reindex":
        print(f"VOXEL_REINDEX_OK|recipes={reindex(catalog)}")
    elif args.command == "verify":
        records, files = verify_packed(catalog)
        print(f"VOXEL_VERIFY_OK|recipes={records}|files={files}")
    elif args.command == "unpack":
        print(f"VOXEL_UNPACK_OK|recipes={unpack(catalog, args.output)}")
    elif args.command == "repack":
        records, files = repack(catalog.parent, args.output)
        print(f"VOXEL_REPACK_OK|recipes={records}|files={files}")


def main():
    if len(sys.argv) > 1 and sys.argv[1] in ("list", "parts", "extract", "replace", "diff", "reindex", "verify", "unpack", "repack"):
        edit_main(sys.argv[1:])
        return
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("data/voxels"))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    records, files = pack(args.root, args.output)
    print(f"VOXEL_PACK_OK|recipes={records}|files={files}|source_unchanged=1")


if __name__ == "__main__":
    main()
