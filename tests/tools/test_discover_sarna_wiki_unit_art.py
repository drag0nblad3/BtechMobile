import pathlib
import sys
import unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from discover_sarna_wiki_unit_art import decode_page, Infobox


def page(title, name, src):
    return (f'<title>{title} - BattleTechWiki</title>'
            '<img src="https://cfw.sarna.net/images/ads/banner.png"/>'
            '<table class="infobox"><tr><td>'
            f'<a href="/wiki/File:{name}"><img alt="{name}" src="{src}"/></a>'
            '</td></tr></table>')


class WikiInfoboxTest(unittest.TestCase):
    def test_infobox_only_ignores_ads(self):
        src = "https://cfw.sarna.net/wiki/images/thumb/4/46/Alfar.jpg/300px-test.jpg"
        result = decode_page(page("Álfar", "Alfar.jpg", src), "alfar")
        self.assertEqual(result["image_url"], src)
        self.assertEqual(result["reference_tier"],
                         "Sarna_infobox_art_generation_unverified")

    def test_modern_recognition_guide_is_identified(self):
        src = "https://cfw.sarna.net/wiki/images/thumb/8/88/Glass_RGilClan_v13.png/300px-test.png"
        result = decode_page(page("Glass Spider (Galahad)",
                                  "Glass_Spider_RGilClan_v13.png", src),
                             "glass_spider")
        self.assertEqual(result["reference_tier"],
                         "modern_Recognition_Guide_illustration")
        self.assertFalse(result["generation_approved"])

    def test_wrong_chassis_and_spurious_image_are_rejected(self):
        src = "https://cfw.sarna.net/wiki/images/thumb/a/Atlas.jpg/300px-test.jpg"
        self.assertIsNone(decode_page(page("Phoenix Hawk", "Atlas.jpg", src),
                                      "phoenix"))
        self.assertIsNone(decode_page(page("Atlas", "Atlas.jpg",
                                         "https://tracker.example/atlas.jpg"),
                                      "atlas"))
        self.assertIsNone(decode_page(
            '<title>Rook - BattleTechWiki</title><img src="' + src + '"/>',
            "rook"))

    def test_variant_family_references_are_not_exact_sculpts(self):
        src = "https://cfw.sarna.net/wiki/images/thumb/9/9f/Elemental.png/300px-test.png"
        self.assertIsNotNone(decode_page(
            page("Elemental (Battle Armor)", "Elemental.png", src),
            "battle_armor/elemental_ba_laser"))
        self.assertIsNotNone(decode_page(page("Bulldog Medium Tank",
            "Bulldog_RGilClan.jpg", src), "vehicle/bulldog_medium_tank"))


if __name__ == "__main__":
    unittest.main()
