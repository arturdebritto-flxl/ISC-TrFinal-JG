import re
import unittest

from PIL import Image

from tools import build_text_cutscenes_bgr233


class TextCutsceneBuildTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = build_text_cutscenes_bgr233.build()

    def test_sources_are_exactly_320x240_and_keep_the_expected_structure(self):
        expected_colors = set(build_text_cutscenes_bgr233.COLOR_MAP)
        for name in build_text_cutscenes_bgr233.SOURCE_NAMES:
            path = build_text_cutscenes_bgr233.SOURCE_DIR / name
            with Image.open(path) as source:
                image = source.convert("RGBA")
            self.assertEqual(image.size, (320, 240))
            self.assertEqual(set(image.get_flattened_data()), expected_colors)

    def test_each_payload_has_exactly_76800_direct_bgr233_bytes(self):
        self.assertEqual(len(self.result.payloads), 4)
        for payload in self.result.payloads:
            self.assertEqual(len(payload), 76800)
            self.assertEqual(set(payload), {0x00, 0x52, 0xFF})

    def test_mapping_is_explicit_and_preserves_every_coordinate(self):
        for index, name in enumerate(build_text_cutscenes_bgr233.SOURCE_NAMES):
            path = build_text_cutscenes_bgr233.SOURCE_DIR / name
            with Image.open(path) as source:
                pixels = source.convert("RGBA").get_flattened_data()
            expected = bytes(build_text_cutscenes_bgr233.COLOR_MAP[pixel] for pixel in pixels)
            self.assertEqual(self.result.payloads[index], expected)

    def test_generation_is_deterministic(self):
        repeated = build_text_cutscenes_bgr233.build()
        self.assertEqual(self.result, repeated)

    def test_checked_in_outputs_and_previews_are_current(self):
        for path, content in self.result.files:
            self.assertTrue(path.exists(), path)
            self.assertEqual(path.read_bytes(), content, path)


class TextCutsceneIntegrationTests(unittest.TestCase):
    def test_render_maps_the_four_image_states_to_four_text_payloads(self):
        render = (build_text_cutscenes_bgr233.ROOT / "src" / "render.s").read_text(encoding="utf-8")
        for index in range(4):
            self.assertIn(f'text_cutscene_{index}.data"', render)
            self.assertIn(f"text_cutscene_{index}_pixels", render)
        self.assertIn("li t2, 76800", render)

    def test_flow_requires_a_fresh_event_between_image_and_text(self):
        screens = (build_text_cutscenes_bgr233.ROOT / "src" / "screens.s").read_text(encoding="utf-8")
        self.assertIn("cutscene_advance_pressed:", screens)
        self.assertIn("cutscene_discard_pending_loop:", screens)
        self.assertIn("cutscene_wait_new_event:", screens)
        self.assertEqual(len(re.findall(r"^\s*call show_text_cutscene\s*$", screens, re.MULTILINE)), 1)
        self.assertEqual(len(re.findall(r"^\s*jal show_text_cutscene_3\s*$", screens, re.MULTILINE)), 1)
        self.assertIn("call set_state_cutscene_explosion", screens)


if __name__ == "__main__":
    unittest.main()
