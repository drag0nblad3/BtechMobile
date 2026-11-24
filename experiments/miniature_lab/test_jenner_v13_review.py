"""Anatomy review safety checks; no v13 promotion without photo registration."""
import json
import unittest
from pathlib import Path

import miniature_lab as geo
import make_jenner_v13_review as draft

HERE=Path(__file__).resolve().parent


class JennerV13AnatomyReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.baseline=json.loads((HERE/"jenner_assembly_v12.json").read_text())
        cls.saved=json.loads((HERE/"jenner_assembly_v13_review.json").read_text())
        cls.generated=draft.build()
        cls.cells=geo.rasterize(cls.saved)
        cls.original=geo.rasterize(cls.baseline)

    def test_trial_reproduces_and_never_claims_acceptance(self):
        self.assertEqual(geo.rasterize(self.generated),self.cells)
        self.assertIn("UNACCEPTED",self.saved["review_status"])
        self.assertEqual(self.saved["sculpt"],self.baseline["sculpt"])
        self.assertEqual(len(self.saved["parts"]),30)

    def test_all_rig_pivots_are_unchanged(self):
        old={p["name"]:p for p in self.baseline["parts"]}
        for part in self.saved["parts"]:
            self.assertEqual(part.get("pivot"),old[part["name"]].get("pivot"))

    def test_source_geometry_is_connected_and_backed(self):
        self.assertEqual(geo.audit(self.saved,self.cells),[])
        for p in self.saved["parts"]:
            if p.get("parent"):
                self.assertTrue(geo.strong_contact(
                    self.cells[p["name"]],self.cells[p["parent"]]),p["name"])

    def test_refinement_is_more_controlled_not_a_fake_leg_accuracy_score(self):
        shapes={p["name"]:p["shapes"] for p in self.saved["parts"]}
        for p in ("ll","rl","ll_shin","rl_shin"):
            hull=shapes[p][0]
            self.assertEqual(len(hull["sections"]),5)
            self.assertTrue(all(len(x["polygon"])==16 for x in hull["sections"]))
        # At 0.04-pitch these surface controls may rasterize identically.
        # Do NOT promote purely because polygon/section counts increase.
        self.assertLess(sum(len(v) for v in self.cells.values()),
                        sum(len(v) for v in self.original.values()))
        self.assertNotIn("accepted_accuracy",self.saved)


if __name__=="__main__":
    unittest.main()
