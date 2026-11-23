import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from discover_tro_reference_art import candidate_files, find_art


class TroSourceTest(unittest.TestCase):
    def test_exactly_linked_official_tro_files(self):
        page = """<a href='/files/info/media/images/product_scans/tro_scans/mech/albatross.gif'>
        albatross</a><a href='/files/info/media/images/product_scans/tro_scans/mech/brigand_ldt-1.gif'>
        brigand</a><a href='https://unrelated.test/atlas.gif'>ignore</a>"""
        listing = candidate_files(page, "mech")
        self.assertEqual(set(listing), {"albatross.gif", "brigand_ldt-1.gif"})
        self.assertEqual(find_art("albatross", listing), "albatross.gif")
        self.assertEqual(find_art("brigand", listing), "brigand_ldt-1.gif")
        self.assertIsNone(find_art("atlas", listing))

    def test_do_not_accidentally_alias_similar_chassis(self):
        art = {"phoenix_hawk.gif": "a", "phoenix_hawk_lam.gif": "b"}
        self.assertEqual(find_art("phoenix_hawk", art), "phoenix_hawk.gif")
        self.assertIsNone(find_art("phoenix", art))

    def test_3025_scan_is_explicit_legacy_fallback(self):
        art = {"3025_warhammer1.jpg": "a", "3025_warhammer2.jpg": "b"}
        self.assertEqual(find_art("warhammer", art), "3025_warhammer1.jpg")


if __name__ == "__main__":
    unittest.main()
