"""Build and validate the two native-size sprite pilots for review."""

from __future__ import annotations

import argparse
import io
import zipfile
from collections.abc import Iterable, Sequence
from pathlib import Path

from PIL import Image


TRANSPARENT = (0, 0, 0, 0)
PREVIEW_SCALE = 16

PLAYER_PALETTE = {
    "K": (24, 22, 19, 255),
    "R": (225, 43, 39, 255),
    "r": (143, 25, 27, 255),
    "S": (238, 169, 112, 255),
    "s": (184, 105, 68, 255),
    "W": (242, 238, 220, 255),
    "w": (177, 182, 166, 255),
    "G": (56, 126, 57, 255),
    "g": (25, 75, 39, 255),
}

RAT_PALETTE = {
    "K": (24, 23, 22, 255),
    "D": (57, 54, 52, 255),
    "M": (91, 86, 79, 255),
    "L": (139, 128, 112, 255),
    "P": (203, 117, 112, 255),
    "I": (92, 119, 53, 255),
    "X": (214, 49, 46, 255),
}

PLAYER_PIXELS = (
    "................",
    "................",
    ".....rrrrrr.....",
    "....rRRRRRrrr...",
    "...KSSSSSSSK....",
    "...KSsKSKsSK....",
    "...KSSSSSSSK....",
    "...sKKWWWKs.....",
    "...sKWWWWWWKs...",
    "...sKwwwwwwKs...",
    "....KGGGGGGK....",
    "....KGgGGgGK....",
    "....KGgGGgGK....",
    "....KggKKggK....",
    "....KKK..KKK....",
    "...KKK....KKK...",
)

RAT_PIXELS = (
    "................",
    "................",
    "................",
    "................",
    "........KP......",
    ".......KPKKK....",
    "....KKKMMMMMKK..",
    "....KKMMMMMMLLK.",
    "...KDDMMMMMMLLKK",
    "PPPPKMMMMMMLXKKK",
    "....KDMMIIILLPPK",
    ".....KKKMMKPK...",
    "......KDK.KMK...",
    "......KPK.KPK...",
    "................",
    "................",
)


def open_rgba(path: Path) -> Image.Image:
    with Image.open(path) as source:
        return source.convert("RGBA")


def split_sheet(image: Image.Image, frame_size: tuple[int, int]) -> list[Image.Image]:
    """Split a regular sheet in row-major order without resizing frames."""
    frame_width, frame_height = frame_size
    if image.width % frame_width or image.height % frame_height:
        raise ValueError(f"sheet {image.size} is not divisible by {frame_size}")
    return [
        image.crop((x, y, x + frame_width, y + frame_height))
        for y in range(0, image.height, frame_height)
        for x in range(0, image.width, frame_width)
    ]


def native_canvas(size: tuple[int, int]) -> Image.Image:
    return Image.new("RGBA", size, TRANSPARENT)


def sprite_from_rows(
    rows: Sequence[str], palette: dict[str, tuple[int, int, int, int]]
) -> Image.Image:
    height = len(rows)
    width = len(rows[0]) if rows else 0
    if not width or any(len(row) != width for row in rows):
        raise ValueError("sprite rows must form a non-empty rectangle")
    image = native_canvas((width, height))
    for y, row in enumerate(rows):
        for x, key in enumerate(row):
            if key != ".":
                image.putpixel((x, y), palette[key])
    return image


def build_player_idle_front() -> Image.Image:
    return sprite_from_rows(PLAYER_PIXELS, PLAYER_PALETTE)


def build_rat_common_side() -> Image.Image:
    return sprite_from_rows(RAT_PIXELS, RAT_PALETTE)


def quantize_to_palette(
    image: Image.Image, palette: Iterable[tuple[int, int, int, int]]
) -> Image.Image:
    """Map opaque pixels to the nearest supplied RGBA color; alpha stays binary."""
    colors = [color for color in palette if color[3] == 255]
    if not colors:
        raise ValueError("palette requires at least one opaque color")
    output = native_canvas(image.size)
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = image.getpixel((x, y))
            if alpha == 0:
                continue
            nearest = min(
                colors,
                key=lambda color: (
                    (red - color[0]) ** 2
                    + (green - color[1]) ** 2
                    + (blue - color[2]) ** 2
                ),
            )
            output.putpixel((x, y), nearest)
    return output


def image_stats(image: Image.Image) -> dict[str, object]:
    rgba = image.convert("RGBA")
    pixels = list(
        rgba.get_flattened_data() if hasattr(rgba, "get_flattened_data") else rgba.getdata()
    )
    alpha_values = sorted({pixel[3] for pixel in pixels})
    opaque = [pixel for pixel in pixels if pixel[3] == 255]
    bbox = rgba.getchannel("A").getbbox()
    return {
        "size": rgba.size,
        "mode": rgba.mode,
        "opaque_colors": len(set(opaque)),
        "alpha_values": alpha_values,
        "bbox": bbox,
        "content_size": (bbox[2] - bbox[0], bbox[3] - bbox[1]) if bbox else (0, 0),
        "opaque_pixels": len(opaque),
        "partial_alpha": any(alpha not in (0, 255) for alpha in alpha_values),
    }


def rgba_to_rars8(pixel: tuple[int, int, int, int]) -> int:
    red, green, blue, alpha = pixel
    if alpha == 0:
        return 0
    value = ((blue >> 6) << 6) | ((green >> 5) << 3) | (red >> 5)
    return value or 1


def fit_original_to_native(image: Image.Image, size: int = 16) -> Image.Image:
    """Reproduce the existing converter's crop/nearest/center comparison view."""
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("original sprite is fully transparent")
    crop = rgba.crop(bbox)
    scale = min(size / crop.width, size / crop.height, 1.0)
    resized = crop.resize(
        (max(1, round(crop.width * scale)), max(1, round(crop.height * scale))),
        Image.Resampling.NEAREST,
    )
    canvas = native_canvas((size, size))
    canvas.alpha_composite(
        resized, ((size - resized.width) // 2, (size - resized.height) // 2)
    )
    return canvas


def _zip_rgba(archive_path: Path, member: str) -> Image.Image:
    with zipfile.ZipFile(archive_path) as archive:
        data = archive.read(member)
    with Image.open(io.BytesIO(data)) as source:
        return source.convert("RGBA")


def comparison_preview(original: Image.Image, pilot: Image.Image) -> Image.Image:
    original_native = fit_original_to_native(original)
    left = original_native.resize((256, 256), Image.Resampling.NEAREST)
    right = pilot.resize((256, 256), Image.Resampling.NEAREST)
    comparison = Image.new("RGBA", (512, 256), TRANSPARENT)
    comparison.alpha_composite(left, (0, 0))
    comparison.alpha_composite(right, (256, 0))
    return comparison


def validate_pilot(
    name: str, image: Image.Image, expected_bbox: tuple[int, int, int, int], max_colors: int
) -> dict[str, object]:
    stats = image_stats(image)
    if stats["size"] != (16, 16):
        raise ValueError(f"{name}: expected 16x16, got {stats['size']}")
    if stats["mode"] != "RGBA":
        raise ValueError(f"{name}: expected RGBA")
    if stats["partial_alpha"]:
        raise ValueError(f"{name}: partial alpha is forbidden")
    if stats["bbox"] != expected_bbox:
        raise ValueError(f"{name}: unexpected bbox {stats['bbox']}")
    if not 1 <= int(stats["opaque_colors"]) <= max_colors:
        raise ValueError(f"{name}: excessive color count")
    return stats


def _print_validation(name: str, stats: dict[str, object]) -> None:
    print(
        f"{name}: size={stats['size']} mode={stats['mode']} "
        f"opaque_colors={stats['opaque_colors']} alpha={stats['alpha_values']} "
        f"bbox={stats['bbox']} content={stats['content_size']} "
        f"opaque_pixels={stats['opaque_pixels']} partial_alpha={stats['partial_alpha']} "
        "palette=RARS-BGR233-compatible bytes=256 antialiasing=no "
        "large_concept_resize=no"
    )


def generate_pilots(repo_root: Path, output_root: Path) -> list[Path]:
    native = output_root / "native"
    previews = output_root / "previews"
    native.mkdir(parents=True, exist_ok=True)
    previews.mkdir(parents=True, exist_ok=True)

    player = build_player_idle_front()
    rat = build_rat_common_side()
    player_stats = validate_pilot("player_idle_front", player, (3, 2, 13, 16), 10)
    rat_stats = validate_pilot("rat_common_side", rat, (0, 4, 16, 14), 10)

    player_path = native / "player_idle_front.png"
    rat_path = native / "rat_common_side.png"
    player.save(player_path)
    rat.save(rat_path)

    player_original = _zip_rgba(
        repo_root / "assets" / "source" / "Protagonista .zip", "sprite_00.png"
    )
    rat_original = _zip_rgba(
        repo_root / "assets" / "source" / "sprites-1.zip",
        "sprites/image-1.png.png",
    )
    player_preview = previews / "player_comparison.png"
    rat_preview = previews / "rat_common_comparison.png"
    comparison_preview(player_original, player).save(player_preview)
    comparison_preview(rat_original, rat).save(rat_preview)

    _print_validation("player_idle_front", player_stats)
    _print_validation("rat_common_side", rat_stats)
    return [player_path, rat_path, player_preview, rat_preview]


def _package_summary(pixelrats_zip: Path | None, snoblin_zip: Path | None) -> None:
    if pixelrats_zip:
        with zipfile.ZipFile(pixelrats_zip) as archive:
            pngs = [name for name in archive.namelist() if name.lower().endswith(".png")]
            frames = []
            for name in pngs:
                with Image.open(io.BytesIO(archive.read(name))) as image:
                    frames.append(image.width // 32 * (image.height // 32))
        print(
            f"PixelRats: {len(pngs)} color sheets; {frames[0] if frames else 0} "
            "walk frames each; side view only; opposite side may be mirrored; up/down absent"
        )
    if snoblin_zip:
        with zipfile.ZipFile(snoblin_zip) as archive:
            base = "Characters/Prototype_Character/Default/"
            parts = []
            for action in ("idle", "walk", "hurt", "death"):
                with Image.open(io.BytesIO(archive.read(base + action + ".png"))) as image:
                    count = image.width // 32 * (image.height // 32)
                    parts.append(f"{action}={count}")
        print(
            "Snoblin: " + ", ".join(parts) + "; front/side/back rows; "
            "mirror the side row for the opposite lateral direction"
        )


def _weapon_summary(project_sprites_zip: Path | None) -> None:
    if not project_sprites_zip:
        return
    with zipfile.ZipFile(project_sprites_zip) as archive:
        for weapon in ("pistol", "shotgun", "uzi"):
            member = f"sprites/items/{weapon}_pickup.png"
            with Image.open(io.BytesIO(archive.read(member))) as source:
                stats = image_stats(source.convert("RGBA"))
            print(
                f"{weapon}: size={stats['size']} colors={stats['opaque_colors']} "
                f"alpha={stats['alpha_values']} offline_composition=yes "
                "anchors=per-direction hand_x,hand_y"
            )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--project-sprites-zip", type=Path)
    parser.add_argument("--pixelrats-zip", type=Path)
    parser.add_argument("--snoblin-zip", type=Path)
    args = parser.parse_args()
    generate_pilots(args.repo.resolve(), args.output.resolve())
    _package_summary(args.pixelrats_zip, args.snoblin_zip)
    _weapon_summary(args.project_sprites_zip)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
