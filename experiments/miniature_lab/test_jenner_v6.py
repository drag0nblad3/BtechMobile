"""Isolated Jenner v6: connected 25-piece angled/polygon assembly."""
import copy
import json
import unittest
from pathlib import Path

import miniature_lab as geo
import subassembly as sub
import make_jenner_v6 as generator
import reference_fit as fit
import photo_fit as photos

HERE = Path(__file__).resolve().parent


class JennerV6Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.v5 = json.loads((HERE / "jenner_assembly_v5.json").read_text())
        cls.v6 = generator.build()
        cls.old = geo.rasterize(cls.v5)
        cls.cells = geo.rasterize(cls.v6)

    def test_polygon_curvature_is_real_not_many_identical_vertices(self):
        contours = [sec["polygon"] for p in self.v6["parts"]
                    for shape in p["shapes"] for sec in shape["sections"]]
        counts = [len(c) for c in contours]
        self.assertGreaterEqual(max(counts), 32)
        self.assertGreater(sum(n >= 16 for n in counts), 50)
        self.assertGreater(sum(counts), 1500)
        self.assertNotEqual(self.v5["parts"][1]["shapes"][0]["sections"][0]["polygon"],
                            self.v6["parts"][1]["shapes"][0]["sections"][0]["polygon"])

    def test_25_connected_and_supported_parts_cover_all_damage_locations(self):
        self.assertEqual(len(self.v5["parts"]), 12)
        self.assertEqual(len(self.v6["parts"]), 25)
        self.assertEqual(geo.audit(self.v6, self.cells), [])
        self.assertEqual({p["loc"] for p in self.v6["parts"]},
                         {"HD", "CT", "LT", "RT", "LA", "RA", "LL", "RL"})
        self.assertTrue(all(geo.components(c) == 1 for c in self.cells.values()))

    def test_partition_preserves_exact_occupied_volume_and_materials(self):
        before = copy.deepcopy(self.v6)
        before["parts"] = [p for p in before["parts"] if not p.get("claim_from")]
        original = {cell: mat for group in geo.rasterize(before).values()
                    for cell, mat in group.items()}
        segmented = {cell: mat for group in self.cells.values()
                     for cell, mat in group.items()}
        self.assertEqual(original, segmented)
        self.assertLessEqual(len(segmented),
                             sum(map(len, self.old.values())) * 1.02)

    def test_every_cut_has_backed_contact_and_correct_attachment_direction(self):
        for p in self.v6["parts"]:
            if not p.get("claim_from"):
                continue
            child = self.cells[p["name"]]
            parent = self.cells[p["parent"]]
            self.assertGreater(len(child), 40)
            self.assertTrue(geo.strong_contact(child, parent), p["name"])
            self.assertEqual(sub.check_direction(p, child, parent), [], p["name"])
        wrong = copy.deepcopy(next(p for p in self.v6["parts"]
                                   if p["name"] == "la_outer_cowl"))
        wrong["attach_normal"] = [0, 1, 0]
        self.assertTrue(sub.check_direction(wrong, self.cells[wrong["name"]],
                                            self.cells[wrong["parent"]]))

    def test_legacy_voxel_export_is_parent_first_and_weapon_ports_remain(self):
        exported = geo.export(self.v6, self.cells)
        seen = set()
        for p in exported["parts"]:
            self.assertTrue(not p.get("parent") or p["parent"] in seen, p["name"])
            seen.add(p["name"])
        self.assertEqual(len(exported["parts"]), 25)
        self.assertEqual(exported["unit"], "jenner_jr7d")
        self.assertEqual(len(exported["muzzles"]["LA"]), 2)
        self.assertEqual(len(exported["muzzles"]["RA"]), 2)

    def test_reference_comparison_recombines_ownership_without_false_penalty(self):
        refs = json.loads((HERE / "jenner_photo_landmarks.json").read_text())
        views = json.loads((HERE / "jenner_photo_annotations.json").read_text())
        l5 = fit.score(self.v5, self.old, refs)["mean_rigid_rmse"]
        l6 = fit.score(self.v6, self.cells, refs)["mean_rigid_rmse"]
        self.assertLess(abs(l6 - l5), .002)
        s5 = photos.fit(self.v5, self.old, views, 50)["mean_iou"]
        s6 = photos.fit(self.v6, self.cells, views, 50)["mean_iou"]
        self.assertLess(abs(s6 - s5), .015)


if __name__ == "__main__":
    unittest.main()
