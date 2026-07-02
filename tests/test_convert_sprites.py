import hashlib
import io
import unittest
from pathlib import Path

from PIL import Image

from tools.convert_sprites import (
    FORMULA,
    RUNTIME_SPRITES,
    discover,
    emit,
    rgba_to_rars8,
    replace_runtime_block,
    transform,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "source"
GENERATED = ROOT / "assets" / "generated"


class SpriteConverterTests(unittest.TestCase):
    def test_calibration_colors_use_bgr233(self):
        self.assertEqual(0x07, rgba_to_rars8((255, 0, 0, 255)))
        self.assertEqual(0x38, rgba_to_rars8((0, 255, 0, 255)))
        self.assertEqual(0xC0, rgba_to_rars8((0, 0, 255, 255)))
        self.assertEqual(0xFF, rgba_to_rars8((255, 255, 255, 255)))

    def test_transparency_and_opaque_black_are_distinct(self):
        self.assertEqual(0, rgba_to_rars8((0, 0, 0, 0)))
        self.assertEqual(1, rgba_to_rars8((0, 0, 0, 255)))
        self.assertNotEqual(0, rgba_to_rars8((0, 0, 0, 1)))

    def test_crop_nearest_neighbor_and_padding(self):
        image = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
        image.putpixel((1, 1), (255, 0, 0, 255))
        image.putpixel((2, 1), (0, 0, 255, 255))
        stream = io.BytesIO()
        image.save(stream, format="PNG")

        width, height, payload, metadata = transform(stream.getvalue(), 4)

        self.assertEqual((4, 4), (width, height))
        self.assertEqual([1, 1, 3, 2], metadata["crop"])
        self.assertEqual([2, 1], metadata["content_size"])
        self.assertEqual([1, 1], metadata["offset"])
        self.assertEqual([0x07, 0xC0], list(payload[5:7]))
        self.assertEqual(14, payload.count(0))

    def test_transform_draws_every_nonzero_alpha(self):
        image = Image.new("RGBA", (1, 1), (255, 0, 0, 1))
        stream = io.BytesIO()
        image.save(stream, format="PNG")

        _, _, payload, _ = transform(stream.getvalue(), 1)

        self.assertEqual(bytes([0x07]), payload)

    def test_all_real_assets_and_representatives_are_emitted_deterministically(self):
        first = emit(SOURCE, GENERATED)
        first_files = {
            name: (GENERATED / name).read_bytes()
            for name in ("sprites.s", "runtime_sprites.s", "manifest.json")
        }
        second = emit(SOURCE, GENERATED)
        second_files = {
            name: (GENERATED / name).read_bytes()
            for name in first_files
        }
        self.assertEqual(first, second)
        self.assertEqual(first_files, second_files)

        self.assertEqual(53, len(first["sprites"]))
        self.assertEqual(25, len(first["runtime_sprites"]))
        self.assertEqual(set(RUNTIME_SPRITES), {
            record["symbol"] for record in first["runtime_sprites"]
        })
        self.assertEqual(FORMULA, first["formula"])
        records = {
            (record["group"], record["source"]): record
            for record in first["sprites"]
        }
        entries = {
            (entry.group, entry.relative.as_posix()): entry
            for entry in discover(SOURCE)
        }
        representatives = {
            "player": ("_protagonista", "sprite_00.png"),
            "enemy_inferred": ("_sprites_1", "sprites/image-1.png.png"),
            "weapon": ("_armas", "sprite_0.png"),
            "projectile_inferred": ("_sprites_1", "sprites/image-1.png (1).png"),
            "medkit": ("_med_kit", "Med-Kit.png"),
        }
        for name, key in representatives.items():
            with self.subTest(name=name):
                record = records[key]
                self.assertRegex(record["source_sha256"], r"^[0-9a-f]{64}$")
                self.assertRegex(record["payload_sha256"], r"^[0-9a-f]{64}$")
                self.assertEqual([16, 16], record["output_size"])
                payload = transform(entries[key].data, 16)[2]
                self.assertEqual(
                    hashlib.sha256(payload).hexdigest(),
                    record["payload_sha256"],
                )
                self.assertTrue(any(payload))

        payload_hashes = [record["payload_sha256"] for record in first["sprites"]]
        self.assertEqual(
            payload_hashes,
            [record["payload_sha256"] for record in second["sprites"]],
        )
        self.assertTrue(all(len(bytes.fromhex(value)) == hashlib.sha256().digest_size for value in payload_hashes))

    def test_medkit_reference_contains_red_and_white(self):
        medkit = next(
            entry
            for entry in discover(SOURCE)
            if entry.relative.name.casefold() == "med-kit.png".casefold()
        )
        payload = transform(medkit.data, 16)[2]

        self.assertIn(0xFF, payload)
        self.assertTrue(any(value & 0x07 and value & 0xF8 == 0 for value in payload))

    def test_generated_runtime_block_is_the_one_consumed_by_render(self):
        generated = (GENERATED / "runtime_sprites.s").read_text(encoding="ascii").rstrip()
        updated = replace_runtime_block(
            "before\n# SPRITE_DATA_BEGIN\nstale\n# SPRITE_DATA_END\nafter\n",
            generated,
        )
        self.assertNotIn("stale", updated)
        for symbol in RUNTIME_SPRITES:
            self.assertEqual(1, updated.count(f"{symbol}:"))

    def test_checked_in_runtime_bytes_match_fresh_generation(self):
        emit(SOURCE, GENERATED)
        render = (ROOT / "src" / "render.s").read_text(encoding="utf-8")
        block = render.split("# SPRITE_DATA_BEGIN\n", 1)[1].split(
            "\n# SPRITE_DATA_END", 1
        )[0]
        self.assertEqual(
            (GENERATED / "runtime_sprites.s").read_text(encoding="ascii").rstrip(),
            block.rstrip(),
        )


if __name__ == "__main__":
    unittest.main()
