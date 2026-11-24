"""Full Jenner anatomy reconstruction regressions (isolated v14 trial)."""
import copy
import json
import unittest
from pathlib import Path

import miniature_lab as geo
import make_jenner_v14 as anatomy
import subassembly as seams
import multisource_fit

HERE = Path(__file__).resolve().parent


class JennerWholeAnatomyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.v12 = json.loads((HERE/"jenner_assembly_v12.json").read_text())
        cls.v14 = json.loads((HERE/"jenner_assembly_v14_trial.json").read_text())
        cls.old = geo.rasterize(cls.v12)
        cls.new = geo.rasterize(cls.v14)

    def test_all_seven_geometry_stages_reproducibly_compile(self):
        stages = anatomy.build_stages()
        self.assertEqual(len(stages), 8)
        self.assertEqual(geo.rasterize(anatomy.build()), self.new)
        for name, model in stages:
            with self.subTest(pass_name=name):
                cells = geo.rasterize(model)
                self.assertEqual(geo.audit(model, cells), [], name)
                self.assertEqual(len(cells), 30)

    def test_zero_islands_or_overlaps_with_backed_angled_joints(self):
        self.assertEqual(geo.audit(self.v14, self.new), [])
        self.assertTrue(all(geo.components(c) == 1 for c in self.new.values()))
        joints = [p for p in self.v14["parts"] if p.get("parent")]
        self.assertEqual(len(joints), 29)
        for p in joints:
            child, parent = self.new[p["name"]], self.new[p["parent"]]
            self.assertTrue(geo.strong_contact(child, parent), p["name"])
            self.assertEqual(seams.check_direction(p, child, parent), [], p["name"])

    def test_every_major_anatomical_family_has_actual_voxel_changes(self):
        target = ("ct", "hd", "lt", "rt", "la", "ra", "ll", "rl",
                  "ll_shin", "rl_shin", "ll_foot_toe", "rl_foot_toe",
                  "ct_dorsal")
        for name in target:
            self.assertNotEqual(self.old[name], self.new[name], name)

    def test_torso_and_legs_rebalanced_without_excess_volume(self):
        # Source audit at pitch 0.04: both baselines ~15,126 cells.
        self.assertLess(len(self.new["ct"]), len(self.old["ct"]))
        for side in ("l", "r"):
            self.assertGreater(len(self.new[side+"l"]), len(self.old[side+"l"]))
            self.assertGreater(len(self.new[side+"l_shin"]),
                               len(self.old[side+"l_shin"]))
        old_total = sum(map(len, self.old.values()))
        new_total = sum(map(len, self.new.values()))
        self.assertLess(abs(new_total-old_total), old_total*.025)

    def test_three_toes_exist_after_voxelization_beyond_old_tip(self):
        for side in ("l", "r"):
            owner = side+"l_foot_toe"
            old_toe = self.old[owner]
            new_toe = self.new[owner]
            self.assertGreaterEqual(len(new_toe)-len(old_toe), 30)
            # x cells sampled on the visible forward terminal ring.
            tip = [c for c in new_toe if (c[2]+.5)*self.v14["pitch"] < -.455
                   and (c[1]+.5)*self.v14["pitch"] < .115]
            self.assertTrue(tip, side+" no real extended toe voxels")
            columns = sorted({x for x, _, _ in tip})
            self.assertGreaterEqual(len(columns), 3)
            # All toe tips must be supported by the same owner, not islands.
            self.assertEqual(geo.components(new_toe), 1)

    def test_lasers_pivots_and_head_paint_are_preserved(self):
        self.assertEqual(self.v12["muzzles"], self.v14["muzzles"])
        prev = {p["name"]: p for p in self.v12["parts"]}
        for p in self.v14["parts"]:
            self.assertEqual(prev[p["name"]].get("pivot"), p.get("pivot"))
            self.assertEqual(prev[p["name"]].get("parent"), p.get("parent"))
            self.assertEqual(prev[p["name"]].get("loc"), p.get("loc"))
        plain = copy.deepcopy(self.v14)
        head = next(p for p in plain["parts"] if p["name"] == "hd")
        head["shapes"] = [s for s in head["shapes"] if s.get("op") != "paint"]
        without_paint = geo.rasterize(plain)
        self.assertEqual(set(without_paint["hd"]), set(self.new["hd"]))

    def test_unregistered_photos_remain_excluded_from_scoring(self):
        manifest = json.loads(
            (HERE/"jenner_additional_reference_views.json").read_text())
        calibration = multisource_fit.new_registration(
            self.v12, self.old, manifest)
        self.assertEqual(calibration[0]["status"], "registered_diagnostic")
        self.assertEqual(calibration[1]["status"], "unscored")
        self.assertNotIn("pose", calibration[1])


if __name__ == "__main__":
    unittest.main()
