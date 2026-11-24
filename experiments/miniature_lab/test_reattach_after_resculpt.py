"""A good sculpt is repaired at its joint instead of being discarded."""
import unittest

import miniature_lab as geo
import reattach_after_resculpt as reattach


class ReattachAfterResculptTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # A deliberately re-sculpted leg with two lower armored lobes.
        # The old low knee cut splits them into floating islands.
        cls.shape = {}
        for y in range(7):
            if y <= 2:
                xs = list(range(0,3))+list(range(4,7))
            elif y == 3:
                xs = list(range(7))  # real cross-piece connects lobes
            else:
                xs = list(range(1,6))
            for x in xs:
                for z in range(4):
                    cls.shape[(x,y,z)] = "armor"
        cls.downstream = {(x,y,z):"armor"
                          for x in (1,2) for y in (-2,-1)
                          for z in range(4)}

    def test_stale_cut_is_a_reattachment_task_not_model_rejection(self):
        cut = {"normal":[0,-1,0], "origin":[0,2.5,0]}
        report = reattach.inspect(self.shape,1,cut,(self.downstream,))
        self.assertTrue(report["errors"])
        self.assertIn("disconnected", str(report["errors"]))

    def test_new_cut_recovers_two_connected_masses_and_backed_faces(self):
        candidates = [
            {"normal":[0,-1,0], "origin":[0,2.5,0]},
            {"normal":[0,-1,0], "origin":[0,3.5,0]}]
        result = reattach.find_reattachment(
            self.shape,1,candidates,(self.downstream,),target=[0,3.5,0])
        self.assertEqual(result["cut"], candidates[1])
        self.assertEqual(result["errors"], [])
        self.assertEqual(geo.components(result["retained"]),1)
        self.assertEqual(geo.components(result["claimed"]),1)
        self.assertTrue(geo.strong_contact(result["claimed"],
                                           result["retained"]))
        self.assertTrue(geo.strong_contact(self.downstream,
                                           result["claimed"]))
        self.assertEqual(set(result["retained"]) | set(result["claimed"]),
                         set(self.shape))
        self.assertFalse(set(result["retained"]) & set(result["claimed"]))
        self.assertEqual(result["angle_degrees"],0.)

    def test_apply_pivot_after_finding_real_joint_never_adds_geometry(self):
        spec={"parts":[
            {"name":"upper","shapes":[]},
            {"name":"knee","claim_from":"upper","pivot":[0,2.5,0],
             "partition":{"planes":[{"normal":[0,-1,0],
                                     "origin":[0,2.5,0]}]}},
            {"name":"shin","parent":"knee","pivot":[0,1,0],
             "shapes":[]}]}
        cut={"normal":[0,-1,0],"origin":[0,3.5,0]}
        self.assertIs(reattach.apply_to_spec(
            spec,"knee",cut,pivot=[0,3.5,0],
            downstream_pivots={"shin":[0,1.5,0]}),spec)
        self.assertEqual(spec["parts"][1]["pivot"],[0,3.5,0])
        self.assertEqual(spec["parts"][2]["pivot"],[0,1.5,0])
        self.assertEqual(spec["parts"][1]["attach_normal"],[0,1,0])
        self.assertEqual(spec["parts"][1]["partition"]["planes"],[cut])

    def test_do_not_fake_contact_with_hidden_filler(self):
        stale={"normal":[0,-1,0], "origin":[0,2.5,0]}
        with self.assertRaisesRegex(ValueError,"No sound reattachment"):
            reattach.find_reattachment(self.shape,1,[stale],
                                       downstream=(self.downstream,))


if __name__ == "__main__":
    unittest.main()
