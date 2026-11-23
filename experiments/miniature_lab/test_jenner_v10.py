"""New Jenner miniature-shape tests; never read production voxel data."""
import copy
import json
import math
import unittest
from pathlib import Path
import miniature_lab as vox
import photo_fit
import reference_fit
import subassembly

HERE = Path(__file__).resolve().parent


class JennerV10PlasticSculptTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base = json.loads((HERE / "jenner_assembly_v8.json").read_text())
        cls.v9 = json.loads((HERE / "jenner_assembly_v9.json").read_text())
        cls.v10 = json.loads((HERE / "jenner_assembly_v10.json").read_text())
        cls.before = vox.rasterize(cls.base)
        cls.after = vox.rasterize(cls.v10)

    def test_self_contained_source_without_merged_model_dependency(self):
        self.assertEqual(len(self.v10["parts"]), 30)
        self.assertEqual(self.v10["unit"], "jenner_jr7d")
        self.assertEqual(self.v10["sculpt"], self.base["sculpt"])
        self.assertTrue(all(not p["name"].startswith("temp_")
                            for p in self.v10["parts"]))

    def test_glazing_paints_existing_hull_not_floating_voxels(self):
        plain = copy.deepcopy(self.v10)
        head = next(p for p in plain["parts"] if p["name"] == "hd")
        windows = [s for s in head["shapes"] if s.get("op") == "paint"
                   and s["axis"] == "z" and s["sections"][0]["at"] < -1.16]
        self.assertEqual(len(windows), 3)
        head["shapes"] = [s for s in head["shapes"] if s.get("op") != "paint"]
        unpainted = vox.rasterize(plain)
        for name in unpainted:
            self.assertEqual(set(unpainted[name]), set(self.after[name]), name)
        self.assertGreater(sum(m == "glass" for p in self.after.values()
                               for m in p.values()), 0)

    def test_shoulder_arm_assembly_shortened_without_extra_outer_span(self):
        old = {p["name"]: p for p in self.v9["parts"]}
        new = {p["name"]: p for p in self.v10["parts"]}
        for side in ("l", "r"):
            prev = old[side + "t"]["shapes"][0]["sections"][2]["polygon"]
            now = new[side + "t"]["shapes"][0]["sections"][2]["polygon"]
            self.assertGreater(max(abs(q[0]) for q in now),
                               max(abs(q[0]) for q in prev) + .05)
            a = old[side + "a"]["shapes"][0]["sections"]
            b = new[side + "a"]["shapes"][0]["sections"]
            self.assertLess(abs(b[-1]["at"] - b[0]["at"]),
                            abs(a[-1]["at"] - a[0]["at"]))
            self.assertAlmostEqual(max(abs(s["at"]) for s in b),
                                   max(abs(s["at"]) for s in a), delta=.0002)
        self.assertEqual(vox.audit(self.v10, self.after), [])
        prev_n = sum(map(len, self.before.values()))
        curr_n = sum(map(len, self.after.values()))
        self.assertLess(abs(prev_n-curr_n) / prev_n, .04)

    def test_all_29_parent_links_have_backed_and_angularly_valid_contacts(self):
        measured_angles = []
        for p in self.v10["parts"]:
            if not p.get("parent"):
                continue
            child, parent = self.after[p["name"]], self.after[p["parent"]]
            self.assertTrue(vox.strong_contact(child, parent), p["name"])
            self.assertEqual(subassembly.check_direction(p, child, parent), [])
            measured = subassembly.normal_report(child, parent)["normal"]
            intended = subassembly.normalize(p["attach_normal"])
            measured_angles.append(math.degrees(math.acos(
                max(-1., min(1., subassembly.dot(measured, intended))))))
        self.assertEqual(len(measured_angles), 29)
        self.assertLess(max(measured_angles), 15)
        exported = vox.export(self.v10, self.after)
        seen = set()
        for p in exported["parts"]:
            self.assertTrue(not p.get("parent") or p["parent"] in seen)
            seen.add(p["name"])

    def test_all_four_bore_origins_follow_pod_shortening(self):
        pitch = self.v10["pitch"]
        for loc in ("LA", "RA"):
            owned = {c for p in self.v10["parts"] if p["loc"] == loc
                     for c in self.after[p["name"]]}
            self.assertEqual(len(self.v10["muzzles"][loc]), 2)
            for x, y, z in self.v10["muzzles"][loc]:
                for dz in (.04, .08, .12):
                    c = tuple(math.floor(v / pitch) for v in (x, y, z + dz))
                    self.assertNotIn(c, owned, (loc, c))

    def test_rough_photo_proxies_avoid_false_automatic_promotion(self):
        rough = json.loads((HERE/"jenner_photo_annotations.json").read_text())
        landmarks = json.loads((HERE/"jenner_photo_landmarks.json").read_text())
        prev = photo_fit.fit(self.base, self.before, rough, 58)["mean_iou"]
        now = photo_fit.fit(self.v10, self.after, rough, 58)["mean_iou"]
        prev_rmse = reference_fit.score(
            self.base, self.before, landmarks)["mean_rigid_rmse"]
        now_rmse = reference_fit.score(
            self.v10, self.after, landmarks)["mean_rigid_rmse"]
        self.assertGreaterEqual(now, prev - .005)
        self.assertLess(now_rmse, prev_rmse)
        # Approximate masks and camera fits, NOT photographic accuracy scores.


if __name__ == "__main__":
    unittest.main()
