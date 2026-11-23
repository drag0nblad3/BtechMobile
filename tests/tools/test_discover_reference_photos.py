import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from discover_reference_photos import discover, normalized


class GalleryDiscoveryTest(unittest.TestCase):
    def test_plastic_image_is_matched_and_not_fabricated(self):
        page = """<table><tr><td>BattleAxe</td><td>4-35</td><td>AXM</td>
        <td>Mech</td><td>Pack</td><td>123</td>
        <td><a href='/Pictures/CGLminis/battleaxe4-35.jpg'>Image</a></td></tr>
        <tr><td>Goliath</td><td>4</td><td>1A</td><td>Mech</td><td>Pack</td>
        <td>2</td><td>No image available</td></tr>
        </table>"""
        matched = discover(page, {"battleaxe": "battleaxe", "goliath": "goliath"})
        self.assertEqual(len(matched), 1)
        self.assertEqual(matched[0]["model"], "battleaxe")
        self.assertIn("battleaxe4-35.jpg", matched[0]["image_url"])
        self.assertEqual(matched[0]["status"],
                         "DISCOVERED_PHOTO_NEEDS_POSE_CAMERA_MASK_REVIEW")

    def test_reject_untrusted_image_domains_and_non_mechs(self):
        page = """<tr><td>Atlas</td><td>99</td><td></td><td>Mech</td>
        <td>Pack</td><td>2</td><td>
        <a href='https://not-source.example/e.jpg'>Image</a></td></tr>
        <tr><td>SRM Carrier</td><td>77</td><td></td><td>Vehicle</td>
        <td>Pack</td><td>2</td><td>
        <a href='/Pictures/CGLminis/srm.jpg'>Image</a></td></tr>"""
        self.assertEqual(discover(page, {"atlas": "atlas", "srmcarrier": "srm_carrier"}), [])

    def test_normalize_catalyst_names(self):
        self.assertEqual(normalized("Phoenix Hawk"), "phoenixhawk")
        self.assertEqual(normalized("phoenix_hawk"), "phoenixhawk")
        self.assertEqual(normalized("Mad Cat"), "timberwolf")


if __name__ == "__main__":
    unittest.main()
