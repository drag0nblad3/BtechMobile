"""Regress new same-edition Jenner photos and five reference-guided sculpt passes."""
import json
import unittest
from pathlib import Path

import miniature_lab as geo
import make_jenner_v12 as generator
import multisource_fit as multi
import photo_registration as camera_fit
import subassembly as seams

HERE=Path(__file__).resolve().parent


class JennerV12Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.v11=json.loads((HERE/"jenner_assembly_v11.json").read_text())
        cls.v12=json.loads((HERE/"jenner_assembly_v12.json").read_text())
        cls.before=geo.rasterize(cls.v11)
        cls.after=geo.rasterize(cls.v12)
        cls.reference=json.loads((HERE/"jenner_additional_reference_views.json").read_text())

    def test_same_2021_catalyst_sculpt_in_all_photographs(self):
        self.assertEqual(self.v12["sculpt"],self.reference["sculpt"])
        self.assertEqual(len(self.reference["new_photos"]),2)
        self.assertTrue(all(p["image_url"].startswith("https://")
                            and len(p["rigid_px"])>=3
                            for p in self.reference["new_photos"]))
        self.assertTrue(all(p["preview_size_px"]==[500,500]
                            for p in self.reference["new_photos"]))

    def test_both_new_cameras_attempted_but_occluded_side_unscored(self):
        fitted=multi.new_registration(self.v11,self.before,self.reference)
        self.assertEqual(fitted[0]["status"],"registered_diagnostic")
        self.assertLess(fitted[0]["camera"]["rigid_rmse"],.08)
        self.assertEqual(fitted[1]["status"],"unscored")
        self.assertGreater(fitted[1]["camera_attempt"]["rigid_rmse"],.08)
        self.assertNotIn("camera",fitted[1])
        self.assertNotIn("pose",fitted[1])

    def test_generator_reproduces_five_passes_and_keeps_structural_contacts(self):
        source=generator.build()
        self.assertEqual(geo.rasterize(source),self.after)
        self.assertEqual(len(generator.build_stages()),6)
        for stage,model in generator.build_stages():
            with self.subTest(stage=stage):
                cells=geo.rasterize(model)
                self.assertEqual(geo.audit(model,cells),[],stage)
                self.assertEqual(len(cells),30)
        self.assertLess(sum(map(len,self.after.values())),
                        sum(map(len,self.before.values()))*1.02)

    def test_29_attachment_normals_and_parent_hierarchy(self):
        self.assertEqual(geo.audit(self.v12,self.after),[])
        count=0
        for p in self.v12["parts"]:
            parent=p.get("parent")
            if not parent:continue
            count+=1
            self.assertTrue(geo.strong_contact(self.after[p["name"]],
                                               self.after[parent]),p["name"])
            self.assertEqual(seams.check_direction(
                p,self.after[p["name"]],self.after[parent]),[])
        self.assertEqual(count,29)
        seen=set()
        for part in geo.export(self.v12,self.after)["parts"]:
            self.assertTrue(not part.get("parent") or part["parent"] in seen)
            seen.add(part["name"])

    def test_three_separate_forward_windows_and_sixteen_physical_grille_ports(self):
        by={p["name"]:p for p in self.v12["parts"]}
        windows=[s for s in by["hd"]["shapes"][1:4]
                 if s["op"]=="paint" and s["mat"]=="glass"]
        self.assertEqual(len(windows),3)
        for i in range(2):
            left=max(q[0] for q in windows[i]["sections"][0]["polygon"])
            right=min(q[0] for q in windows[i+1]["sections"][0]["polygon"])
            self.assertGreater(right-left,.04)
        grille=[s for s in by["ct"]["shapes"]
                if s.get("op")=="subtract" and s["axis"]=="z"
                and s["sections"][0]["at"]==-.33]
        self.assertEqual(len(grille),16)
        self.assertEqual(self.v12["muzzles"],self.v11["muzzles"])

    def test_frozen_camera_pose_comparison_uses_only_well_fitted_photos(self):
        old,frozen=multi.standard_registration(self.v11,self.before)
        newer=camera_fit.evaluate(self.v12,self.after,old,frozen,58)
        prior=camera_fit.evaluate(self.v11,self.before,old,frozen,58)
        self.assertEqual((prior["registered_views"],newer["registered_views"]),(3,3))
        self.assertGreaterEqual(newer["mean_registered_iou"],
                                prior["mean_registered_iou"])
        additional=multi.new_registration(self.v11,self.before,self.reference)
        a=multi.evaluate_registered(self.v11,self.before,self.reference,additional,58)
        b=multi.evaluate_registered(self.v12,self.after,self.reference,additional,58)
        self.assertGreaterEqual(b[0]["iou"],a[0]["iou"])
        self.assertEqual(b[1]["status"],"unscored")
        self.assertNotIn("iou",b[1])


if __name__=="__main__":
    unittest.main()
