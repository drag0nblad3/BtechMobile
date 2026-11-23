"""Regression tests for same-edition Jenner photographic fitting (experimental only)."""
import json
import math
import unittest
from pathlib import Path

import miniature_lab as vox
import reference_fit as fit
import photo_fit as silhouette_fit

ROOT = Path(__file__).resolve().parent


class ReferenceFitTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.early = json.loads((ROOT / "jenner_assembly.json").read_text())
        cls.latest = json.loads((ROOT / "jenner_assembly_v4.json").read_text())
        cls.combined = json.loads((ROOT / "jenner_assembly_combined.json").read_text())
        cls.ann = json.loads((ROOT / "jenner_photo_landmarks.json").read_text())
        cls.base_parts = vox.rasterize(cls.early)
        cls.latest_parts = vox.rasterize(cls.latest)
        cls.combined_parts = vox.rasterize(cls.combined)

    def test_source_is_same_plastic_sculpt_and_no_photos_committed(self):
        self.assertIn("Jenner6.jpg", self.ann["reference_url"])
        self.assertIn("CAT35729", self.ann["sculpt"])
        self.assertGreaterEqual(len(self.ann["views"]), 3)
        for view in self.ann["views"]:
            self.assertTrue(view["landmarks_px"])
            self.assertTrue(view["yaw_candidates"])
            self.assertTrue(view["elevation_candidates"])

    def test_revisions_are_complete_and_physically_connected(self):
        for spec, parts in ((self.early, self.base_parts),
                            (self.latest, self.latest_parts),
                            (self.combined, self.combined_parts)):
            self.assertFalse(vox.audit(spec, parts))
            self.assertEqual({p["loc"] for p in spec["parts"]},
                             {"HD", "CT", "LT", "RT", "LA", "RA", "LL", "RL"})

    def test_same_photo_camera_and_leg_pose_fit_is_measurable(self):
        result = fit.score(self.latest, self.latest_parts, self.ann)
        self.assertEqual(len(result["views"]), len(self.ann["views"]))
        for view in result["views"]:
            self.assertGreater(view["scale"], 0)
            self.assertGreaterEqual(view["rigid_rmse"], 0)
            self.assertTrue(-360 <= view["yaw"] <= 360)
            self.assertTrue(any(key.endswith("_leg_pose") for key in view))

    def test_source_geometry_correction_reduces_coarse_rigid_landmark_error(self):
        before = fit.score(self.early, self.base_parts, self.ann)
        after = fit.score(self.latest, self.latest_parts, self.ann)
        self.assertLess(after["mean_rigid_rmse"], before["mean_rigid_rmse"])
        # This only checks these provisional hand-picked landmarks; it is
        # NOT a quantitative claim of improved miniature silhouette accuracy.

    def test_combined_sculpt_improves_two_independent_coarse_reference_proxies(self):
        landmarks = fit.score(self.combined, self.combined_parts, self.ann)
        base_landmarks = fit.score(self.early, self.base_parts, self.ann)
        self.assertLess(landmarks["mean_rigid_rmse"],
                        base_landmarks["mean_rigid_rmse"])
        silhouettes = json.loads((ROOT / "jenner_photo_annotations.json").read_text())
        initial = silhouette_fit.fit(self.early, self.base_parts, silhouettes, 58)
        combined = silhouette_fit.fit(self.combined, self.combined_parts,
                                      silhouettes, 58)
        self.assertGreater(combined["mean_iou"], initial["mean_iou"] + .01)
        # Not a ground-truth quality target; both inputs are hand-approximated.

    def test_real_gun_boress_and_exported_muzzles_are_consistent(self):
        out = vox.export(self.latest, self.latest_parts)
        self.assertIn("LA", out["muzzles"])
        self.assertIn("RA", out["muzzles"])
        pitch = self.latest["pitch"]
        for side, part in (("LA", "la"), ("RA", "ra")):
            self.assertEqual(len(self.latest["muzzles"][side]), 2)
            for muzzle in self.latest["muzzles"][side]:
                # Open through several occupied grid depths, not black
                # decorative squares painted on a solid front face.
                x, y, z = muzzle
                for dz in (0, .04, .08, .12, .16):
                    c = tuple(round(v / pitch - .5) for v in (x, y, z + dz))
                    self.assertNotIn(c, self.latest_parts[part],
                                     "Muzzle is plugged by solid voxel geometry")
                self.assertEqual(out["muzzles"][side][0][0],
                                 round(self.latest["muzzles"][side][0][0]/pitch, 4))


if __name__ == "__main__":
    unittest.main()
