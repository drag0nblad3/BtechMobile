"""Isolated regression suite: python -m unittest discover -s experiments/miniature_lab."""
import copy
import json
import unittest
from pathlib import Path

import miniature_lab as lab

ROOT = Path(__file__).resolve().parent


class MiniatureLabTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec = json.loads((ROOT / "jenner_assembly.json").read_text())
        cls.cells = lab.rasterize(cls.spec)

    def test_eight_record_sheet_locations_and_named_components(self):
        self.assertEqual({p["loc"] for p in self.spec["parts"]},
                         {"HD", "CT", "LT", "RT", "LA", "RA", "LL", "RL"})
        self.assertEqual(len(self.spec["parts"]), 12)
        self.assertEqual(lab.audit(self.spec, self.cells), [])

    def test_jenner_has_projecting_head(self):
        head = min(z for _, _, z in self.cells["hd"])
        chest = min(z for _, _, z in self.cells["ct"])
        self.assertLess(head, chest - 10)
        self.assertGreater(len(self.cells["hd"]), 300)

    def test_laser_opening_removes_real_cells(self):
        modified = copy.deepcopy(self.spec)
        left_arm = next(p for p in modified["parts"] if p["name"] == "la")
        left_arm["shapes"] = [s for s in left_arm["shapes"]
                              if s.get("op") != "subtract"]
        full = lab.rasterize(modified)
        self.assertGreater(len(full["la"]), len(self.cells["la"]))

    def test_overlap_and_disconnected_joints_are_not_auto_repaired(self):
        modified = {name: cells.copy() for name, cells in self.cells.items()}
        modified["lt"][next(iter(modified["ct"]))] = "armor"
        self.assertTrue(any("overlap" in err
                            for err in lab.audit(self.spec, modified)))
        modified = {name: cells.copy() for name, cells in self.cells.items()}
        modified["la"] = {(x - 50, y, z): v
                          for (x, y, z), v in modified["la"].items()}
        self.assertTrue(any("contact" in err
                            for err in lab.audit(self.spec, modified)))

    def test_legacy_recipe_export_keeps_parts_and_material_roles(self):
        exported = lab.export(self.spec, self.cells)
        self.assertFalse(exported["exclusive_parts"])
        self.assertEqual(exported["unit"], "jenner_jr7d")
        self.assertEqual(len(exported["parts"]), 12)
        self.assertTrue(all(p["shapes"] for p in exported["parts"]))
        self.assertEqual(exported["parts"][0]["loc"], "CT")
        self.assertEqual(exported["parts"][1]["parent"], "ct")
        self.assertIn("structure", {m["role"] for m in exported["materials"]})

    def test_scoring_reports_unannotated_views_without_making_up_scores(self):
        missing = lab.compare(self.spec, self.cells,
                              {"views": [{"name": "front"}]})
        self.assertEqual(missing["views"][0]["status"],
                         "unscored: no outline")
        traced = {"views": [{"name": "front",
                             "yaw_candidates": [-5, 0, 5],
                             "elevation_candidates": [0],
                             "outline": [[.2, .1], [.8, .1],
                                         [.8, .9], [.2, .9]]}]}
        scored = lab.compare(self.spec, self.cells, traced, size=48)
        self.assertTrue(0 <= scored["views"][0]["iou"] <= 1)
        self.assertIn(scored["views"][0]["yaw"], (-5, 0, 5))


if __name__ == "__main__":
    unittest.main()
