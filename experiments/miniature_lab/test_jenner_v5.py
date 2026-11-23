"""Only experimental Jenner v5; never modify or load merged production art."""
import json
import unittest
from pathlib import Path
import miniature_lab as vox
import reference_fit as fit
import photo_fit as photos

HERE = Path(__file__).resolve().parent


class JennerV5Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base = json.loads((HERE / 'jenner_assembly_combined.json').read_text())
        cls.trial = json.loads((HERE / 'jenner_assembly_v5.json').read_text())
        cls.base_cells = vox.rasterize(cls.base)
        cls.trial_cells = vox.rasterize(cls.trial)

    def test_new_head_has_true_round_disk_cross_sections(self):
        head = next(p for p in self.trial['parts'] if p['name'] == 'hd')
        self.assertEqual(head['shapes'][0]['axis'], 'z')
        self.assertTrue(all(len(s['polygon']) == 16 for s in
                            head['shapes'][0]['sections']))
        self.assertTrue(any(s['mat'] == 'glass' for s in head['shapes']))

    def test_head_shoulder_and_pod_connections_need_no_repair(self):
        self.assertEqual(vox.audit(self.trial, self.trial_cells), [])
        self.assertEqual({p['loc'] for p in self.trial['parts']},
                         {'HD', 'CT', 'LT', 'RT', 'LA', 'RA', 'LL', 'RL'})
        self.assertEqual(len(self.trial['parts']), 12)

    def test_older_merged_source_is_never_a_dependency(self):
        self.assertFalse(any('data/voxels/' in str(v) for v in
                             self.trial.values() if isinstance(v, str)))
        self.assertEqual(self.trial['unit'], 'jenner_jr7d')
        self.assertEqual(self.trial['pitch'], .04)

    def test_camera_landmark_proxy_is_reported_not_called_ground_truth(self):
        annotated = json.loads((HERE / 'jenner_photo_landmarks.json').read_text())
        old = fit.score(self.base, self.base_cells, annotated)
        new = fit.score(self.trial, self.trial_cells, annotated)
        self.assertLess(new['mean_rigid_rmse'], old['mean_rigid_rmse'])
        rough = json.loads((HERE / 'jenner_photo_annotations.json').read_text())
        old_sil = photos.fit(self.base, self.base_cells, rough, 50)['mean_iou']
        new_sil = photos.fit(self.trial, self.trial_cells, rough, 50)['mean_iou']
        # Known silhouette regression remains visible; never promote blindly.
        self.assertLess(new_sil, old_sil)


if __name__ == '__main__':
    unittest.main()
