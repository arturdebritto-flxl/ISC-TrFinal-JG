import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def encode_bgr233(red: int, green: int, blue: int) -> int:
    return (blue & 0xC0) | ((green & 0xE0) >> 2) | (red >> 5)


def decode_bgr233(value: int) -> tuple[int, int, int]:
    red3 = value & 0x07
    green3 = (value >> 3) & 0x07
    blue2 = (value >> 6) & 0x03
    red = (red3 << 5) | (red3 << 2) | (red3 >> 1)
    green = (green3 << 5) | (green3 << 2) | (green3 >> 1)
    blue = (blue2 << 6) | (blue2 << 4) | (blue2 << 2) | blue2
    return red, green, blue


class ColorEncodingTests(unittest.TestCase):
    def test_calibration_palette(self) -> None:
        cases = {
            (255, 0, 0): 0x07,
            (0, 255, 0): 0x38,
            (0, 0, 255): 0xC0,
            (255, 255, 255): 0xFF,
            (128, 128, 128): 0xA4,
            (255, 255, 0): 0x3F,
            (0, 255, 255): 0xF8,
            (255, 0, 255): 0xC7,
        }
        for rgb, expected in cases.items():
            with self.subTest(rgb=rgb):
                self.assertEqual(encode_bgr233(*rgb), expected)

    def test_primary_colors_decode_without_channel_swap(self) -> None:
        self.assertEqual(decode_bgr233(0x07), (255, 0, 0))
        self.assertEqual(decode_bgr233(0x38), (0, 255, 0))
        self.assertEqual(decode_bgr233(0xC0), (0, 0, 255))
        self.assertEqual(decode_bgr233(0xFF), (255, 255, 255))

    def test_zero_and_opaque_black_have_distinct_values(self) -> None:
        transparent = 0x00
        opaque_black = 0x01
        self.assertNotEqual(transparent, opaque_black)
        self.assertEqual(decode_bgr233(opaque_black), (36, 0, 0))


class AssemblyColorContractTests(unittest.TestCase):
    def test_hud_and_scene_hardcoded_colors_are_bgr233(self) -> None:
        constants = (ROOT / "src" / "constants.s").read_text(encoding="utf-8")
        expected = {
            "COLOR_WHITE": "0xFF",
            "COLOR_SCENE_BORDER": "0x09",
            "COLOR_TOWN_DETAIL": "0x54",
            "COLOR_SEWER_DETAIL": "0x38",
            "COLOR_LAB_PANEL": "0x5B",
            "COLOR_LAB_DETAIL": "0xA4",
            "COLOR_PLAYER_BULLET": "0x3F",
            "COLOR_ENEMY_BULLET": "0x27",
        }
        for name, value in expected.items():
            self.assertRegex(constants, rf"\.eqv\s+{name}\s+{value}\b")

        hud = (ROOT / "src" / "hud.s").read_text(encoding="utf-8")
        render = (ROOT / "src" / "render.s").read_text(encoding="utf-8")
        self.assertIn("li a3, COLOR_WHITE", hud)
        self.assertIn("li a4, COLOR_SCENE_BORDER", render)

    def test_calibration_uses_frame_zero_byte_writes_and_skip(self) -> None:
        source = (ROOT / "test_color_calibration.s").read_text(encoding="utf-8")
        self.assertIn(".eqv FRAMEBUFFER0, 0xFF000000", source)
        self.assertRegex(source, r"draw_color_swatch:\s+beqz a2,")
        self.assertRegex(source, r"fill_rect_col_loop:[\s\S]*?\bsb a2, 0\(t4\)")
        for value in ("0x07", "0x38", "0xC0", "0xFF", "0xA4",
                      "0x3F", "0xF8", "0xC7", "0x01", "0x00"):
            self.assertIn(f"li a2, {value}", source)

    def test_sprite_blitter_loads_unsigned_skips_zero_and_stores_byte(self) -> None:
        source = (ROOT / "src" / "render.s").read_text(encoding="utf-8")
        fast_blitter = source[
            source.index("draw_sprite_8bpp_fast:"):
            source.index("end_draw_sprite_8bpp_fast:")
        ]
        self.assertGreaterEqual(len(re.findall(r"\blbu a7, 0\(t2\)", fast_blitter)), 2)
        self.assertGreaterEqual(len(re.findall(r"\bbeqz a7,", fast_blitter)), 2)
        self.assertGreaterEqual(len(re.findall(r"\bsb a7,", fast_blitter)), 2)


if __name__ == "__main__":
    unittest.main()
