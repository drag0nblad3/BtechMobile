"""Regression checks for source-independent reference mask scoring."""
import csv
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from score_reference_silhouettes import score_masks, weighted_overall


class ReferenceSilhouetteScoreTests(unittest.TestCase):
    def setUp(self):
        self.shape = {(x, y) for x in range(5, 15) for y in range(3, 22)}

    def test_identical_and_translation_invariant(self):
        self.assertEqual(score_masks(self.shape, self.shape), 100.0)
        moved = {(x + 11, y + 7) for x, y in self.shape}
        self.assertEqual(score_masks(self.shape, moved), 100.0)

    def test_different_body_ratio_drops_score(self):
        thin = {(x, y) for x, y in self.shape if x < 9}
        self.assertLess(score_masks(self.shape, thin), 90)

    def test_overall_requires_all_four_real_paired_views(self):
        self.assertIsNone(weighted_overall({"front": 90}))
        self.assertEqual(weighted_overall({
            "front": 80, "side": 60, "quarter": 70, "top": 50}), 71.7)

    def test_unpaired_reference_does_not_create_score(self):
        with tempfile.TemporaryDirectory() as td:
            root = pathlib.Path(td)
            (root / "renders" / "atlas").mkdir(parents=True)
            (root / "references" / "atlas").mkdir(parents=True)
            lines = ["".join("#" if (x, y) in self.shape else "."
                     for x in range(25)) for y in range(25)]
            for view in ("front", "side"):
                (root / "renders" / "atlas" / (view + ".txt")).write_text(
                    "\n".join(lines) + "\n", encoding="utf-8")
            (root / "references" / "atlas" / "front.txt").write_text(
                "\n".join(lines) + "\n", encoding="utf-8")
            scorecard = root / "input.csv"
            with scorecard.open("w", newline="", encoding="utf-8") as output:
                writer = csv.DictWriter(output, fieldnames=[
                    "model", "status", "front_0_100", "side_0_100",
                    "quarter_0_100", "top_0_100", "overall_0_100",
                    "stance_review_status", "stance_profile"])
                writer.writeheader()
                writer.writerow({"model": "atlas", "front_0_100": "12.0",
                                 "stance_review_status": "VERIFIED_RIG_MATCH",
                                 "stance_profile": "reference-stance-poses.json"})
            result = root / "output.csv"
            run = subprocess.run([sys.executable,
                                  str(ROOT / "tools/score_reference_silhouettes.py"),
                                  "--scorecard", str(scorecard),
                                  "--renders", str(root / "renders"),
                                  "--references", str(root / "references"),
                                  "--output", str(result)],
                                 capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stderr)
            with result.open(newline="", encoding="utf-8") as file:
                row = next(csv.DictReader(file))
            self.assertEqual(row["front_0_100"], "100.0")
            self.assertEqual(row["side_0_100"], "")
            self.assertEqual(row["overall_0_100"], "")
            self.assertIn("1_OF_4", row["status"])

            # Same image evidence is rejected when stance verification is revoked.
            with scorecard.open("w", newline="", encoding="utf-8") as output:
                writer = csv.DictWriter(output, fieldnames=[
                    "model", "status", "front_0_100", "side_0_100",
                    "quarter_0_100", "top_0_100", "overall_0_100",
                    "stance_review_status", "stance_profile"])
                writer.writeheader()
                writer.writerow({"model": "atlas", "front_0_100": "98.0",
                                 "stance_review_status": "UNVERIFIED_POSE"})
            again = subprocess.run([sys.executable,
                                    str(ROOT / "tools/score_reference_silhouettes.py"),
                                    "--scorecard", str(scorecard),
                                    "--renders", str(root / "renders"),
                                    "--references", str(root / "references"),
                                    "--output", str(result)],
                                   capture_output=True, text=True)
            self.assertEqual(again.returncode, 0, again.stderr)
            with result.open(newline="", encoding="utf-8") as file:
                rejected = next(csv.DictReader(file))
            self.assertEqual(rejected["front_0_100"], "")
            self.assertEqual(rejected["overall_0_100"], "")
            self.assertEqual(rejected["status"], "AWAITING_RIG_STANCE_MATCH")


if __name__ == "__main__":
    unittest.main()
