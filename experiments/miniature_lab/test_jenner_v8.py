"""Check 30-component Jenner v8 plate profiles and actual angular joints."""
import json
import math
import unittest
from pathlib import Path

import miniature_lab as geo
import subassembly as seams
import photo_fit as silhouettes
import make_jenner_v8 as generator

HERE = Path(__file__).resolve().parent


class JennerV8Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.previous = json.loads((HERE / "jenner_assembly_v7.json").read_text())
        cls.current = json.loads((HERE / "jenner_assembly_v8.json").read_text())
        cls.cells = geo.rasterize(cls.current)

    def test_generator_and_extra_polygon_control_points(self):
        self.assertEqual(generator.build()["parts"], self.current["parts"])
        names = {p["name"]: p for p in self.current["parts"]}
        for name in ("ct", "lt", "rt"):
            self.assertTrue(all(len(s["polygon"]) == 16
                     for s in names[name]["shapes"][0]["sections"]))

    def test_twenty_nine_parent_child_interfaces_are_solid_and_aligned(self):
        self.assertEqual(len(self.current["parts"]), 30)
        self.assertEqual(geo.audit(self.current, self.cells), [])
        angles = []
        for p in self.current["parts"]:
            if not p.get("parent"):
                continue
            child, parent = self.cells[p["name"]], self.cells[p["parent"]]
            self.assertTrue(geo.strong_contact(child, parent), p["name"])
            self.assertEqual(seams.check_direction(p, child, parent), [], p["name"])
            report = seams.normal_report(child, parent)
            wanted = seams.normalize(p["attach_normal"])
            cos_theta = max(-1, min(1, seams.dot(report["normal"], wanted)))
            angles.append(math.degrees(math.acos(cos_theta)))
        self.assertEqual(len(angles), 29)
        self.assertLess(max(angles), 15)

    def test_new_panels_do_not_add_unwanted_body_volume(self):
        now = sum(map(len, self.cells.values()))
        before = sum(map(len, geo.rasterize(self.previous).values()))
        self.assertLess(abs(now-before), before * .015)

    def test_reference_and_legacy_export_have_not_regressed(self):
        masks = json.loads((HERE / "jenner_photo_annotations.json").read_text())
        old = silhouettes.fit(self.previous, geo.rasterize(self.previous),
                              masks, 50)["mean_iou"]
        new = silhouettes.fit(self.current, self.cells, masks, 50)["mean_iou"]
        self.assertGreaterEqual(new, old - .003)
        model = geo.export(self.current, self.cells)
        seen = set()
        for p in model["parts"]:
            self.assertTrue(not p.get("parent") or p["parent"] in seen)
            seen.add(p["name"])
        self.assertEqual(set(model["muzzles"]), {"LA", "RA"})


if __name__ == "__main__":
    unittest.main()
