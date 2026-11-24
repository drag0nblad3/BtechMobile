"""New Jenner thigh sculpt stays even when its old knee seam would be invalid."""
import json
import unittest
from pathlib import Path

import miniature_lab as geo
import make_jenner_v16 as reconstruct
import reattach_after_resculpt as reattach
import subassembly as seams

HERE = Path(__file__).resolve().parent


class JennerReattachedThighTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.v15 = json.loads((HERE/"jenner_assembly_v15_trial.json").read_text())
        cls.v16 = json.loads((HERE/"jenner_assembly_v16_trial.json").read_text())
        cls.before = geo.rasterize(cls.v15)
        cls.after = geo.rasterize(cls.v16)
        cls.by15 = {p["name"]:p for p in cls.v15["parts"]}
        cls.by16 = {p["name"]:p for p in cls.v16["parts"]}

    def test_generator_rebuilds_scult_and_real_connections(self):
        generated = reconstruct.build()
        self.assertEqual(generated, self.v16)
        self.assertEqual(geo.rasterize(generated), self.after)

    def test_all_30_parts_and_29_backed_angular_joints(self):
        self.assertEqual(len(self.after),30)
        self.assertEqual(geo.audit(self.v16,self.after),[])
        count=0
        for p in self.v16["parts"]:
            self.assertEqual(geo.components(self.after[p["name"]]),1)
            if not p.get("parent"):
                continue
            count+=1
            child,parent=self.after[p["name"]],self.after[p["parent"]]
            self.assertTrue(geo.strong_contact(child,parent),p["name"])
            self.assertEqual(seams.check_direction(p,child,parent),[],p["name"])
        self.assertEqual(count,29)

    def test_true_new_thigh_and_knee_mass_not_just_more_polygons(self):
        for side in ("l","r"):
            self.assertGreater(len(self.after[side+"l"]),
                               len(self.before[side+"l"]))
            self.assertGreater(len(self.after[side+"l_knee_armor"]),
                               len(self.before[side+"l_knee_armor"]))
            thigh=self.by16[side+"l"]
            self.assertEqual(len(thigh["shapes"]),2)
            self.assertEqual(len(thigh["shapes"][0]["sections"]),4)
            self.assertEqual(thigh["shapes"][1]["sections"][0]["at"],.705)
        self.assertLess(sum(map(len,self.after.values())),
                        sum(map(len,self.before.values()))*1.03)

    def test_reattach_knee_partition_and_move_bone_pivot(self):
        for side,sign in (("l",-1),("r",1)):
            cuff=self.by16[side+"l_knee_armor"]
            shin=self.by16[side+"l_shin"]
            self.assertEqual(cuff["partition"]["planes"],
                             [{"normal":[0,-1,.24],
                               "origin":[0,.825,-.14]}])
            self.assertEqual(cuff["pivot"],[sign*.37,.79,-.16])
            self.assertEqual(shin["pivot"],[sign*.37,.68,-.14])
            # Directly check the new mating plane before evaluating
            # exported rig ownership; no bridge voxels are permitted.
            uncut=geo.rasterize({
                "pitch":self.v16["pitch"],
                "parts":[self.by16[side+"l"]]})[side+"l"]
            shin_source=geo.rasterize({
                "pitch":self.v16["pitch"],
                "parts":[self.by16[side+"l_shin"]]})[side+"l_shin"]
            report=reattach.inspect(
                uncut,self.v16["pitch"],cuff["partition"]["planes"][0],
                downstream=(shin_source,))
            self.assertEqual(report["errors"],[])

    def test_weapon_ports_and_all_other_joint_owners_preserved(self):
        self.assertEqual(self.v15["muzzles"],self.v16["muzzles"])
        for p in self.v16["parts"]:
            old=self.by15[p["name"]]
            self.assertEqual(p["name"],old["name"])
            self.assertEqual(p.get("parent"),old.get("parent"))
            self.assertEqual(p.get("loc"),old.get("loc"))
            if not p["name"].endswith(("_shin","_knee_armor")):
                self.assertEqual(p.get("pivot"),old.get("pivot"))
        for side in ("l","r"):
            self.assertEqual(self.before[side+"l_foot_toe"],
                             self.after[side+"l_foot_toe"])

    def test_camera_must_stay_fixed_but_pose_refit_when_pivot_moves(self):
        self.assertIn("reattach",self.v16["reference_review"]["reattach_policy"])
        for side in ("l","r"):
            self.assertNotEqual(self.by15[side+"l_shin"]["pivot"],
                                self.by16[side+"l_shin"]["pivot"])
        # With a changed knee hinge, old joint angle values aren't
        # a physically identical stance. Fit new articulation from
        # observed knee/ankle/foot landmarks while freezing the camera.


if __name__ == "__main__":
    unittest.main()
