"""Keep the camera fixed; re-solve leg angles when physical pivots move."""
import copy
import json
import unittest
from pathlib import Path

import miniature_lab as geo
import multisource_fit as multisource
import pose_recalibration as pose

HERE=Path(__file__).resolve().parent


class RigReattachmentPhotoTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base=json.loads((HERE/"jenner_assembly_v15_trial.json").read_text())
        cls.new=json.loads((HERE/"jenner_assembly_v16_trial.json").read_text())
        cls.old_cells=geo.rasterize(cls.base)
        cls.new_cells=geo.rasterize(cls.new)
        cls.marks=json.loads((HERE/"jenner_photo_landmarks.json").read_text())
        cls.photo=json.loads((HERE/"jenner_photo_annotations.json").read_text())
        cls.original,cls.frozen=multisource.standard_registration(
            cls.base,cls.old_cells)

    def test_unchanged_pivots_retain_frozen_angular_pose(self):
        row=next(x for x in self.frozen["registration"]
                 if x["status"]=="diagnostic_only")
        mark=self.marks["views"][0]
        photo=self.photo["views"][0]
        result=pose.pose_for_pivots(self.base,self.old_cells,mark,photo,
                                    row["camera"],row["pose"],self.base)
        self.assertEqual(result["method"],"frozen_angle_values")
        self.assertEqual(result["pose"],row["pose"])
        self.assertEqual(result["changed_pivots"],[])

    def test_new_shin_hinges_use_landmark_refit_not_new_camera(self):
        row=next(x for x in self.frozen["registration"]
                 if x["status"]=="diagnostic_only")
        original_camera=copy.deepcopy(row["camera"])
        result=pose.pose_for_pivots(
            self.new,self.new_cells,self.marks["views"][0],
            self.photo["views"][0],row["camera"],row["pose"],self.base)
        self.assertEqual(result["method"],"landmark_pose_refit_camera_frozen")
        self.assertIn("ll_shin",result["changed_pivots"])
        self.assertIn("rl_shin",result["changed_pivots"])
        self.assertEqual(row["camera"],original_camera)
        self.assertTrue(all(result["leg_fit"][side]["rmse"]>=0
                            for side in ("l","r")))
        self.assertEqual(set(result["pose"]),
                         {"ll","ll_shin","rl","rl_shin"})

    def test_poor_camera_registration_remains_unscored(self):
        manifest=json.loads(
            (HERE/"jenner_additional_reference_views.json").read_text())
        rows=multisource.new_registration(self.base,self.old_cells,manifest)
        self.assertEqual(rows[1]["status"],"unscored")
        self.assertNotIn("camera",rows[1])

    def test_all_usable_comparisons_keep_same_perspective(self):
        result=pose.compare(self.base,self.new,42)
        scored=[x for x in result["scores"]
                if x["status"]=="diagnostic_only"]
        self.assertEqual(len(scored),4)
        self.assertTrue(all(x["camera_fixed"] for x in scored))
        self.assertTrue(all(x["pose_rule"]==
                            "landmark_pose_refit_camera_frozen"
                            for x in scored))
        self.assertGreaterEqual(result["mean_control"],0)
        self.assertLessEqual(result["mean_trial"],1)
        self.assertEqual(
            sum(x["status"]=="unscored" for x in result["scores"]),2)


if __name__=="__main__":
    unittest.main()
