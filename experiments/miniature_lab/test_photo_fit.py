"""Photo provenance and source-level reconstruction regressions."""
import json
import unittest
from pathlib import Path
import miniature_lab as geo
import photo_fit as photo

HERE = Path(__file__).resolve().parent


class PhotoFitTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.baseline = json.loads((HERE / "jenner_assembly.json").read_text())
        cls.resculpt = json.loads((HERE / "jenner_resculpt.json").read_text())
        cls.reference = json.loads(
            (HERE / "jenner_photo_annotations.json").read_text())

    def test_four_views_belong_to_one_confirmed_sculpt_edition(self):
        self.assertEqual(self.baseline["sculpt"], self.resculpt["sculpt"])
        self.assertEqual(self.resculpt["sculpt"], self.reference["sculpt"])
        self.assertIn("35729", self.reference["sculpt"])
        self.assertEqual(len(self.reference["views"]), 4)
        self.assertEqual(len({v["name"] for v in self.reference["views"]}), 4)
        self.assertTrue(all(v["outline_px"] and v["crop_px"]
                            for v in self.reference["views"]))

    def test_rig_pose_affects_projection_not_source_geometry(self):
        cells = geo.rasterize(self.resculpt)
        neutral, _ = photo.projected_masks(
            self.resculpt, cells, 25, 20, {}, size=48)
        angles = self.reference["views"][1]["pose_candidates"][1]["angles"]
        posed, _ = photo.projected_masks(
            self.resculpt, cells, 25, 20, angles, size=48)
        self.assertNotEqual(neutral, posed)
        self.assertEqual(geo.audit(self.resculpt, cells), [])

    def test_manual_four_angle_score_improves_vs_untouched_baseline(self):
        base = photo.fit(self.baseline, geo.rasterize(self.baseline),
                         self.reference, 58)
        result = photo.fit(self.resculpt, geo.rasterize(self.resculpt),
                           self.reference, 58)
        # Intentional experimental threshold, not a production fidelity bar.
        self.assertGreater(result["mean_iou"], base["mean_iou"] + .01)
        self.assertGreater(result["views"][1]["iou"],
                           base["views"][1]["iou"])

    def test_muzzles_are_in_open_port_and_stop_at_solid_barrel_depth(self):
        cells = geo.rasterize(self.resculpt)
        exported = geo.export(self.resculpt, cells)
        for loc, part in (("LA", "la"), ("RA", "ra")):
            self.assertEqual(len(exported["muzzles"][loc]), 2)
            for muzzle in exported["muzzles"][loc]:
                x, y, z = (round(v) for v in muzzle)
                self.assertNotIn((x, y, z), cells[part])
                self.assertNotIn((x, y, z + 2), cells[part])
                self.assertIn((x, y, z + 5), cells[part])


if __name__ == "__main__":
    unittest.main()
