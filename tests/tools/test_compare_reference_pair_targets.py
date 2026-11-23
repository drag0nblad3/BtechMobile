"""Never invent reference scores: unavailable sources remain explicitly unscored."""
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "tools"))
from compare_reference_pair_targets import assess, fetch_art, reference_mask
from PIL import Image, ImageDraw


class PairTrialTests(unittest.TestCase):
    def test_reject_unapproved_source(self):
        with self.assertRaises(ValueError):
            fetch_art("https://example.com/art.png")

    def test_identical_reference_models_score_high(self):
        with tempfile.TemporaryDirectory() as root:
            r = pathlib.Path(root)
            models = r / "models"
            for name in ("m1", "m2"):
                d = models / name
                d.mkdir(parents=True)
                (d / "quarter.txt").write_text(
                    "".join("." * 16 + "\n" for _ in range(4)) +
                    "".join("." * 3 + "#" * 10 + "." * 3 + "\n" for _ in range(8)) +
                    "".join("." * 16 + "\n" for _ in range(4)))
            im = Image.new("RGB", (250, 250), "white")
            ImageDraw.Draw(im).rectangle((55, 35, 195, 225), fill="black")
            result = assess([{"name":"Synthetic","view":"quarter",
                "a":{"model":"m1","image_url":"https://cfw.sarna.net/a","source_page":"a",
                     "bounds":[0.1,0.1,0.9,0.95]},
                "b":{"model":"m2","image_url":"https://cfw.sarna.net/b","source_page":"b",
                     "bounds":[0.1,0.1,0.9,0.95]}}], models, r / "out",
                downloader=lambda url: im.convert("RGBA"))
            self.assertEqual(result["pairs"][0]["status"],
                             "PROVISIONAL_NEEDS_FOREGROUND_CAMERA_POSE_REVIEW")
            self.assertEqual(result["pairs"][0]["reference_similarity_0_100"],100)
            self.assertEqual(result["pairs"][0]["model_similarity_0_100"],100)
            self.assertEqual(result["approved_four_angle_scores"],0)

    def test_missing_source_stays_unscored(self):
        with tempfile.TemporaryDirectory() as root:
            results=assess([{"name":"Missing","a":{"model":"a","image_url":"https://cfw.sarna.net/x",
                        "source_page":"a","bounds":[0,0,1,1]},
                        "b":{"model":"b","image_url":"https://cfw.sarna.net/y",
                        "source_page":"b","bounds":[0,0,1,1]}}],
                    pathlib.Path(root), pathlib.Path(root)/"out",
                    downloader=lambda _: (_ for _ in ()).throw(ValueError("unavailable")))
            self.assertIsNone(results["pairs"][0]["reference_similarity_0_100"])
            self.assertEqual(results["pairs"][0]["status"], "UNSCORABLE")


if __name__=="__main__":
    unittest.main()
