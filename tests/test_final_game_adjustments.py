import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def routine(source: str, start: str, end: str) -> str:
    return source.split(f"{start}:\n", 1)[1].split(f"\n{end}:", 1)[0]


class FinalGameAdjustmentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.inventory_data = (ROOT / "data/inventory_data.s").read_text(
            encoding="utf-8"
        )
        cls.inventory = (ROOT / "src/inventory.s").read_text(encoding="utf-8")
        cls.powerups = (ROOT / "src/powerups.s").read_text(encoding="utf-8")
        cls.level_manager = (ROOT / "src/level_manager.s").read_text(
            encoding="utf-8"
        )
        cls.game_loop = (ROOT / "src/game_loop.s").read_text(encoding="utf-8")
        cls.render = (ROOT / "src/render.s").read_text(encoding="utf-8")
        cls.hud = (ROOT / "src/hud.s").read_text(encoding="utf-8")

    def test_uzi_is_owned_separately_and_selected_only_with_key_3(self) -> None:
        self.assertRegex(self.inventory_data, r"(?m)^boss_weapon_owned:\s+\.word 0$")
        init = routine(self.inventory, "init_inventory", "update_inventory")
        self.assertRegex(init, r"boss_weapon_owned[\s\S]*?sw zero, 0\(t0\)")

        select = routine(
            self.inventory, "handle_weapon_select_input", "handle_reload_input"
        )
        self.assertRegex(select, r"li t2, '1'[\s\S]*?select_normal_weapon")
        self.assertRegex(select, r"li t2, '2'[\s\S]*?shotgun_owned")
        self.assertRegex(
            select,
            r"li t2, '3'[\s\S]*?boss_weapon_owned[\s\S]*?"
            r"beqz t1, end_handle_weapon_select_input[\s\S]*?WEAPON_BOSS",
        )

    def test_collecting_uzi_unlocks_and_adds_ammo_without_equipping(self) -> None:
        collect = routine(
            self.powerups, "collect_boss_weapon", "finish_collect_boss_weapon"
        )
        self.assertIn("boss_weapon_owned", collect)
        self.assertIn("boss_ammo_count", collect)
        self.assertIn("BOSS_AMMO_GAIN", collect)
        self.assertNotIn("weapon_type", collect)
        self.assertNotIn("WEAPON_BOSS", collect)

    def test_cheat_accepts_c_and_uses_safe_level_transitions(self) -> None:
        cheat = routine(
            self.level_manager,
            "handle_next_level_cheat",
            "reset_transient_level_state",
        )
        self.assertIn("li t2, 'c'", cheat)
        self.assertIn("li t2, 'C'", cheat)
        self.assertIn("STATE_LEVEL1", cheat)
        self.assertIn("STATE_LEVEL2", cheat)
        self.assertIn("STATE_BOSS", cheat)
        self.assertIn("LEVEL_TOWN", cheat)
        self.assertIn("call set_state_level2", cheat)
        self.assertIn("LEVEL_SEWER", cheat)
        self.assertIn("call set_state_level3", cheat)
        self.assertIn("LEVEL_LABORATORY", cheat)
        self.assertIn("call set_state_victory", cheat)

        reset = routine(
            self.level_manager, "reset_transient_level_state", "advance_wave"
        )
        for call in (
            "call init_enemies",
            "call init_bullets",
            "call init_enemy_bullets",
            "call init_powerups",
            "call init_boss",
        ):
            self.assertIn(call, reset)

        playing = routine(self.game_loop, "loop_playing_level", "loop_game_over")
        self.assertRegex(
            playing,
            r"call read_input\s+call handle_next_level_cheat\s+"
            r"bnez a0, finish_playing_frame",
        )

    def test_final_title_uses_two_line_ascii_fallback(self) -> None:
        self.assertIn('label_title_line1: .asciz "Roedores"', self.render)
        self.assertIn('label_title_line2: .asciz "RISC of Infection"', self.render)
        self.assertNotIn("label_echo", self.render)
        menu = routine(self.render, "draw_menu_screen", "draw_game_over_screen")
        self.assertIn("label_title_line1", menu)
        self.assertIn("label_title_line2", menu)
        self.assertLess(menu.index("label_title_line1"), menu.index("label_title_line2"))
        self.assertRegex(menu, r"label_title_line1[\s\S]*?li a1, 144")
        self.assertRegex(menu, r"label_title_line2[\s\S]*?li a1, 126")

        draw_char = routine(self.render, "draw_small_char", "draw_small_text")
        self.assertRegex(draw_char, r"li t0, 'a'[\s\S]*?addi a0, a0, -32")

    def test_existing_uzi_hud_icon_route_is_preserved(self) -> None:
        self.assertRegex(
            self.inventory, r"WEAPON_BOSS[\s\S]*?sprite_weapon_boss_icon"
        )


if __name__ == "__main__":
    unittest.main()
