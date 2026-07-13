import hashlib
import unittest

from tools import build_town_bgr233


class TownBgr233BuildTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = build_town_bgr233.build(write=False)

    def test_sources_are_opaque_320x240_with_approved_66_pixel_mask(self):
        self.assertEqual(self.result.source_size, (320, 240))
        self.assertTrue(self.result.sources_opaque)
        self.assertEqual(len(self.result.original_difference_offsets), 66)

    def test_runtime_payload_is_direct_bgr233_8bpp(self):
        self.assertEqual(len(self.result.base), 76_800)
        self.assertEqual(len(self.result.highlight), 76_800)
        self.assertTrue(all(0 <= value <= 255 for value in self.result.base))
        self.assertEqual(
            self.result.preview_base_rgb,
            tuple(build_town_bgr233.decode_bgr233(value) for value in self.result.base),
        )
        self.assertFalse(self.result.metrics["dithering"])
        self.assertFalse(self.result.metrics["runtime_palette_lookup"])

    def test_generation_is_deterministic(self):
        repeated = build_town_bgr233.build(write=False)
        self.assertEqual(self.result.files, repeated.files)
        self.assertEqual(
            hashlib.sha256(self.result.base).digest(),
            hashlib.sha256(repeated.base).digest(),
        )

    def test_overlay_changes_exactly_the_original_66_coordinates(self):
        converted_differences = tuple(
            offset
            for offset, pair in enumerate(zip(self.result.base, self.result.highlight))
            if pair[0] != pair[1]
        )
        self.assertEqual(converted_differences, self.result.original_difference_offsets)
        self.assertEqual(converted_differences, tuple(offset for offset, _ in self.result.overlay))
        self.assertEqual(len(converted_differences), 66)

    def test_materials_are_distinct_and_meet_contrast_floors(self):
        colors = self.result.metrics["material_colors"]
        asphalt = colors["asphalt"]
        for material in ("shadow", "walls", "obstacles", "lane", "vegetation", "blood"):
            self.assertNotEqual(colors[material], asphalt, material)
            self.assertGreaterEqual(
                self.result.metrics["contrast_from_asphalt"][material],
                build_town_bgr233.MIN_CONTRAST[material],
                material,
            )
        self.assertNotEqual(colors["blood"], colors["walls"])

    def test_every_known_collision_obstacle_remains_painted(self):
        self.assertEqual(len(self.result.metrics["collision_obstacles"]), 13)
        for obstacle in self.result.metrics["collision_obstacles"]:
            self.assertGreater(obstacle["visible_pixels"], 0, obstacle)
            self.assertGreater(obstacle["non_asphalt_fraction"], 0.12, obstacle)
            self.assertFalse(obstacle["uniform_black"], obstacle)

    def test_vehicle_and_small_scene_materials_are_preserved(self):
        checks = self.result.metrics["region_checks"]
        for name in ("vehicle_body", "vehicle_windows", "vehicle_blood", "lane", "vegetation", "blood"):
            self.assertGreater(checks[name]["pixels"], 0, name)
            self.assertGreater(checks[name]["distinct_from_asphalt"], 0, name)

    def test_manhole_has_depth_and_visible_highlight(self):
        manhole = self.result.metrics["manhole"]
        self.assertGreaterEqual(manhole["base_levels"], 3)
        self.assertNotEqual(manhole["outer_color"], manhole["inner_color"])
        self.assertNotEqual(manhole["inner_color"], manhole["center_color"])
        self.assertGreater(manhole["highlight_luminance"], manhole["outer_luminance"])

    def test_no_important_region_became_a_large_black_mass(self):
        self.assertLessEqual(self.result.metrics["largest_black_component"], 160)
        for region in self.result.metrics["important_black_fractions"].values():
            self.assertLess(region, 0.45)


class TownBgr233IntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = build_town_bgr233.build(write=False)

    def test_renderer_keeps_word_copy_and_66_pixel_overlay(self):
        render = (build_town_bgr233.ROOT / "src" / "render.s").read_text(encoding="utf-8")
        self.assertIn('.include "../assets/generated/town_bgr233.s"', render)
        self.assertIn("la t0, town_bgr233_base_pixels", render)
        self.assertIn("la t0, town_bgr233_exit_overlay_pixels", render)
        self.assertIn("li t2, 19200", render)
        self.assertIn("li t2, 66", render)

    def test_generated_assembly_has_no_indexed8_palette(self):
        assembly = self.result.files[build_town_bgr233.ASSEMBLY_PATH]
        self.assertIn("Direct BGR233 8bpp", assembly.decode("ascii"))
        self.assertNotIn("palette", assembly.decode("ascii").lower())
        self.assertNotIn("indexed8", assembly.decode("ascii").lower())

    def test_official_runtime_has_no_indexed8_dependencies(self):
        root = build_town_bgr233.ROOT
        render = (root / "src" / "render.s").read_text(encoding="utf-8")
        constants = (root / "src" / "constants.s").read_text(encoding="utf-8")
        game_state = (root / "src" / "game_state.s").read_text(encoding="utf-8")
        official_runtime = "\n".join((render, constants, game_state))

        for forbidden in (
            "Indexed8",
            "FF112C00",
            "PALETTE_BASE",
            'palette.s',
            "town_base_indexed8",
            "town_palette_rgb",
            "load_town_palette",
            "load_default_palette",
            "backgrounds.s",
        ):
            self.assertNotIn(forbidden.lower(), official_runtime.lower())


if __name__ == "__main__":
    unittest.main()
