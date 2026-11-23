import unittest
import sys
import pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "tools"))
from resolve_missing_reference_gallery import GalleryImages, image_name, permitted_image, select_image


class ReferenceGalleryTests(unittest.TestCase):
    def test_extract_exact_variant_from_gallery(self):
        parser = GalleryImages()
        parser.feed('<img alt="Hatamoto-Kaze" src="//cfw.sarna.net/wiki/images/thumb/a/ab/Hatamoto-Kaze_HTM-27V_GU28.jpg/200px-proof.jpg">'
                    '<img src="https://cfw.sarna.net/wiki/images/1/12/Hatamoto-Hi_HTM-27U_GU28.jpg">')
        got = select_image(parser.images, "Hatamoto-Kaze HTM-27V GU28.jpg")
        self.assertTrue(got.endswith("200px-proof.jpg"))
        self.assertIsNone(select_image(parser.images, "Hatamoto-Mizo HTM-27Y GU28.jpg"))

    def test_file_name_parsing_and_no_unapproved_hosts(self):
        self.assertEqual(image_name("https://cfw.sarna.net/wiki/images/thumb/1/12/Test.jpg/200px-a.jpg"),
                         "Test.jpg")
        self.assertFalse(permitted_image("https://evil.example/wiki/images/thumb/1/12/X.jpg/a.jpg"))
        self.assertFalse(permitted_image("https://cfw.sarna.net/wiki/images/thumb/1/12/X.svg/a.svg"))


if __name__ == "__main__":
    unittest.main()
