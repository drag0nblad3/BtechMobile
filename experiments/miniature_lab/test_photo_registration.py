"""Camera position and pose MUST be registered before comparing miniatures."""
import copy
import json
import unittest
from pathlib import Path
import miniature_lab as geo
import photo_fit
import photo_registration as fit

HERE = Path(__file__).resolve().parent


class CameraAndPoseTests(unittest.TestCase):
    def test_pinhole_camera_yaw_elevation_roll_distance_and_scale(self):
        anchors = {"dorsal": (0, 2.1, .1), "nose": (0, 1.5, -1.1),
                   "left_pod": (-.85, 1.83, -.2),
                   "right_pod": (.85, 1.83, -.2),
                   "waist": (0, 1.18, .08)}
        actual = {"yaw": 35, "elevation": 15, "roll": 4, "distance": 4.5,
                  "target": anchors["waist"], "scale": 2.2,
                  "tx": .53, "ty": .48}
        observed = {k: fit.position(v, actual) for k, v in anchors.items()}
        candidates = {"yaw_candidates": [0, 20, 35],
                      "elevation_candidates": [5, 15]}
        found = fit.fit_camera(anchors, observed, candidates,
                               distances=(4.5,), rolls=(0, 4))
        self.assertEqual((found["yaw"], found["elevation"], found["roll"]),
                         (35, 15, 4))
        self.assertAlmostEqual(found["rigid_rmse"], 0, places=8)
        self.assertAlmostEqual(found["distance"], 4.5)
        self.assertAlmostEqual(found["scale"], 2.2)

    def test_articulated_pose_fit_does_not_change_camera(self):
        anchors = {"l_hip": (-.3, 1.1, 0), "l_knee": (-.38, .7, -.12),
                   "l_ankle": (-.41, .22, .04), "l_foot": (-.42, .05, -.2)}
        camera = {"yaw": 35, "elevation": 15, "roll": 0, "distance": 4.5,
                  "target": (0, 1.0, 0), "scale": 2.8, "tx": .52, "ty": .52}
        def posed(pt, shin):
            if shin:
                pt = photo_fit.rotate(pt, anchors["l_knee"], [-20, 0, 0])
            return photo_fit.rotate(pt, anchors["l_hip"], [20, 0, 6])
        observations = {"l_"+name: fit.position(
            posed(anchors["l_"+name], name != "knee"), camera)
            for name in ("knee", "ankle", "foot")}
        old_camera = copy.deepcopy(camera)
        leg = fit.fit_pose(anchors, observations, camera, "l")
        self.assertEqual((leg["thigh_pitch"], leg["thigh_roll"],
                          leg["shin_pitch"]), (20, 6, -20))
        self.assertLess(leg["rmse"], 1e-9)
        self.assertEqual(camera, old_camera)

    @classmethod
    def setUpClass(cls):
        cls.control = json.loads((HERE / "jenner_assembly_v8.json").read_text())
        cls.candidate = json.loads((HERE / "jenner_assembly_v10.json").read_text())
        cls.photo = json.loads((HERE / "jenner_photo_annotations.json").read_text())
        cls.landmarks = json.loads((HERE / "jenner_photo_landmarks.json").read_text())
        cls.parts = geo.rasterize(cls.control)
        cls.new_parts = geo.rasterize(cls.candidate)
        cls.pairs = {"front_left": "front_left_3quarter",
                     "front_right": "front_right_3quarter",
                     "rear_left": "rear_left_3quarter",
                     "rear_right": "unmeasured_camera_pose"}

    def test_unregistered_photo_is_unscored_not_bad_geometry(self):
        frozen = fit.calibration(self.control, self.parts,
                                 self.photo, self.landmarks, self.pairs)
        evaluated = fit.evaluate(self.control, self.parts, self.photo,
                                 frozen, 38)
        self.assertEqual((evaluated["registered_views"],
                          evaluated["total_views"]), (3, 4))
        missing = [v for v in evaluated["views"] if v["view"] == "rear_right"][0]
        self.assertEqual(missing["status"], "unscored")
        self.assertNotIn("iou", missing)
        self.assertIn("uncalibrated", evaluated["status"])

    def test_all_candidates_share_frozen_camera_and_pose(self):
        frozen = fit.calibration(self.control, self.parts,
                                 self.photo, self.landmarks, self.pairs)
        prior = copy.deepcopy(frozen)
        a = fit.evaluate(self.control, self.parts, self.photo, frozen, 42)
        b = fit.evaluate(self.candidate, self.new_parts, self.photo,
                         frozen, 42)
        self.assertEqual(frozen, prior)
        self.assertEqual(a["registered_views"], b["registered_views"])
        self.assertEqual(a["views"][0]["camera_yaw"],
                         b["views"][0]["camera_yaw"])
        self.assertTrue(all(v["camera_fit_rmse"] < .07 for v in a["views"]
                            if "camera_fit_rmse" in v))
        self.assertTrue(0 <= a["mean_registered_iou"] <= 1)
        self.assertTrue(0 <= b["mean_registered_iou"] <= 1)
        self.assertEqual(a["status"], "diagnostic_only_uncalibrated_lens")

    def test_unrelated_miniature_is_rejected(self):
        frozen = fit.calibration(self.control, self.parts,
                                 self.photo, self.landmarks, self.pairs)
        wrong = dict(self.candidate, sculpt="1988 metal Jenner")
        with self.assertRaisesRegex(ValueError, "miniature generation"):
            fit.evaluate(wrong, self.new_parts, self.photo, frozen)


if __name__ == "__main__":
    unittest.main()
