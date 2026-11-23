"""Five Jenner geometry passes against frozen same-sculpt camera and rig."""
import copy
import json
import math
import unittest
from pathlib import Path
import miniature_lab as geo
import photo_registration as reg
import reference_fit as landmarks
import subassembly as seams
import make_jenner_v11

HERE = Path(__file__).resolve().parent


class JennerV11Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.stages = make_jenner_v11.build_stages()
        cls.old = cls.stages[0][1]
        cls.generated = cls.stages[-1][1]
        cls.saved = json.loads((HERE/"jenner_assembly_v11.json").read_text())
        cls.old_cells = geo.rasterize(cls.old)
        cls.cells = geo.rasterize(cls.saved)
        cls.masks = json.loads((HERE/"jenner_photo_annotations.json").read_text())
        cls.marks = json.loads((HERE/"jenner_photo_landmarks.json").read_text())
        cls.control = json.loads((HERE/"jenner_assembly_v8.json").read_text())
        control_cells = geo.rasterize(cls.control)
        cls.frozen = reg.calibration(cls.control, control_cells, cls.masks,
                                     cls.marks, {
              "front_left": "front_left_3quarter",
              "front_right": "front_right_3quarter",
              "rear_left": "rear_left_3quarter",
              "rear_right": "missing_reference_landmarks"})

    def test_generator_reproduces_model_geometry_not_just_labels(self):
        self.assertEqual(len(self.stages), 6)
        self.assertEqual(self.generated["shape_refinement_revision"],
                         self.saved["shape_refinement_revision"])
        self.assertEqual({p["name"] for p in self.generated["parts"]},
                         {p["name"] for p in self.saved["parts"]})
        self.assertEqual(geo.rasterize(self.generated), self.cells)
        self.assertEqual(self.saved["sculpt"], self.control["sculpt"])

    def test_all_five_sculpt_stages_keep_backed_attached_parts(self):
        for name, trial in self.stages:
            with self.subTest(stage=name):
                parts = geo.rasterize(trial)
                self.assertEqual(geo.audit(trial, parts), [], name)
                self.assertEqual(len(parts), 30)
                self.assertTrue(all(geo.components(c) == 1
                                    for c in parts.values()))

    def test_all_original_joint_angles_and_parent_order_survive(self):
        self.assertEqual(geo.audit(self.saved, self.cells), [])
        owned = {p["name"]: p for p in self.saved["parts"]}
        self.assertEqual(len(owned), 30)
        count = 0
        for p in self.saved["parts"]:
            if not p.get("parent"):
                continue
            count += 1
            self.assertTrue(geo.strong_contact(self.cells[p["name"]],
                                               self.cells[p["parent"]]))
            self.assertEqual(seams.check_direction(
                p, self.cells[p["name"]], self.cells[p["parent"]]), [])
        self.assertEqual(count, 29)
        seen = set()
        for p in geo.export(self.saved, self.cells)["parts"]:
            self.assertTrue(not p.get("parent") or p["parent"] in seen)
            seen.add(p["name"])

    def test_detail_paint_never_creates_floating_geometry(self):
        plain = copy.deepcopy(self.saved)
        hd = next(p for p in plain["parts"] if p["name"] == "hd")
        self.assertEqual(sum(s.get("op") == "paint" for s in hd["shapes"]), 5)
        hd["shapes"] = [s for s in hd["shapes"]
                        if s.get("op") != "paint"]
        plain_cells = geo.rasterize(plain)
        for name in self.cells:
            self.assertEqual(set(plain_cells[name]), set(self.cells[name]))

    def test_distinctive_dish_without_body_bloat(self):
        ct = self.saved["parts"][0]
        dish = [sh for sh in ct["shapes"] if sh["axis"] == "y" and
                len(sh["sections"][0]["polygon"]) == 24]
        self.assertEqual(len(dish), 1)
        self.assertGreater(dish[0]["sections"][-1]["at"], 2.3)
        total = sum(map(len, self.cells.values()))
        old_total = sum(map(len, self.old_cells.values()))
        self.assertLess(total, old_total)
        self.assertGreater(total, old_total*.94)

    def test_four_weapon_bores_and_muzzle_positions(self):
        self.assertEqual(self.saved["muzzles"], self.old["muzzles"])
        pitch = self.saved["pitch"]
        for loc in ("LA", "RA"):
            cells = {c for p in self.saved["parts"] if p["loc"] == loc
                     for c in self.cells[p["name"]]}
            self.assertEqual(len(self.saved["muzzles"][loc]), 2)
            for x, y, z in self.saved["muzzles"][loc]:
                for dz in (0, .04, .08):
                    key = tuple(math.floor(q/pitch) for q in (x, y, z+dz))
                    self.assertNotIn(key, cells)

    def test_registered_pose_and_camera_frozen_before_scoring(self):
        a = reg.evaluate(self.old, self.old_cells, self.masks,
                         self.frozen, 58)
        b = reg.evaluate(self.saved, self.cells, self.masks,
                         self.frozen, 58)
        self.assertEqual((a["registered_views"], b["registered_views"]), (3, 3))
        self.assertEqual(b["views"][3]["status"], "unscored")
        self.assertNotIn("iou", b["views"][3])
        self.assertGreater(b["mean_registered_iou"],
                           a["mean_registered_iou"]+.001)
        self.assertLess(
            landmarks.score(self.saved, self.cells, self.marks)["mean_rigid_rmse"],
            landmarks.score(self.old, self.old_cells, self.marks)["mean_rigid_rmse"]
        )
        self.assertIn("uncalibrated", b["status"])


if __name__ == "__main__":
    unittest.main()
