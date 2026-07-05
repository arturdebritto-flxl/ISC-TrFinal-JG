import tempfile
import unittest
from pathlib import Path

from PIL import Image

from tools.sprite_pipeline.pilot import (
    build_player_idle_front,
    build_rat_common_side,
    generate_pilots,
    image_stats,
    rgba_to_rars8,
)


ROOT = Path(__file__).resolve().parents[1]


class SpritePilotTests(unittest.TestCase):
    def test_player_pilot_preserves_native_contract(self):
        image = build_player_idle_front()
        stats = image_stats(image)

        self.assertEqual((16, 16), image.size)
        self.assertEqual("RGBA", image.mode)
        self.assertEqual([0, 255], stats["alpha_values"])
        self.assertFalse(stats["partial_alpha"])
        self.assertGreaterEqual(stats["opaque_colors"], 8)
        self.assertLessEqual(stats["opaque_colors"], 10)
        self.assertEqual((3, 2, 13, 16), stats["bbox"])

    def test_rat_pilot_preserves_native_contract(self):
        image = build_rat_common_side()
        stats = image_stats(image)

        self.assertEqual((16, 16), image.size)
        self.assertEqual([0, 255], stats["alpha_values"])
        self.assertFalse(stats["partial_alpha"])
        self.assertGreaterEqual(stats["opaque_colors"], 7)
        self.assertLessEqual(stats["opaque_colors"], 10)
        self.assertEqual((0, 4, 16, 14), stats["bbox"])

    def test_rars_encoding_reserves_zero_for_transparency(self):
        self.assertEqual(0, rgba_to_rars8((20, 20, 20, 0)))
        self.assertNotEqual(0, rgba_to_rars8((0, 0, 0, 255)))

    def test_generation_writes_only_native_pilots_and_previews(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            generated = generate_pilots(ROOT, output)

            self.assertEqual(4, len(generated))
            for path in generated:
                self.assertTrue(path.is_file(), path)
            with Image.open(output / "previews" / "player_comparison.png") as preview:
                self.assertEqual((512, 256), preview.size)
            with Image.open(output / "previews" / "rat_common_comparison.png") as preview:
                self.assertEqual((512, 256), preview.size)


if __name__ == "__main__":
    unittest.main()
