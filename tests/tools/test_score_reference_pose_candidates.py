import pathlib
import tempfile
import unittest
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from score_reference_pose_candidates import select_candidates


class PoseCandidateScoreTest(unittest.TestCase):
    def test_real_mask_pair_selects_closest_joint_pose(self):
        with tempfile.TemporaryDirectory() as td:
            folder = pathlib.Path(td)
            refs = folder / "references" / "sample"
            refs.mkdir(parents=True)
            (refs / "front.txt").write_text(
                "####..\n####..\n..##..\n..##..\n", encoding="utf-8")
            a = folder / "neutral.txt"
            b = folder / "posed.txt"
            a.write_text("####..\n####..\n####..\n####..\n", encoding="utf-8")
            b.write_text("####..\n####..\n..##..\n..##..\n", encoding="utf-8")
            poses = [{"model": "sample", "view": "front",
                      "candidate_id": "neutral", "joints": {}, "camera": {},
                      "path": str(a)},
                     {"model": "sample", "view": "front",
                      "candidate_id": "step_left",
                      "joints": {"ll": [18, 0, 0]}, "camera": {},
                      "path": str(b)}]
            row = select_candidates({"model": "sample", "view": "front"},
                                    folder / "references", poses)
            self.assertEqual(row["pose_fit_0_100_provisional"], 100.0)
            self.assertEqual(row["pose_candidate_id"], "step_left")
            self.assertEqual(row["pose_candidates_tested"], 2)
            self.assertIn("UNVERIFIED", row["pose_status"])

    def test_no_unverified_mask_is_never_marked_as_scored(self):
        with tempfile.TemporaryDirectory() as td:
            result = select_candidates({"model": "missing",
                                        "view": "front"}, pathlib.Path(td), [])
            self.assertIn("error", result)
            self.assertNotIn("pose_fit_0_100_provisional", result)


if __name__ == "__main__":
    unittest.main()
