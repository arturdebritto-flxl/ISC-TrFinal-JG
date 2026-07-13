import re
import unittest
from collections import deque

from tools import build_text_cutscenes_bgr233


VALID_ADVANCE_KEYS = {10, 13, 32}


class EventMmioHarness:
    """Minimal event model matching the RARS receiver READY/data contract."""

    def __init__(self, pending=(), after_show=()):
        self.events = deque(pending)
        self.after_show = tuple(after_show)
        self.read_count = 0
        self.transition_count = 0

    @property
    def ready(self):
        return bool(self.events)

    def read_data(self):
        if not self.ready:
            raise AssertionError("receiver data read while READY=0")
        self.read_count += 1
        return self.events.popleft()

    def show_text(self):
        self.events.extend(self.after_show)

    def run_text_cutscene(self):
        while self.ready:
            self.read_data()
        self.show_text()
        while True:
            if not self.ready:
                raise AssertionError("test did not provide a new keyboard event")
            key = self.read_data()
            if key in VALID_ADVANCE_KEYS:
                self.transition_count += 1
                return key


class TextCutsceneEventTests(unittest.TestCase):
    def test_discards_residual_event_then_accepts_enter_cr(self):
        mmio = EventMmioHarness(pending=(13,), after_show=(13,))
        self.assertEqual(mmio.run_text_cutscene(), 13)
        self.assertEqual(mmio.read_count, 2)
        self.assertEqual(mmio.transition_count, 1)

    def test_accepts_enter_lf_and_space(self):
        for key in (10, 32):
            with self.subTest(key=key):
                mmio = EventMmioHarness(after_show=(key,))
                self.assertEqual(mmio.run_text_cutscene(), key)
                self.assertEqual(mmio.transition_count, 1)

    def test_invalid_key_is_consumed_before_enter(self):
        mmio = EventMmioHarness(after_show=(ord("x"), 13))
        self.assertEqual(mmio.run_text_cutscene(), 13)
        self.assertEqual(mmio.read_count, 2)
        self.assertEqual(mmio.transition_count, 1)


class TextCutsceneAssemblyContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.screens = (build_text_cutscenes_bgr233.ROOT / "src" / "screens.s").read_text(
            encoding="utf-8"
        )
        cls.constants = (build_text_cutscenes_bgr233.ROOT / "src" / "constants.s").read_text(
            encoding="utf-8"
        )

    def test_text_wait_uses_ready_then_consumes_data_once(self):
        routine = self.screens[
            self.screens.index("show_text_cutscene:") : self.screens.index("update_cutscene:")
        ]
        self.assertIn("KDMMIO_Ctrl", routine)
        self.assertIn("andi", routine)
        self.assertIn("KDMMIO_Data", routine)
        self.assertLess(routine.index("KDMMIO_Ctrl"), routine.index("KDMMIO_Data"))
        self.assertIn("li t2, 10", routine)
        self.assertIn("li t2, 13", routine)
        self.assertIn("li t2, 32", routine)

    def test_text_wait_preserves_ra_and_balances_stack(self):
        routine = self.screens[
            self.screens.index("show_text_cutscene:") : self.screens.index("update_cutscene:")
        ]
        self.assertIn("addi sp, sp, -4", routine)
        self.assertIn("sw ra, 0(sp)", routine)
        self.assertIn("lw ra, 0(sp)", routine)
        self.assertIn("addi sp, sp, 4", routine)
        self.assertTrue(routine.rstrip().endswith("ret"))

    def test_returns_to_each_original_destination(self):
        for state, advance_label, setter in (
            ("STATE_CUTSCENE_INTRO", "advance_cutscene_to_level1", "set_state_level1"),
            ("STATE_CUTSCENE_LEVEL2", "advance_cutscene_to_level2", "set_state_level2"),
            ("STATE_CUTSCENE_LEVEL3", "advance_cutscene_to_level3", "set_state_level3"),
        ):
            with self.subTest(state=state):
                self.assertRegex(
                    self.screens,
                    re.compile(
                        rf"li t2, {state}\s+beq t1, t2, {advance_label}",
                        re.MULTILINE,
                    ),
                )
                self.assertRegex(
                    self.screens,
                    re.compile(rf"{advance_label}:\s+call {setter}", re.MULTILINE),
                )
        self.assertRegex(
            self.screens,
            re.compile(
                r"show_current_text_cutscene:\s+call show_text_cutscene\s+j advance_cutscene",
                re.MULTILINE,
            ),
        )
        detonator = self.screens[
            self.screens.index("update_post_boss_detonator:") : self.screens.index(
                "update_post_boss_explosion:"
            )
        ]
        self.assertIn("j advance_to_post_boss_explosion", detonator)
        self.assertNotIn("call show_text_cutscene", detonator)

    def test_event_flow_has_no_release_timer(self):
        self.assertNotIn("CUTSCENE_RELEASE_", self.screens)
        self.assertNotIn("CUTSCENE_RELEASE_", self.constants)


if __name__ == "__main__":
    unittest.main()
