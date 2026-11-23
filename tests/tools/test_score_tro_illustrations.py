import pathlib
import sys
import unittest

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from score_tro_illustrations import fill_art_contour
from score_reference_silhouettes import read_mask


class TroIllustrationTest(unittest.TestCase):
    def test_closed_ink_outline_fills_as_voxel_silhouette(self):
        image = Image.new("L", (100, 100), 255)
        painter = ImageDraw.Draw(image)
        painter.rectangle((20, 15, 80, 85), outline=35, width=3)
        mask, covered = fill_art_contour(image)
        self.assertGreater(covered, 0.30)
        self.assertLess(covered, 0.60)
        self.assertIn((50, 50), {
            p for p in read_mask_from_image(mask)})
        self.assertNotIn((4, 4), read_mask_from_image(mask))

    def test_blank_page_never_receives_an_unearned_score(self):
        blank = Image.new("L", (50, 50), 255)
        with self.assertRaises(ValueError):
            fill_art_contour(blank)


def read_mask_from_image(image):
    pixels = image.load()
    return {(x, y) for y in range(image.height) for x in range(image.width)
            if pixels[x, y] == (0, 0, 0)}


if __name__ == "__main__":
    unittest.main()
