"""Byte-level catalog packer regression tests (no Godot dependency)."""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[2] / "tools/pack_voxel_catalog.py"
SPEC = importlib.util.spec_from_file_location("pack_voxel_catalog", SCRIPT)
PACKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PACKER)


class VoxelCatalogPackTests(unittest.TestCase):
    def test_preserves_source_bytes_and_logical_references(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "voxels"
            root.mkdir()
            (root / "assets").mkdir()
            records = {
                "alpha.json": '{ "id":"alpha", "name":"Éclair \\" test", "n":1.2500e-2 }',
                "alpha_shape.json": '{"id":"alpha","parts":[{"name":"ct","shapes":[]}]}',
                "beta.json": '{"source":"res://data/voxels/alpha_shape.json","subdivide":2}',
                "assets/tank.json": '{"voxel_cap":50000,"id":"tank"}',
            }
            for key, raw in records.items():
                (root / key).write_text(raw, encoding="utf-8")
            out = Path(tmp) / "packed"
            self.assertEqual(PACKER.pack(root, out), (4, 3))
            index = json.loads((out / "index.json").read_bytes())
            self.assertEqual(set(index["entries"]), set(records))
            for key, raw in records.items():
                self.assertEqual((root / key).read_text(encoding="utf-8"), raw)
                shard, offset, size = index["entries"][key]
                data = (out / shard).read_bytes()[offset:offset + size]
                self.assertEqual(json.loads(data)["recipe"], json.loads(raw))
            with self.assertRaises(ValueError):
                PACKER.pack(root, out)

    def test_stage_and_verify_every_shipped_recipe(self):
        root = SCRIPT.parents[1] / "data/voxels"
        source = PACKER.source_files(root)
        # Once the full migration lands, this preflight test should switch to
        # comparing the checked-in index against the packed catalog.
        self.assertGreater(len(source), 100)
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "catalog"
            count, shards = PACKER.pack(root, out)
            self.assertEqual(count, len(source))
            self.assertLess(shards, count)
            self.assertGreater(shards, 100)
            self.assertEqual(PACKER.source_files(root), source)
            print(f"VOXEL_PACK_OK|recipes={count}|files={shards}|source_unchanged=1")

    def test_chassis_groups_and_targeted_part_edits(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "source"
            root.mkdir()
            records = {
                "atlas_shape.json": {"id": "atlas_shape", "parts": [
                    {"name": "ct", "shapes": [1]}, {"name": "la", "shapes": [2]}]},
                "atlas_voxel.json": {"id": "atlas_voxel", "source":
                    "res://data/voxels/atlas_shape.json"},
                "atlas_a.json": {"id": "atlas_a", "source":
                    "res://data/voxels/atlas_voxel.json",
                    "part_overlays": [{"part": "la", "add": [3]}]},
                "atlas_ii.json": {"id": "atlas_ii", "parts": [{"name": "ct"}]},
            }
            for key, record in records.items():
                (root / key).write_text(json.dumps(record), encoding="utf-8")
            out = Path(tmp) / "packed"
            self.assertEqual(PACKER.pack(root, out), (4, 3))
            entries = PACKER.load_index(out)
            self.assertEqual(entries["atlas_a.json"][0], "mech-atlas.json")
            self.assertEqual(entries["atlas_shape.json"][0], "mech-atlas.json")
            self.assertEqual(entries["atlas_voxel.json"][0], "mech-atlas.json")
            self.assertEqual(entries["atlas_ii.json"][0], "mech-atlas_ii.json")
            other_shard = (out / "mech-atlas_ii.json").read_bytes()
            unchanged = PACKER.read_record(out, "atlas_a.json")[1]
            changed = {"name": "la", "shapes": [2, 4, 5]}
            self.assertIn("+", PACKER.diff(out, "atlas_shape.json", changed, "la"))
            PACKER.replace_record(out, "atlas_shape.json", changed, "la")
            self.assertEqual(PACKER.extract(out, "atlas_shape.json", "la"), changed)
            self.assertEqual(PACKER.extract(out, "atlas_shape.json", "ct"),
                             records["atlas_shape.json"]["parts"][0])
            self.assertEqual(PACKER.read_record(out, "atlas_a.json")[1], unchanged)
            self.assertEqual((out / "mech-atlas_ii.json").read_bytes(), other_shard)
            with self.assertRaises(ValueError):
                PACKER.extract(out, "atlas_voxel.json", "la")
            with self.assertRaises(ValueError):
                PACKER.replace_record(out, "atlas_shape.json", {"name": "wrong"}, "la")
            overlay = {"part": "la", "add": [3, 7]}
            PACKER.replace_record(out, "atlas_a.json", overlay, "la")
            self.assertEqual(PACKER.extract(out, "atlas_a.json", "la"), overlay)
            index = PACKER.load_index(out)
            (out / "index.json").unlink()
            self.assertEqual(PACKER.reindex(out), 4)
            self.assertEqual(PACKER.load_index(out), index)

    def test_compact_does_not_change_string_or_number_tokens(self):
        raw = ' { "text": "a  b\\n", "x": 1.2500e-2, "y": -0.0 } '
        self.assertEqual(PACKER.compact(raw),
                         '{"text":"a  b\\n","x":1.2500e-2,"y":-0.0}')


if __name__ == "__main__":
    unittest.main()
