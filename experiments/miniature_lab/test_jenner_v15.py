"""Jenner v15 must truly have three separate, load-bearing toe tips."""
import json
import unittest
from pathlib import Path
import miniature_lab as geo
import make_jenner_v15 as generator

HERE=Path(__file__).resolve().parent


def front_clusters(owned,pitch):
    columns=sorted({x for (x,y,z) in owned
                    if (z+.5)*pitch < -.455 and
                    (y+.5)*pitch < .115})
    count=0
    for i,x in enumerate(columns):
        if i==0 or x-columns[i-1]>1:
            count+=1
    return count


class JennerThreeClawTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.v14=json.loads((HERE/"jenner_assembly_v14_trial.json").read_text())
        cls.v15=json.loads((HERE/"jenner_assembly_v15_trial.json").read_text())
        cls.old=geo.rasterize(cls.v14)
        cls.new=geo.rasterize(cls.v15)

    def test_generator_and_all_30_parts(self):
        self.assertEqual(geo.rasterize(generator.build()),self.new)
        self.assertEqual(len(self.v15["parts"]),30)
        self.assertEqual(geo.audit(self.v15,self.new),[])

    def test_exactly_three_separated_visible_toes_per_side(self):
        for side in ("l","r"):
            toe=side+"l_foot_toe"
            self.assertEqual(front_clusters(self.old[toe],self.v14["pitch"]),2)
            self.assertEqual(front_clusters(self.new[toe],self.v15["pitch"]),3)
            self.assertEqual(geo.components(self.new[toe]),1)
            self.assertTrue(geo.strong_contact(self.new[toe],
                                               self.new[side+"l_foot"]),toe)

    def test_ankle_rig_and_laser_muzzles_unchanged(self):
        self.assertEqual(self.v15["muzzles"],self.v14["muzzles"])
        p14={p["name"]:p for p in self.v14["parts"]}
        for p in self.v15["parts"]:
            old=p14[p["name"]]
            self.assertEqual(p.get("pivot"),old.get("pivot"))
            self.assertEqual(p.get("parent"),old.get("parent"))
        self.assertLess(abs(sum(map(len,self.old.values())) -
                            sum(map(len,self.new.values()))),50)


if __name__=="__main__":
    unittest.main()
