"""Deterministic PNG/ZIP to RARS Custom 8-bpp sprite converter."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import re
import zipfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


TRANSPARENT = 0
MAX_DIMENSION = 64
FORMAT = "RARS16 Custom1 BGR233 direct 8bpp (BBGGGRRR)"
FORMULA = (
    "alpha == 0 ? 0 : max(1, ((blue >> 6) << 6) | "
    "((green >> 5) << 3) | (red >> 5))"
)

FINAL_GROUP = "_final_sprites"
NON_SPRITE_SOURCE_DIRS = {"cutscenes"}


def build_runtime_sprites() -> dict[str, tuple[str, str, int]]:
    """Return baseline runtime art plus the explicitly approved final sprites."""
    sprites: dict[str, tuple[str, str, int]] = {
        "sprite_player_down_0": ("_protagonista", "sprite_00.png", 16),
        "sprite_player_down_1": ("_protagonista", "sprite_01.png", 16),
        "sprite_player_up_0": ("_protagonista", "sprite_04.png", 16),
        "sprite_player_up_1": ("_protagonista", "sprite_05.png", 16),
        "sprite_player_right_0": ("_protagonista", "sprite_08.png", 16),
        "sprite_player_right_1": ("_protagonista", "sprite_09.png", 16),
        "sprite_player_left_0": ("_protagonista", "sprite_16.png", 16),
        "sprite_player_left_1": ("_protagonista", "sprite_17.png", 16),
        "sprite_enemy_common_0": ("_sprites_1", "sprites/image-1.png.png", 16),
        "sprite_enemy_common_1": ("_sprites_1", "sprites/image-2.png.png", 16),
        "sprite_enemy_echo_0": ("_sprites_1", "sprites/image-12.png.png", 16),
        "sprite_enemy_echo_1": ("_sprites_1", "sprites/image-13.png.png", 16),
        "sprite_enemy_mutant_0": ("_sprites_1", "sprites/image-10.png.png", 16),
        "sprite_enemy_mutant_1": ("_sprites_1", "sprites/image-11.png.png", 16),
        "sprite_enemy_spitter_0": ("_sprites_1", "sprites/image-18.png.png", 16),
        "sprite_enemy_spitter_1": ("_sprites_1", "sprites/image-19.png.png", 16),
        "sprite_boss_0": ("_sprites_1", "sprites/New Piskel-1.png.png", 32),
        "sprite_boss_1": ("_sprites_1", "sprites/New Piskel-2.png.png", 32),
        "sprite_powerup_heal": ("_med_kit", "Med-Kit.png", 16),
        "sprite_powerup_ammo": ("_armas", "sprite_1.png", 16),
        "sprite_powerup_boss_weapon": ("_armas", "sprite_0.png", 16),
        "sprite_powerup_boss_ammo": ("_armas", "sprite_5.png", 16),
        "sprite_weapon_normal_icon": ("_armas", "sprite_0.png", 16),
        "sprite_weapon_shotgun_icon": ("_armas", "sprite_4.png", 16),
        "sprite_weapon_boss_icon": ("_armas", "sprite_2.png", 16),
    }

    static = {
        "sprite_ammo_pistol_pickup": ("05_MUNICAO_E_MEDKIT_8x8/ammo_pistol_pickup_8x8.png", 8),
        "sprite_ammo_shotgun_pickup": ("05_MUNICAO_E_MEDKIT_8x8/ammo_shotgun_pickup_8x8.png", 8),
        "sprite_ammo_uzi_pickup": ("05_MUNICAO_E_MEDKIT_8x8/ammo_uzi_pickup_8x8.png", 8),
        "sprite_medkit_pickup": ("05_MUNICAO_E_MEDKIT_8x8/medkit_pickup_8x8.png", 8),
        "sprite_projectile_pistol": ("06_PROJETEIS/projectile_pistol_3x3.png", 3),
        "sprite_projectile_shotgun": ("06_PROJETEIS/projectile_shotgun_3x3.png", 3),
        "sprite_projectile_uzi": ("06_PROJETEIS/projectile_uzi_3x3.png", 3),
        "sprite_projectile_spitter": ("06_PROJETEIS/projectile_spitter_4x4.png", 4),
        "sprite_projectile_boss": ("06_PROJETEIS/projectile_boss_green_6x6.png", 6),
    }
    for symbol, (source, size) in static.items():
        sprites[symbol] = (FINAL_GROUP, source, size)
    return sprites


RUNTIME_SPRITES = build_runtime_sprites()


def build_runtime_tables() -> dict[str, list[str]]:
    return {}


RUNTIME_TABLES = build_runtime_tables()


@dataclass(frozen=True)
class SourceEntry:
    group: str
    relative: Path
    data: bytes


def symbol_for(group: str, relative: Path) -> str:
    raw = f"asset_{group}_{relative.with_suffix('').as_posix()}".lower()
    symbol = re.sub(r"[^a-z0-9_]+", "_", raw).strip("_")
    if not symbol or symbol[0].isdigit():
        symbol = "asset_" + symbol
    return symbol


def rgba_to_rars8(pixel: tuple[int, int, int, int]) -> int:
    """Encode RGBA as the BBGGGRRR byte consumed by the custom display."""
    red, green, blue, alpha = pixel
    if alpha == 0:
        return TRANSPARENT
    value = ((blue >> 6) << 6) | ((green >> 5) << 3) | (red >> 5)
    return value or 1  # Zero is reserved for transparency; preserve opaque black.


def transform(data: bytes, target: int) -> tuple[int, int, bytes, dict]:
    with Image.open(io.BytesIO(data)) as source:
        image = source.convert("RGBA")

    alpha = image.getchannel("A")
    crop = alpha.getbbox()
    if crop is None:
        raise ValueError("fully transparent image")

    cropped = image.crop(crop)
    scale = min(target / cropped.width, target / cropped.height, 1.0)
    width = max(1, round(cropped.width * scale))
    height = max(1, round(cropped.height * scale))
    if width > MAX_DIMENSION or height > MAX_DIMENSION:
        raise ValueError(f"sprite exceeds {MAX_DIMENSION}px")

    resized = cropped.resize((width, height), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (target, target), (0, 0, 0, 0))
    offset = ((target - width) // 2, (target - height) // 2)
    canvas.paste(resized, offset)
    pixels = (
        canvas.get_flattened_data()
        if hasattr(canvas, "get_flattened_data")
        else canvas.getdata()
    )
    payload = bytes(rgba_to_rars8(pixel) for pixel in pixels)
    metadata = {
        "source_size": list(image.size),
        "crop": list(crop),
        "content_size": [width, height],
        "output_size": [target, target],
        "offset": list(offset),
        "resampling": "nearest",
        "transparent_value": TRANSPARENT,
        "payload_sha256": hashlib.sha256(payload).hexdigest(),
    }
    return target, target, payload, metadata


def transform_exact(data: bytes, size: int) -> tuple[int, int, bytes, dict]:
    """Convert a final-size RGBA sprite without cropping or repositioning it."""
    with Image.open(io.BytesIO(data)) as source:
        image = source.convert("RGBA")
    if image.size != (size, size):
        raise ValueError(f"expected {size}x{size} sprite, got {image.width}x{image.height}")
    pixels = (
        image.get_flattened_data()
        if hasattr(image, "get_flattened_data")
        else image.getdata()
    )
    payload = bytes(rgba_to_rars8(pixel) for pixel in pixels)
    metadata = {
        "source_size": [size, size],
        "crop": [0, 0, size, size],
        "content_size": [size, size],
        "output_size": [size, size],
        "offset": [0, 0],
        "resampling": "none",
        "transparent_value": TRANSPARENT,
        "payload_sha256": hashlib.sha256(payload).hexdigest(),
    }
    return size, size, payload, metadata


def discover(source_dir: Path) -> list[SourceEntry]:
    entries: list[SourceEntry] = []
    for source in sorted(source_dir.iterdir(), key=lambda path: path.name.casefold()):
        if source.is_dir() and source.name.casefold() in NON_SPRITE_SOURCE_DIRS:
            continue
        group = symbol_for("", Path(source.stem)).removeprefix("asset_")
        if source.is_dir():
            pngs = sorted(
                source.rglob("*.png"),
                key=lambda path: path.relative_to(source).as_posix().casefold(),
            )
            entries.extend(
                SourceEntry(group, path.relative_to(source), path.read_bytes())
                for path in pngs
            )
        elif source.suffix.lower() == ".zip":
            with zipfile.ZipFile(source) as archive:
                members = archive.infolist()
                for member in members:
                    relative = Path(member.filename)
                    if relative.is_absolute() or ".." in relative.parts:
                        raise ValueError(f"unsafe ZIP member: {member.filename}")
                pngs = sorted(
                    (m for m in members if m.filename.lower().endswith(".png")),
                    key=lambda member: member.filename.casefold(),
                )
                entries.extend(
                    SourceEntry(group, Path(member.filename), archive.read(member))
                    for member in pngs
                )
        elif source.suffix.lower() == ".png":
            entries.append(SourceEntry(group, Path(source.name), source.read_bytes()))
    return entries


def emit(source_dir: Path, output_dir: Path, target: int = 16) -> dict:
    if not 1 <= target <= MAX_DIMENSION:
        raise ValueError(f"target must be between 1 and {MAX_DIMENSION}")

    output_dir.mkdir(parents=True, exist_ok=True)
    records: list[dict] = []
    symbols: set[str] = set()
    entries = discover(source_dir)
    asm = [
        "# Generated by tools/convert_sprites.py; do not edit.\n",
        f"# Format: {FORMAT}\n",
        f"# Formula: {FORMULA}\n",
        ".data\n",
    ]

    for entry in entries:
        # Final assets are emitted at their manifest dimensions below.  Keep the
        # legacy all-assets catalog stable instead of adding resized duplicates.
        if entry.group == FINAL_GROUP:
            continue
        symbol = symbol_for(entry.group, entry.relative)
        if symbol in symbols:
            raise ValueError(f"duplicate Assembly symbol: {symbol}")
        symbols.add(symbol)

        width, height, payload, metadata = transform(entry.data, target)
        asm.extend(
            [
                f"\n# {entry.group}/{entry.relative.as_posix()}\n",
                f".align 2\n{symbol}:\n",
            ]
        )
        for offset in range(0, len(payload), 16):
            values = ", ".join(f"0x{value:02X}" for value in payload[offset : offset + 16])
            asm.append(f"    .byte {values}\n")
        asm.extend(
            [
                f".eqv {symbol.upper()}_WIDTH {width}\n",
                f".eqv {symbol.upper()}_HEIGHT {height}\n",
            ]
        )
        records.append(
            {
                "symbol": symbol,
                "group": entry.group,
                "source": entry.relative.as_posix(),
                "source_sha256": hashlib.sha256(entry.data).hexdigest(),
                **metadata,
            }
        )

    entries_by_key = {
        (entry.group, entry.relative.as_posix()): entry
        for entry in entries
    }
    runtime_asm = [
        "# Generated by tools/convert_sprites.py; do not edit.\n",
        f"# Format: {FORMAT}\n",
        f"# Formula: {FORMULA}\n",
    ]
    runtime_records = []
    for symbol, (group, source, size) in RUNTIME_SPRITES.items():
        entry = entries_by_key[(group, source)]
        transform_runtime = transform_exact if group == FINAL_GROUP else transform
        _, _, payload, metadata = transform_runtime(entry.data, size)
        runtime_asm.append(f"\n# {group}/{source}\n{symbol}:\n")
        for offset in range(0, len(payload), 16):
            values = ", ".join(
                f"0x{value:02X}" for value in payload[offset : offset + 16]
            )
            runtime_asm.append(f"    .byte {values}\n")
        runtime_records.append(
            {
                "symbol": symbol,
                "group": group,
                "source": source,
                "source_sha256": hashlib.sha256(entry.data).hexdigest(),
                **metadata,
            }
        )

    runtime_asm.append("\n.align 2\n")
    for table, symbols in RUNTIME_TABLES.items():
        missing = [symbol for symbol in symbols if symbol not in RUNTIME_SPRITES]
        if missing:
            raise ValueError(f"runtime table {table} references unknown sprites: {missing}")
        runtime_asm.append(f"{table}:\n    .word {', '.join(symbols)}\n")

    manifest = {
        "format": FORMAT,
        "formula": FORMULA,
        "sprites": records,
        "runtime_sprites": runtime_records,
        "runtime_tables": RUNTIME_TABLES,
    }
    (output_dir / "sprites.s").write_text("".join(asm), encoding="ascii", newline="\n")
    (output_dir / "runtime_sprites.s").write_text(
        "".join(runtime_asm), encoding="ascii", newline="\n"
    )
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    return manifest


def replace_runtime_block(source: str, generated: str) -> str:
    """Return Assembly with only its delimited sprite block replaced."""
    replacement = f"# SPRITE_DATA_BEGIN\n{generated}\n# SPRITE_DATA_END"
    updated, count = re.subn(
        r"# SPRITE_DATA_BEGIN.*?# SPRITE_DATA_END",
        replacement,
        source,
        count=1,
        flags=re.DOTALL,
    )
    if count != 1:
        raise ValueError("sprite markers not found exactly once")
    return updated


def update_runtime_source(render_path: Path, runtime_path: Path) -> None:
    """Replace only the generated sprite block consumed by the game."""
    source = render_path.read_text(encoding="utf-8")
    generated = runtime_path.read_text(encoding="ascii").rstrip()
    updated = replace_runtime_block(source, generated)
    render_path.write_text(updated, encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path("assets/source"))
    parser.add_argument("--output", type=Path, default=Path("assets/generated"))
    parser.add_argument("--size", type=int, default=16)
    parser.add_argument("--render", type=Path, default=Path("src/render.s"))
    parser.add_argument("--no-update-render", action="store_true")
    args = parser.parse_args()
    emit(args.source, args.output, args.size)
    if not args.no_update_render:
        update_runtime_source(args.render, args.output / "runtime_sprites.s")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
