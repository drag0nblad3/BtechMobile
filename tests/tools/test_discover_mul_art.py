import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from discover_mul_art import Page, accept_page, candidates_for

ART = "/point-backs/unit-art/manual/bulldog-7c96a0.webp"


def page(title, image=ART):
    return (f'<html><head><title>{title} · BattleTech</title></head>'
            f'<body><a href="{image}">'
            f'<img alt="{title} illustration" src="{image}"></a></body></html>')


class OfficialMULSourceTest(unittest.TestCase):
    def test_real_official_tank_image_is_accepted(self):
        matched = accept_page(page("Bulldog Medium Tank"),
                              "vehicle/bulldog_medium_tank")
        self.assertIsNotNone(matched)
        self.assertEqual(matched["image_url"],
                         "https://masterunitlist.battletech.com" + ART)

    def test_named_glass_spider_alias(self):
        matched = accept_page(page("Galahad (Glass Spider)"),
                              "glass_spider")
        self.assertIsNotNone(matched)

    def test_wrong_model_or_origin_cannot_be_accepted(self):
        self.assertIsNone(accept_page(page("Phoenix Hawk"), "phoenix"))
        self.assertIsNone(accept_page(page("Atlas",
            "https://untrusted.example/point-backs/unit-art/manual/a.webp"),
            "atlas"))

    def test_actual_battle_armor_variant(self):
        self.assertIsNotNone(accept_page(
            page("Elemental Battle Armor [Laser] (Sqd4)"),
            "battle_armor/elemental_ba_laser"))
        self.assertIsNone(accept_page(
            page("Elemental Battle Armor [Flamer] (Sqd4)"),
            "battle_armor/elemental_ba_laser"))

    def test_generic_archetypes_cannot_inherit_arbitrary_unit_art(self):
        self.assertEqual(candidates_for("archetype/tracked_tank"), [])
        self.assertIn("bulldog-medium-tank",
                      candidates_for("vehicle/bulldog_medium_tank"))


if __name__ == "__main__":
    unittest.main()
