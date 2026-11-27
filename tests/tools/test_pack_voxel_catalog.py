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

    def test_compact_does_not_change_string_or_number_tokens(self):
        raw = ' { "text": "a  b\\n", "x": 1.2500e-2, "y": -0.0 } '
        self.assertEqual(PACKER.compact(raw),
                         '{"text":"a  b\\n","x":1.2500e-2,"y":-0.0}')


if __name__ == "__main__":
    unittest.main()
