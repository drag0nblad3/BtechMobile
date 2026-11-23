"""Independent Jenner v7 regression: geometry, joins, ancestry and photo proxy."""
import copy
import json
import unittest
from pathlib import Path
import miniature_lab as geo
import subassembly as seams
import photo_fit as reference
import make_jenner_v7 as generator

HERE = Path(__file__).resolve().parent


class JennerV7Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.v5 = json.loads((HERE / "jenner_assembly_v5.json").read_text())
        cls.v7 = json.loads((HERE / "jenner_assembly_v7.json").read_text())
        cls.cells = geo.rasterize(cls.v7)

    def test_generator_reproduces_every_source_part(self):
        generated = generator.build()
        for a, b in zip(generated["parts"], self.v7["parts"]):
            self.assertEqual(a, b)
        self.assertEqual(len(generated["parts"]), 30)

    def test_thirty_unique_connected_owners_and_all_damage_locations(self):
        self.assertEqual(geo.audit(self.v7, self.cells), [])
        self.assertEqual(len(self.cells), 30)
        self.assertEqual({p["loc"] for p in self.v7["parts"]},
                         {"CT", "HD", "LT", "RT", "LA", "RA", "LL", "RL"})
        for name, cells in self.cells.items():
            self.assertEqual(geo.components(cells), 1, name)

    def test_contours_are_detailed_and_not_extra_volume(self):
        indexed = {p["name"]:p for p in self.v7["parts"]}
        for name in ("hd", "la", "ra"):
            self.assertGreaterEqual(max(len(s["polygon"])
                    for shape in indexed[name]["shapes"]
                    for s in shape["sections"]), 24)
        unsplit = copy.deepcopy(self.v7)
        unsplit["parts"] = [p for p in unsplit["parts"] if not p.get("claim_from")]
        original = {c:mat for part in geo.rasterize(unsplit).values()
                    for c,mat in part.items()}
        cut = {c:mat for part in self.cells.values() for c,mat in part.items()}
        self.assertEqual(original, cut)
        v5_count = sum(len(part) for part in geo.rasterize(self.v5).values())
        self.assertLess(len(cut), v5_count * 1.02)

    def test_all_joint_faces_are_backed_and_angular_normals_are_real(self):
        for p in self.v7["parts"]:
            if not p.get("claim_from"):
                continue
            child, parent = self.cells[p["name"]], self.cells[p["parent"]]
            self.assertTrue(geo.strong_contact(child, parent), p["name"])
            self.assertEqual(seams.check_direction(p, child, parent), [], p["name"])
        for prefix in ("l", "r"):
            mount = next(p for p in self.v7["parts"]
                         if p["name"] == prefix+"a_inboard_socket")
            arm = next(p for p in self.v7["parts"]
                       if p["name"] == prefix+"a")
            self.assertEqual(arm["parent"], mount["name"])
            bad = copy.deepcopy(mount)
            bad["attach_normal"] = [0, -1, 0]
            self.assertTrue(seams.check_direction(bad,
                            self.cells[mount["name"]], self.cells[mount["parent"]]))

    def test_export_parents_precede_children_even_after_part_split(self):
        recipe = geo.export(self.v7, self.cells)
        seen = set()
        for p in recipe["parts"]:
            self.assertTrue(not p.get("parent") or p["parent"] in seen)
            seen.add(p["name"])
        self.assertEqual(len(recipe["parts"]), 30)
        self.assertEqual(len(recipe["muzzles"]["LA"]), 2)
        self.assertEqual(len(recipe["muzzles"]["RA"]), 2)

    def test_reference_proxy_does_not_regress_against_v5(self):
        annotations = json.loads((HERE/"jenner_photo_annotations.json").read_text())
        before = reference.fit(self.v5, geo.rasterize(self.v5),
                               annotations, 50)["mean_iou"]
        after = reference.fit(self.v7, self.cells, annotations, 50)["mean_iou"]
        self.assertGreaterEqual(after, before)
        # Approximate hand-traced contours, not true photo-matching accuracy.


if __name__ == "__main__":
    unittest.main()
