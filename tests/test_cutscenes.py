import subprocess
import sys
import unittest
from pathlib import Path

from tools.convert_sprites import discover


ROOT = Path(__file__).resolve().parents[1]
CUTSCENE_ASSET = ROOT / "assets" / "generated" / "cutscenes.s"


class CutscenePipelineTests(unittest.TestCase):
    def test_converter_emits_three_exact_fullscreen_payloads(self):
        result = subprocess.run(
            [sys.executable, "tools/convert_cutscenes.py", "--check"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        source = CUTSCENE_ASSET.read_text(encoding="ascii")
        self.assertEqual(source.count("# payload-bytes: 76800"), 3)
        self.assertIn("cutscene_intro_pixels:", source)
        self.assertIn("cutscene_level2_pixels:", source)
        self.assertIn("cutscene_level3_pixels:", source)

    def test_sprite_pipeline_does_not_reprocess_fullscreen_cutscenes(self):
        sprite_sources = discover(ROOT / "assets" / "source")
        self.assertNotIn("_cutscenes", {entry.group for entry in sprite_sources})

    def test_title_and_cutscene_flow_are_wired_into_game_states(self):
        constants = (ROOT / "src" / "constants.s").read_text(encoding="utf-8")
        loop = (ROOT / "src" / "game_loop.s").read_text(encoding="utf-8")
        screens = (ROOT / "src" / "screens.s").read_text(encoding="utf-8")
        levels = (ROOT / "src" / "level_manager.s").read_text(encoding="utf-8")
        render = (ROOT / "src" / "render.s").read_text(encoding="utf-8")

        for state in ("STATE_CUTSCENE_INTRO", "STATE_CUTSCENE_LEVEL2", "STATE_CUTSCENE_LEVEL3"):
            self.assertIn(state, constants)
            self.assertIn(state, loop)
            self.assertIn(state, screens)

        self.assertIn("call update_cutscene", loop)
        self.assertIn("call draw_cutscene_screen", loop)
        self.assertIn("call set_state_cutscene_intro", screens)
        self.assertIn("call set_state_cutscene_level2", levels)
        self.assertIn("call set_state_cutscene_level3", levels)

        self.assertIn('.asciz "Roedores"', render)
        self.assertIn('.asciz "RISC of Infection"', render)
        self.assertIn("li a1, 144", render)
        self.assertIn("li a1, 126", render)
        self.assertNotIn('.asciz "Roedores:"', render)


if __name__ == "__main__":
    unittest.main()
