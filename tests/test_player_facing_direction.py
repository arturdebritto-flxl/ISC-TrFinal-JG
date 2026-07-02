import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def routine(source: str, start: str, end: str) -> str:
    return source.split(f"{start}:\n", 1)[1].split(f"\n{end}:", 1)[0]


class PlayerFacingDirectionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.player = (ROOT / "src" / "player.s").read_text(encoding="utf-8")
        self.bullets = (ROOT / "src" / "bullets.s").read_text(encoding="utf-8")
        self.render = (ROOT / "src" / "render.s").read_text(encoding="utf-8")

    def test_movement_buffer_does_not_write_facing_directly(self) -> None:
        move_buffer = routine(self.player, "store_move_buffer", "apply_move_buffer")
        self.assertNotIn("player_direction", move_buffer)

    def test_facing_routine_prioritizes_shooting_then_movement(self) -> None:
        facing = routine(
            self.player,
            "update_player_facing_direction",
            "is_player_position_blocked",
        )
        shoot_check = facing.index("shoot_hold_timer")
        movement_check = facing.index("player_moved")
        self.assertLess(shoot_check, movement_check)
        self.assertRegex(
            facing,
            r"shoot_hold_timer[\s\S]*?bgtz\s+t1,\s*face_shoot_direction",
        )
        self.assertRegex(
            facing,
            r"player_moved[\s\S]*?beqz\s+t1,\s*end_update_player_facing_direction",
        )
        self.assertIn("player_move_direction", facing)
        self.assertIn("shoot_direction", facing)
        self.assertEqual(1, len(re.findall(r"\bsw t1, 0\(t0\)", facing)))

    def test_facing_is_updated_before_shoot_buffer_is_consumed(self) -> None:
        shoot_buffer = routine(
            self.bullets,
            "apply_shoot_buffer",
            "end_check_shoot_input",
        )
        facing_call = shoot_buffer.index("call update_player_facing_direction")
        timer_decrement = shoot_buffer.index("addi t1, t1, -1")
        self.assertLess(facing_call, timer_decrement)

    def test_player_sprite_selection_reads_player_direction(self) -> None:
        selection = routine(
            self.render,
            "draw_player_square",
            "draw_selected_player_sprite",
        )
        self.assertRegex(selection, r"player_direction\s+lw t1, 0\(t0\)")
        expected_routes = {
            "DIR_UP": "select_player_up_sprite",
            "DIR_LEFT": "select_player_left_sprite",
            "DIR_RIGHT": "select_player_right_sprite",
        }
        for direction, label in expected_routes.items():
            with self.subTest(direction=direction):
                self.assertRegex(
                    selection,
                    rf"li t2, {direction}\s+beq t1, t2, {label}",
                )
        self.assertIn("select_player_down_sprite:", selection)

    def test_horizontal_projectile_deltas_keep_their_direction(self) -> None:
        delta_selection = routine(self.bullets, "set_cardinal_delta", "delta_up")
        self.assertRegex(
            delta_selection,
            r"DIR_LEFT\s+beq a0, t1, delta_left[\s\S]*?"
            r"DIR_RIGHT\s+beq a0, t1, delta_right",
        )
        left_delta = routine(self.bullets, "delta_left", "delta_right")
        right_delta = routine(self.bullets, "delta_right", "set_spread_delta_left")
        self.assertIn("sub a2, zero, t5", left_delta)
        self.assertIn("mv a2, t5", right_delta)

    def test_horizontal_sprite_labels_use_the_correct_source_pngs(self) -> None:
        manifest = json.loads(
            (ROOT / "assets" / "generated" / "manifest.json").read_text(
                encoding="utf-8"
            )
        )
        sources = {
            record["symbol"]: record["source"]
            for record in manifest["runtime_sprites"]
        }
        self.assertEqual("sprite_16.png", sources["sprite_player_left_0"])
        self.assertEqual("sprite_17.png", sources["sprite_player_left_1"])
        self.assertEqual("sprite_08.png", sources["sprite_player_right_0"])
        self.assertEqual("sprite_09.png", sources["sprite_player_right_1"])
        self.assertEqual("sprite_04.png", sources["sprite_player_up_0"])
        self.assertEqual("sprite_05.png", sources["sprite_player_up_1"])
        self.assertEqual("sprite_00.png", sources["sprite_player_down_0"])
        self.assertEqual("sprite_01.png", sources["sprite_player_down_1"])


if __name__ == "__main__":
    unittest.main()
