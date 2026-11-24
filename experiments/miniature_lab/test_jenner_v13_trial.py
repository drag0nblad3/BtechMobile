"""Regress a Jenner torso/calf shape trial, never promote to production art."""
import json
import unittest
from pathlib import Path

import miniature_lab as geo
import subassembly as seams
import make_jenner_v13_trial as trial

HERE = Path(__file__).resolve().parent


class JennerV13AnatomyTrialTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.old = json.loads((HERE / "jenner_assembly_v12.json").read_text())
        cls.new = json.loads((HERE / "jenner_assembly_v13_trial.json").read_text())
        cls.old_cells = geo.rasterize(cls.old)
        cls.new_cells = geo.rasterize(cls.new)

    def test_source_reproducibility_and_no_new_independent_parts(self):
        self.assertEqual(trial.build(), self.new)
        self.assertEqual(len(self.new["parts"]), 30)
        self.assertEqual({p["name"] for p in self.old["parts"]},
                         {p["name"] for p in self.new["parts"]})
        self.assertEqual(self.old["sculpt"], self.new["sculpt"])

    def test_backed_joints_no_overlap_and_no_detached_knee(self):
        self.assertEqual(geo.audit(self.new, self.new_cells), [])
        self.assertTrue(all(geo.components(c) == 1
                            for c in self.new_cells.values()))
        joints = [p for p in self.new["parts"] if p.get("parent")]
        self.assertEqual(len(joints), 29)
        for p in joints:
            name = p["name"]
            parent = p["parent"]
            self.assertTrue(geo.strong_contact(
                self.new_cells[name], self.new_cells[parent]), name)
            self.assertEqual(seams.check_direction(
                p, self.new_cells[name], self.new_cells[parent]), [], name)

    def test_thigh_sculpt_and_photographed_pose_do_not_change(self):
        old = {p["name"]: p for p in self.old["parts"]}
        new = {p["name"]: p for p in self.new["parts"]}
        for side in ("l", "r"):
            self.assertEqual(old[side+"l"]["shapes"], new[side+"l"]["shapes"])
            self.assertEqual(old[side+"l"]["pivot"], new[side+"l"]["pivot"])
            self.assertEqual(old[side+"l_shin"]["pivot"],
                             new[side+"l_shin"]["pivot"])
            self.assertEqual(old[side+"l_foot"]["pivot"],
                             new[side+"l_foot"]["pivot"])
        self.assertEqual(self.old["muzzles"], self.new["muzzles"])

    def test_torso_rear_taper_and_mid_calf_are_real_voxel_changes(self):
        self.assertNotEqual(self.old_cells["ct"], self.new_cells["ct"])
        self.assertNotEqual(self.old_cells["ll_shin"],
                            self.new_cells["ll_shin"])
        self.assertNotEqual(self.old_cells["rl_shin"],
                            self.new_cells["rl_shin"])
        old_voxels = sum(map(len, self.old_cells.values()))
        new_voxels = sum(map(len, self.new_cells.values()))
        # Local source-level audit: v12 15126 / v13 15064 voxels.
        self.assertLess(new_voxels, old_voxels)
        self.assertGreater(new_voxels, old_voxels * .96)

    def test_toe_adjustment_not_mistaken_for_observed_voxel_improvement(self):
        for side in ("l", "r"):
            name = side + "l_foot"
            # At 0.04 pitch the groove+tip edits may have no voxel impact.
            # Keep them explicitly diagnostic and do NOT claim toe improvement.
            self.assertEqual(self.old_cells[name], self.new_cells[name])

    def test_not_accepted_without_per_part_camera_and_pose_registration(self):
        self.assertIn("trial", self.new["shape_refinement_revision"])
        notes = self.new["reference_review"]
        self.assertIn("camera+pose", notes["acceptance"])
        self.assertIn("disconnection", notes["trial_changes"][-1])
        self.assertIn("pose", notes["pose_caveat"])


if __name__ == "__main__":
    unittest.main()
