"""No fabricated scores and no mixed comparisons in photo-fit deltas."""
import importlib.util
import pathlib
import unittest

MODULE = pathlib.Path(__file__).resolve().parents[2] / "tools/qa/photo_fit_delta.py"
SPEC = importlib.util.spec_from_file_location("photo_fit_delta", MODULE)
code = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(code)


class CameraResculptDeltaTests(unittest.TestCase):
    def test_both_camera_pairs_have_provisional_numeric_deltas(self):
        old = {"candidate_results": [
            {"model": "victor", "view": "front",
             "score_camera_adjusted_unverified": 40.0,
             "pose_fit_0_100_provisional": 42.4}]}
        new = {"candidate_results": [
            {"model": "victor", "view": "front",
             "score_camera_adjusted_unverified": 42.7,
             "pose_fit_0_100_provisional": 41.0}]}
        result = code.compare_reports(old, new)
        self.assertEqual(result["comparable"], 1)
        self.assertEqual(result["approved_scores"], 0)
        self.assertEqual(result["improved_at_least_2"], 1)
        self.assertEqual(result["degraded_at_least_2"], 0)
        self.assertEqual(result["rows"][0]["fit_camera_delta_unverified"], 2.7)
        self.assertEqual(result["rows"][0]["pose_delta_unverified"], -1.4)
        self.assertFalse(result["rows"][0]["approved_score"])

    def test_missing_source_or_failed_photo_never_makes_up_scores(self):
        old = {"candidate_results": [
            {"model": "archer", "view": "front",
             "score_camera_adjusted_unverified": 51.0}]}
        new = {"candidate_results": [
            {"model": "archer", "view": "front", "error": "HTTP 404"}]}
        result = code.compare_reports(old, new)
        self.assertEqual(result["comparable"], 0)
        self.assertEqual(result["missing_or_failed"], 1)
        self.assertIsNone(result["rows"][0]["fit_camera_delta_unverified"])
        self.assertEqual(result["rows"][0]["status"],
                         "UNSCORED_NO_MATCHED_CAMERA_PAIR")

    def test_mismatched_models_stay_unscored(self):
        before = {"candidate_results": [
            {"model": "turkina", "view": "quarter",
             "score_camera_adjusted_unverified": 48.0}]}
        after = {"candidate_results": [
            {"model": "charger", "view": "quarter",
             "score_camera_adjusted_unverified": 40.0}]}
        result = code.compare_reports(before, after)
        self.assertEqual(result["models_attempted"], 2)
        self.assertEqual(result["comparable"], 0)

    def test_duplicate_camera_candidate_is_rejected(self):
        repeated = {"candidate_results": [
            {"model": "crossbow", "view": "front"},
            {"model": "crossbow", "view": "front"}]}
        with self.assertRaises(ValueError):
            code.compare_reports(repeated, {})


if __name__ == "__main__":
    unittest.main()
