import re
import unittest

from tools import build_text_cutscenes_bgr233


class FinalCutsceneVictoryFlowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = build_text_cutscenes_bgr233.ROOT
        cls.collision = (root / "src" / "collision.s").read_text(encoding="utf-8")
        cls.screens = (root / "src" / "screens.s").read_text(encoding="utf-8")
        cls.render = (root / "src" / "render.s").read_text(encoding="utf-8")
        cls.game_loop = (root / "src" / "game_loop.s").read_text(encoding="utf-8")
        cls.main = (root / "main.s").read_text(encoding="utf-8")

    def test_boss_defeat_starts_detonator_then_explosion(self):
        boss_defeated = self.collision[
            self.collision.index("boss_defeated:") : self.collision.index("next_bullet_boss:")
        ]
        self.assertEqual(boss_defeated.count("call set_state_cutscene_detonator"), 1)

        detonator = self.screens[
            self.screens.index("update_post_boss_detonator:") : self.screens.index(
                "update_post_boss_explosion:"
            )
        ]
        self.assertEqual(detonator.count("call set_state_cutscene_explosion"), 1)
        self.assertNotIn("call show_text_cutscene", detonator)

    def test_explosion_is_followed_once_by_final_text_then_victory(self):
        explosion_loop = self.game_loop[
            self.game_loop.index("loop_post_boss_explosion:") : self.game_loop.index(
                "loop_playing_level:"
            )
        ]
        self.assertIn("call update_post_boss_explosion", explosion_loop)
        self.assertNotIn("call draw_cutscene_screen", explosion_loop)

        explosion = self.screens[
            self.screens.index("update_post_boss_explosion:") : self.screens.index(
                "game_over_screen:"
            )
        ]
        self.assertEqual(explosion.count("call discard_pending_keyboard_events"), 1)
        self.assertEqual(explosion.count("call begin_frame"), 1)
        self.assertEqual(explosion.count("call draw_cutscene_screen"), 1)
        self.assertEqual(explosion.count("call end_frame"), 1)
        self.assertEqual(explosion.count("call wait_post_boss_explosion_key"), 1)
        self.assertEqual(explosion.count("jal show_text_cutscene_3"), 1)
        self.assertEqual(explosion.count("call set_state_victory"), 1)
        self.assertLess(
            explosion.index("call discard_pending_keyboard_events"),
            explosion.index("call draw_cutscene_screen"),
        )
        self.assertLess(
            explosion.index("call draw_cutscene_screen"),
            explosion.index("call wait_post_boss_explosion_key"),
        )
        self.assertLess(
            explosion.index("call wait_post_boss_explosion_key"),
            explosion.index("jal show_text_cutscene_3"),
        )
        self.assertLess(
            explosion.index("jal show_text_cutscene_3"),
            explosion.index("call set_state_victory"),
        )

        final_text_select = self.render[
            self.render.index("la t0, cutscene_text_visible") : self.render.index(
                "select_image_cutscene:"
            )
        ]
        self.assertIn("STATE_CUTSCENE_EXPLOSION", final_text_select)
        self.assertNotIn("STATE_CUTSCENE_DETONATOR", final_text_select)
        self.assertEqual(self.render.count("la t0, text_cutscene_3_pixels"), 1)

    def test_explosion_wait_accepts_only_new_enter_or_space_event(self):
        self.assertIn("wait_post_boss_explosion_key:", self.screens)
        wait = self.screens[
            self.screens.index("wait_post_boss_explosion_key:") : self.screens.index(
                "game_over_screen:"
            )
        ]
        self.assertLess(wait.index("KDMMIO_Ctrl"), wait.index("KDMMIO_Data"))
        self.assertIn("andi", wait)
        self.assertIn("li t2, 13", wait)
        self.assertIn("li t2, 10", wait)
        self.assertIn("li t2, 32", wait)
        self.assertIn("bne a0, t2, wait_post_boss_explosion_key", wait)

    def test_victory_uses_real_score_and_returns_menu_or_leave(self):
        loop_victory = self.game_loop[
            self.game_loop.index("loop_victory:") : self.game_loop.index("leave_game_loop:")
        ]
        self.assertRegex(loop_victory, r"la t0, score\s+lw a0, 0\(t0\)\s+call victory_screen")
        self.assertIn("beqz a0, leave_game_loop", loop_victory)
        self.assertLess(loop_victory.index("call reset_game_run"), loop_victory.index("call set_state_menu"))

        victory = self.screens[
            self.screens.index("victory_screen:") : self.screens.index("reset_game_run:")
        ]
        self.assertRegex(victory, r"la t0, victory_score\s+sw a0, 0\(t0\)")
        self.assertRegex(victory, re.compile(r"victory_confirm:.*?li a0, 1", re.DOTALL))
        self.assertRegex(victory, r"victory_leave:\s+li a0, 0")
        self.assertIn("call discard_pending_keyboard_events", victory)
        for key_test in ("li t0, 'w'", "li t0, 'W'", "li t0, 's'", "li t0, 'S'", "li t0, 32", "li t0, 10", "li t0, 13", "li t0, 'q'", "li t0, 'Q'"):
            self.assertIn(key_test, victory)
        self.assertIn("sw ra, 0(sp)", victory)
        self.assertIn("lw ra, 0(sp)", victory)
        self.assertNotIn("li a7, 10", victory)
        self.assertNotIn("call game_loop", victory)

    def test_final_flow_has_no_demo_or_duplicate_labels(self):
        combined = "\n".join((self.screens, self.render, self.game_loop, self.main))
        self.assertNotIn("victory_demo.s", combined)
        labels = re.findall(r"^([A-Za-z_][A-Za-z0-9_]*):", combined, re.MULTILINE)
        duplicates = {label for label in labels if labels.count(label) > 1}
        self.assertEqual(duplicates, set())


if __name__ == "__main__":
    unittest.main()
