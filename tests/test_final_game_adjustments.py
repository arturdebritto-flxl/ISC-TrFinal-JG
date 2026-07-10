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
        cls.screens = (ROOT / "src/screens.s").read_text(encoding="utf-8")
        cls.game_loop = (ROOT / "src/game_loop.s").read_text(encoding="utf-8")
        cls.render = (ROOT / "src/render.s").read_text(encoding="utf-8")
        cls.hud = (ROOT / "src/hud.s").read_text(encoding="utf-8")
        cls.readme = (ROOT / "README.md").read_text(encoding="utf-8")

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

    def test_cheat_accepts_c_and_uses_cutscene_transitions(self) -> None:
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
        self.assertIn("call set_state_cutscene_level2", cheat)
        self.assertNotIn("call set_state_level2", cheat)
        self.assertIn("LEVEL_SEWER", cheat)
        self.assertIn("call set_state_cutscene_level3", cheat)
        self.assertNotIn("call set_state_level3", cheat)
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
            r"bnez a0, render_cheat_transition_frame",
        )
        self.assertIn("render_cheat_transition_frame:", playing)
        self.assertIn("call draw_cutscene_screen", playing)
        self.assertIn("call draw_victory_screen", playing)

    def test_restart_keys_are_t_only_outside_gameplay(self) -> None:
        game_over = routine(self.screens, "update_game_over", "update_victory")
        victory = routine(self.screens, "update_victory", "reset_game_run")

        for screen in (game_over, victory):
            self.assertIn("li t2, 't'", screen)
            self.assertIn("li t2, 'T'", screen)
            self.assertNotIn("li t2, 'r'", screen)
            self.assertNotIn("li t2, 'R'", screen)

        reload_input = routine(
            self.inventory, "handle_reload_input", "handle_inventory_input"
        )
        self.assertIn("li t2, 'r'", reload_input)
        self.assertIn("li t2, 'R'", reload_input)
        self.assertNotIn("li t2, 't'", reload_input)
        self.assertNotIn("li t2, 'T'", reload_input)

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

    def test_menu_and_game_over_use_adapted_screen_art(self) -> None:
        self.assertIn('../assets/generated/screen_art.s"', self.render)
        self.assertIn("menu_base_runs", self.render)
        self.assertIn("game_over_art_runs", self.render)
        self.assertIn("draw_screen_runs", self.render)

        menu = routine(self.render, "draw_menu_screen", "draw_cutscene_screen")
        self.assertIn("la a0, menu_base_runs", menu)
        self.assertIn("call draw_screen_runs", menu)
        self.assertIn("label_title_line1", menu)
        self.assertIn("label_title_line2", menu)

        game_over = routine(
            self.render, "draw_game_over_screen", "draw_victory_screen"
        )
        self.assertIn("la a0, game_over_art_runs", game_over)
        self.assertIn("call draw_screen_runs", game_over)
        self.assertRegex(game_over, r"la t0, score[\s\S]*?call draw_small_number")

    def test_readme_is_player_and_code_documentation(self) -> None:
        lower = self.readme.lower()
        self.assertIn("## como rodar", lower)
        self.assertIn("## controles", lower)
        self.assertIn("## arquitetura do codigo", lower)
        self.assertNotIn("checklist", lower)
        self.assertNotIn("sprite", lower)
        self.assertNotIn("para ia", lower)
        self.assertNotIn("agente", lower)
        self.assertNotIn("instrucoes para", lower)


if __name__ == "__main__":
    unittest.main()
