import pathlib
import sys
import unittest

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from score_first_reference_photos import remove_noise, prepare_mask


class PhotoMaskIsolationTest(unittest.TestCase):
    def test_catalog_watermark_does_not_become_mech_silhouette(self):
        im = Image.new("RGB", (160, 160), "white")
        draw = ImageDraw.Draw(im)
        draw.rectangle((20, 20, 85, 143), fill="black")
        # Source gallery inset/logo is disconnected from miniature.
        draw.rectangle((123, 119, 149, 147), fill="black")
        mask, cover, share = prepare_mask(im, threshold=205)
        pixel = mask.load()
        self.assertEqual(pixel[55, 70], (0, 0, 0))
        self.assertEqual(pixel[134, 131], (255, 255, 255))
        self.assertGreater(share, 0.90)
        self.assertLess(share, 0.93)

    def test_poses_and_cannons_remain_when_connected_to_torso(self):
        im = Image.new("RGB", (160, 160), "white")
        draw = ImageDraw.Draw(im)
        draw.rectangle((58, 25, 94, 84), fill="black")
        draw.rectangle((15, 45, 70, 55), fill="black")
        draw.rectangle((60, 84, 72, 145), fill="black")
        draw.rectangle((83, 84, 95, 145), fill="black")
        mask, _, share = prepare_mask(im, threshold=205)
        self.assertEqual(mask.getpixel((18, 50)), (0, 0, 0))
        self.assertEqual(mask.getpixel((67, 139)), (0, 0, 0))
        self.assertEqual(mask.getpixel((91, 137)), (0, 0, 0))
        self.assertEqual(share, 1.0)

    def test_empty_or_disconnected_art_is_detected(self):
        isolated, fraction = remove_noise(
            {(2, 2), (3, 2), (30, 30)}, 40, 40)
        self.assertEqual(isolated, {(2, 2), (3, 2)})
        self.assertAlmostEqual(fraction, 2 / 3, places=4)
        white = Image.new("RGB", (80, 80), "white")
        with self.assertRaises(ValueError):
            prepare_mask(white)


if __name__ == "__main__":
    unittest.main()
