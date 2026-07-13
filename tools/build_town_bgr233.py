"""Build the Town background as direct, material-aware BGR233 pixels."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import struct
from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "backgrounds"
GENERATED_DIR = ROOT / "assets" / "generated"
BASE_SOURCE = SOURCE_DIR / "town_base.png"
HIGHLIGHT_SOURCE = SOURCE_DIR / "town_exit_highlight.png"
SCREEN_SIZE = (320, 240)
PIXEL_COUNT = SCREEN_SIZE[0] * SCREEN_SIZE[1]
EXIT_OVERLAY_PIXEL_COUNT = 66

ASSEMBLY_PATH = GENERATED_DIR / "town_bgr233.s"
BASE_BIN_PATH = GENERATED_DIR / "town_bgr233_base.bin"
OVERLAY_BIN_PATH = GENERATED_DIR / "town_bgr233_exit_overlay.bin"
PREVIEW_PATH = GENERATED_DIR / "town_bgr233_preview.png"
HIGHLIGHT_PREVIEW_PATH = GENERATED_DIR / "town_bgr233_highlight_preview.png"
COMPARISON_PATH = GENERATED_DIR / "town_bgr233_comparison.png"
OBSTACLES_PATH = GENERATED_DIR / "town_bgr233_obstacles_check.png"
METRICS_PATH = GENERATED_DIR / "town_bgr233_metrics.json"

# Authoritative internal Town collision rectangles, copied only for diagnostics.
COLLISION_AABBS = (
    (182, 28, 203, 38),
    (193, 37, 203, 55),
    (271, 31, 302, 42),
    (265, 40, 281, 54),
    (286, 40, 296, 50),
    (171, 80, 181, 126),
    (179, 88, 199, 98),
    (179, 116, 197, 126),
    (187, 124, 197, 142),
    (37, 141, 88, 173),
    (86, 154, 119, 160),
    (100, 196, 110, 217),
    (216, 211, 244, 221),
)

EXTERNAL_COLLISION_RECTS = (
    (0, 0, 134, 9),
    (0, 7, 35, 19),
    (0, 17, 19, 28),
    (0, 26, 9, 77),
    (190, 0, 320, 9),
    (305, 7, 320, 113),
    (0, 137, 9, 230),
    (0, 228, 123, 240),
    (305, 153, 320, 230),
    (189, 228, 320, 240),
)

VEHICLE_BOX = (37, 141, 119, 173)
MANHOLE_BOX = (48, 16, 80, 48)

MIN_CONTRAST = {
    "shadow": 20.0,
    "walls": 30.0,
    "obstacles": 35.0,
    "lane": 60.0,
    "vegetation": 35.0,
    "blood": 40.0,
}


@dataclass(frozen=True)
class BuildResult:
    source_size: tuple[int, int]
    sources_opaque: bool
    original_difference_offsets: tuple[int, ...]
    base: bytes
    highlight: bytes
    overlay: tuple[tuple[int, int], ...]
    preview_base_rgb: tuple[tuple[int, int, int], ...]
    files: dict[Path, bytes]
    metrics: dict[str, object]
    candidates: dict[str, bytes]


def encode_bgr233(red: int, green: int, blue: int) -> int:
    """Encode RGB as the Custom1 direct BBGGGRRR framebuffer byte."""
    return ((blue >> 6) << 6) | ((green >> 5) << 3) | (red >> 5)


def decode_bgr233(value: int) -> tuple[int, int, int]:
    red = value & 0x07
    green = (value >> 3) & 0x07
    blue = (value >> 6) & 0x03
    return (
        round(red * 255 / 7),
        round(green * 255 / 7),
        round(blue * 255 / 3),
    )


def luminance(rgb: tuple[int, int, int]) -> float:
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]


def perceptual_contrast(first: int, second: int) -> float:
    a = decode_bgr233(first)
    b = decode_bgr233(second)
    return math.sqrt(
        0.2126 * (a[0] - b[0]) ** 2
        + 0.7152 * (a[1] - b[1]) ** 2
        + 0.0722 * (a[2] - b[2]) ** 2
    )


def in_box(x: int, y: int, box: tuple[int, int, int, int]) -> bool:
    x0, y0, x1, y1 = box
    return x0 <= x < x1 and y0 <= y < y1


def load_sources() -> tuple[Image.Image, Image.Image, bool]:
    with Image.open(BASE_SOURCE) as opened:
        base = opened.convert("RGBA")
    with Image.open(HIGHLIGHT_SOURCE) as opened:
        highlight = opened.convert("RGBA")
    if base.size != SCREEN_SIZE or highlight.size != SCREEN_SIZE:
        raise ValueError(
            f"Town sources must both be 320x240; got {base.size} and {highlight.size}"
        )
    base_pixels = tuple(base.get_flattened_data())
    highlight_pixels = tuple(highlight.get_flattened_data())
    opaque = all(pixel[3] == 255 for pixel in base_pixels + highlight_pixels)
    if not opaque:
        raise ValueError("Town sources must be fully opaque")
    return base, highlight, opaque


def classify_materials(
    pixels: tuple[tuple[int, int, int, int], ...],
) -> tuple[str, ...]:
    materials: list[str] = []
    for offset, (red, green, blue, _) in enumerate(pixels):
        x = offset % SCREEN_SIZE[0]
        y = offset // SCREEN_SIZE[0]
        neutral = max(red, green, blue) - min(red, green, blue) <= 8
        is_green = green >= 24 and green > red * 1.16 and green > blue * 1.12
        is_blood = red >= 48 and red > green * 1.62 and red > blue * 1.35
        is_lane = red >= 100 and green >= 68 and blue <= 48 and green >= red * 0.62
        is_warm = red >= 28 and red > green * 1.12 and green > blue * 1.08
        in_vehicle = in_box(x, y, VEHICLE_BOX)
        in_obstacle = any(in_box(x, y, box) for box in COLLISION_AABBS)

        if in_vehicle and is_green:
            material = "vehicle_body"
        elif in_vehicle and is_blood:
            material = "vehicle_blood"
        elif in_vehicle and neutral and (red, green, blue) != (43, 43, 43) and red >= 32:
            material = "vehicle_windows"
        elif is_lane:
            material = "lane"
        elif is_green:
            material = "vegetation"
        elif is_blood:
            material = "blood"
        elif is_warm:
            material = "walls"
        elif in_obstacle and neutral and (red >= 50 or abs(red - 43) >= 5):
            material = "obstacles"
        elif neutral and (red, green, blue) == (43, 43, 43):
            material = "asphalt"
        elif neutral:
            material = "shadow"
        else:
            material = "other"
        materials.append(material)
    return tuple(materials)


def palette_for(variant: str) -> dict[str, object]:
    common: dict[str, object] = {
        "walls": (0x01, 0x0A, 0x13, 0x1C),
        "obstacles": (0x48, 0x52, 0x9B, 0xAD),
        "lane": (0x1C, 0x25, 0x2E, 0x37),
        "vegetation": (0x08, 0x10, 0x19, 0x22),
        "blood": (0x01, 0x02, 0x03, 0x04),
        "vehicle_body": (0x08, 0x10, 0x18, 0x21),
        "vehicle_windows": (0x49, 0x52, 0x9B, 0xAD),
        "vehicle_blood": (0x01, 0x02, 0x03, 0x04),
        "manhole_center": 0x00,
        "manhole_depth": 0x40,
        "manhole_inner": 0x49,
        "manhole_outer": 0x52,
        "highlight_dark": 0x2E,
        "highlight_light": 0x77,
    }
    if variant == "light_slate":
        common.update(
            {
                "asphalt": 0x52,
                "shadow_deep": 0x40,
                "shadow": 0x49,
                "shadow_edge": 0x48,
                "asphalt_light": 0x9B,
            }
        )
    elif variant == "dark_slate":
        common.update(
            {
                "asphalt": 0x48,
                "shadow_deep": 0x40,
                "shadow": 0x40,
                "shadow_edge": 0x49,
                "asphalt_light": 0x51,
            }
        )
    else:
        raise ValueError(f"unknown material-aware candidate: {variant}")
    return common


def choose_ladder(ladder: tuple[int, int, int, int], value: float) -> int:
    if value < 32:
        return ladder[0]
    if value < 64:
        return ladder[1]
    if value < 112:
        return ladder[2]
    return ladder[3]


def render_material_candidate(
    source_pixels: tuple[tuple[int, int, int, int], ...],
    highlight_pixels: tuple[tuple[int, int, int, int], ...],
    materials: tuple[str, ...],
    difference_offsets: tuple[int, ...],
    variant: str,
) -> tuple[bytes, bytes, dict[str, object]]:
    palette = palette_for(variant)
    difference_set = set(difference_offsets)
    output = bytearray(PIXEL_COUNT)

    for offset, ((red, green, blue, _), material) in enumerate(zip(source_pixels, materials)):
        value = luminance((red, green, blue))
        if material == "asphalt":
            encoded = int(palette["asphalt"])
        elif material == "shadow":
            if value < 18:
                encoded = int(palette["shadow_deep"])
            elif value < 38:
                encoded = int(palette["shadow"])
            elif value < 51:
                encoded = int(palette["shadow_edge"])
            else:
                encoded = int(palette["asphalt_light"])
        elif material in {
            "walls",
            "obstacles",
            "lane",
            "vegetation",
            "blood",
            "vehicle_body",
            "vehicle_windows",
            "vehicle_blood",
        }:
            encoded = choose_ladder(palette[material], value)  # type: ignore[arg-type]
        else:
            encoded = encode_bgr233(red, green, blue)
        output[offset] = encoded

    # The source itself defines all manhole layers; no geometric pixels are added.
    x0, y0, x1, y1 = MANHOLE_BOX
    for y in range(y0, y1):
        for x in range(x0, x1):
            offset = y * SCREEN_SIZE[0] + x
            red, green, blue, _ = source_pixels[offset]
            if offset in difference_set:
                output[offset] = int(palette["manhole_outer"])
            elif (red, green, blue) == (0, 0, 0):
                output[offset] = int(palette["manhole_center"])
            elif (red, green, blue) == (10, 10, 10):
                output[offset] = int(palette["manhole_depth"])
            elif (red, green, blue) == (33, 33, 33):
                output[offset] = int(palette["manhole_inner"])
            elif (red, green, blue) == (36, 36, 36):
                output[offset] = int(palette["manhole_outer"])

    highlighted = bytearray(output)
    for offset in difference_offsets:
        red, green, blue, _ = highlight_pixels[offset]
        highlighted[offset] = int(
            palette["highlight_light"] if luminance((red, green, blue)) >= 200 else palette["highlight_dark"]
        )
    return bytes(output), bytes(highlighted), palette


def connected_components(values: bytes, target: int) -> tuple[int, ...]:
    seen = bytearray(PIXEL_COUNT)
    sizes: list[int] = []
    width, height = SCREEN_SIZE
    for start, value in enumerate(values):
        if value != target or seen[start]:
            continue
        seen[start] = 1
        queue = deque((start,))
        size = 0
        while queue:
            offset = queue.popleft()
            size += 1
            x = offset % width
            y = offset // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < width and 0 <= ny < height:
                    neighbor = ny * width + nx
                    if not seen[neighbor] and values[neighbor] == target:
                        seen[neighbor] = 1
                        queue.append(neighbor)
        sizes.append(size)
    return tuple(sizes)


def region_offsets(box: tuple[int, int, int, int]) -> tuple[int, ...]:
    x0, y0, x1, y1 = box
    return tuple(y * SCREEN_SIZE[0] + x for y in range(y0, y1) for x in range(x0, x1))


def candidate_quality(
    base: bytes,
    palette: dict[str, object],
    materials: tuple[str, ...],
) -> dict[str, object]:
    asphalt = int(palette["asphalt"])
    material_colors = {
        "asphalt": asphalt,
        "shadow": int(palette["shadow"]),
        "walls": palette["walls"][3],  # type: ignore[index]
        "obstacles": palette["obstacles"][2],  # type: ignore[index]
        "lane": palette["lane"][1],  # type: ignore[index]
        "vegetation": palette["vegetation"][2],  # type: ignore[index]
        "blood": palette["blood"][3],  # type: ignore[index]
    }
    contrasts = {
        material: perceptual_contrast(asphalt, int(color))
        for material, color in material_colors.items()
        if material != "asphalt"
    }
    asphalt_error = abs(luminance(decode_bgr233(asphalt)) - 43.0)
    contrast_reward = sum(min(value, 120.0) for value in contrasts.values()) / len(contrasts)
    black_components = connected_components(base, 0)
    score = contrast_reward - 1.5 * asphalt_error - 0.05 * max(black_components, default=0)
    passed = all(
        contrasts[name] >= MIN_CONTRAST[name]
        for name in MIN_CONTRAST
    )
    return {
        "score": round(score, 4),
        "passed_hard_gates": passed,
        "asphalt_bgr233": f"0x{asphalt:02X}",
        "asphalt_rgb": decode_bgr233(asphalt),
        "asphalt_luminance_error": round(asphalt_error, 4),
        "contrast_from_asphalt": {name: round(value, 4) for name, value in contrasts.items()},
        "largest_black_component": max(black_components, default=0),
    }


def png_bytes(rgb_pixels: tuple[tuple[int, int, int], ...]) -> bytes:
    from io import BytesIO

    image = Image.new("RGB", SCREEN_SIZE)
    image.putdata(rgb_pixels)
    buffer = BytesIO()
    image.save(buffer, format="PNG", optimize=False)
    return buffer.getvalue()


def image_from_payload(payload: bytes) -> Image.Image:
    image = Image.new("RGB", SCREEN_SIZE)
    image.putdata(tuple(decode_bgr233(value) for value in payload))
    return image


def comparison_png(
    original: Image.Image,
    baseline: bytes,
    chosen: bytes,
    highlighted: bytes,
) -> bytes:
    from io import BytesIO

    labels = ("Original RGB", "Nearest BGR233", "Material-aware", "Bueiro destacado")
    images = (
        original.convert("RGB"),
        image_from_payload(baseline),
        image_from_payload(chosen),
        image_from_payload(highlighted),
    )
    canvas = Image.new("RGB", (SCREEN_SIZE[0] * 4, SCREEN_SIZE[1] + 18), (245, 245, 245))
    draw = ImageDraw.Draw(canvas)
    for index, (label, image) in enumerate(zip(labels, images)):
        x = index * SCREEN_SIZE[0]
        draw.text((x + 4, 3), label, fill=(0, 0, 0))
        canvas.paste(image, (x, 18))
    buffer = BytesIO()
    canvas.save(buffer, format="PNG", optimize=False)
    return buffer.getvalue()


def obstacles_png(payload: bytes) -> bytes:
    from io import BytesIO

    image = image_from_payload(payload)
    draw = ImageDraw.Draw(image)
    for box in EXTERNAL_COLLISION_RECTS:
        x0, y0, x1, y1 = box
        draw.rectangle((x0, y0, x1 - 1, y1 - 1), outline=(0, 168, 255))
    for box in COLLISION_AABBS:
        x0, y0, x1, y1 = box
        draw.rectangle((x0, y0, x1 - 1, y1 - 1), outline=(0, 168, 255))
    buffer = BytesIO()
    image.save(buffer, format="PNG", optimize=False)
    return buffer.getvalue()


def render_assembly(base: bytes, overlay: tuple[tuple[int, int], ...]) -> bytes:
    lines = [
        "# Generated by tools/build_town_bgr233.py; do not edit.",
        "# Direct BGR233 8bpp (BBGGGRRR), 320x240, row-major, no dithering.",
        "",
        ".data",
        ".align 2",
        "",
        f"# payload-bytes: {len(base)}",
        "town_bgr233_base_pixels:",
    ]
    for offset in range(0, len(base), 32):
        lines.append("    .byte " + ", ".join(f"0x{value:02X}" for value in base[offset : offset + 32]))
    lines.extend(("", f"# overlay-pixels: {len(overlay)}", "town_bgr233_exit_overlay_pixels:"))
    words = tuple((offset << 8) | value for offset, value in overlay)
    for offset in range(0, len(words), 8):
        lines.append("    .word " + ", ".join(f"0x{value:08X}" for value in words[offset : offset + 8]))
    return ("\n".join(lines) + "\n").encode("ascii")


def build(*, write: bool = True) -> BuildResult:
    base_source, highlight_source, opaque = load_sources()
    base_pixels = tuple(base_source.get_flattened_data())
    highlight_pixels = tuple(highlight_source.get_flattened_data())
    difference_offsets = tuple(
        offset
        for offset, pair in enumerate(zip(base_pixels, highlight_pixels))
        if pair[0] != pair[1]
    )
    if len(difference_offsets) != EXIT_OVERLAY_PIXEL_COUNT:
        raise ValueError(
            f"Town source overlay must contain 66 coordinates, got {len(difference_offsets)}"
        )

    materials = classify_materials(base_pixels)
    nearest = bytes(encode_bgr233(red, green, blue) for red, green, blue, _ in base_pixels)
    candidates: dict[str, bytes] = {"nearest": nearest}
    highlights: dict[str, bytes] = {}
    palettes: dict[str, dict[str, object]] = {}
    candidate_metrics: dict[str, dict[str, object]] = {
        "nearest": {
            "passed_hard_gates": False,
            "asphalt_bgr233": "0x09",
            "reason": "dominant asphalt and neutral shadows collapse under global nearest conversion",
        }
    }
    for name in ("light_slate", "dark_slate"):
        candidate, highlighted, palette = render_material_candidate(
            base_pixels, highlight_pixels, materials, difference_offsets, name
        )
        candidates[name] = candidate
        highlights[name] = highlighted
        palettes[name] = palette
        candidate_metrics[name] = candidate_quality(candidate, palette, materials)

    eligible = tuple(
        name
        for name in ("light_slate", "dark_slate")
        if candidate_metrics[name]["passed_hard_gates"]
    )
    if not eligible:
        raise RuntimeError("No material-aware Town candidate passed the contrast gates")
    selected = max(eligible, key=lambda name: float(candidate_metrics[name]["score"]))
    base = candidates[selected]
    highlight = highlights[selected]
    palette = palettes[selected]
    overlay = tuple((offset, highlight[offset]) for offset in difference_offsets)
    actual_differences = tuple(
        offset for offset, pair in enumerate(zip(base, highlight)) if pair[0] != pair[1]
    )
    if actual_differences != difference_offsets:
        raise RuntimeError("Converted Town overlay does not match the approved 66-pixel mask")

    asphalt = int(palette["asphalt"])
    material_colors = {
        "asphalt": asphalt,
        "shadow": int(palette["shadow"]),
        "walls": int(palette["walls"][3]),  # type: ignore[index]
        "obstacles": int(palette["obstacles"][2]),  # type: ignore[index]
        "lane": int(palette["lane"][1]),  # type: ignore[index]
        "vegetation": int(palette["vegetation"][2]),  # type: ignore[index]
        "blood": int(palette["blood"][3]),  # type: ignore[index]
    }
    contrast_from_asphalt = {
        name: perceptual_contrast(asphalt, value)
        for name, value in material_colors.items()
        if name != "asphalt"
    }

    collision_obstacles: list[dict[str, object]] = []
    for index, box in enumerate(COLLISION_AABBS, 1):
        offsets = region_offsets(box)
        values = {base[offset] for offset in offsets}
        non_asphalt = sum(base[offset] != asphalt for offset in offsets)
        collision_obstacles.append(
            {
                "index": index,
                "box": box,
                "visible_pixels": non_asphalt,
                "non_asphalt_fraction": non_asphalt / len(offsets),
                "distinct_colors": len(values),
                "uniform_black": values == {0},
            }
        )

    region_checks: dict[str, dict[str, int]] = {}
    for name in (
        "vehicle_body",
        "vehicle_windows",
        "vehicle_blood",
        "lane",
        "vegetation",
        "blood",
    ):
        offsets = tuple(index for index, material in enumerate(materials) if material == name)
        region_checks[name] = {
            "pixels": len(offsets),
            "distinct_from_asphalt": sum(base[offset] != asphalt for offset in offsets),
        }

    manhole_offsets = region_offsets(MANHOLE_BOX)
    manhole_values = {base[offset] for offset in manhole_offsets if base_pixels[offset][:3] != (43, 43, 43)}
    outer = int(palette["manhole_outer"])
    inner = int(palette["manhole_inner"])
    center = int(palette["manhole_center"])
    highlight_luminance = sum(luminance(decode_bgr233(highlight[offset])) for offset in difference_offsets) / len(difference_offsets)

    important_names = ("walls", "obstacles", "vehicle_body", "vehicle_windows", "lane", "vegetation", "blood")
    important_black_fractions: dict[str, float] = {}
    for name in important_names:
        offsets = tuple(index for index, material in enumerate(materials) if material == name)
        important_black_fractions[name] = (
            sum(base[offset] == 0 for offset in offsets) / len(offsets) if offsets else 0.0
        )

    black_components = connected_components(base, 0)
    metrics: dict[str, object] = {
        "selected_candidate": selected,
        "candidate_metrics": candidate_metrics,
        "asphalt_bgr233": f"0x{asphalt:02X}",
        "asphalt_rgb": decode_bgr233(asphalt),
        "material_colors": material_colors,
        "material_rgb": {name: decode_bgr233(value) for name, value in material_colors.items()},
        "contrast_from_asphalt": contrast_from_asphalt,
        "dithering": False,
        "runtime_palette_lookup": False,
        "source_difference_pixels": len(difference_offsets),
        "converted_difference_pixels": len(actual_differences),
        "overlay_coordinates_match": actual_differences == difference_offsets,
        "collision_obstacles": collision_obstacles,
        "region_checks": region_checks,
        "manhole": {
            "base_levels": len(manhole_values),
            "outer_color": outer,
            "inner_color": inner,
            "center_color": center,
            "outer_luminance": luminance(decode_bgr233(outer)),
            "highlight_luminance": highlight_luminance,
        },
        "largest_black_component": max(black_components, default=0),
        "important_black_fractions": important_black_fractions,
        "art_collision_divergences": [],
    }

    preview_base_rgb = tuple(decode_bgr233(value) for value in base)
    preview_highlight_rgb = tuple(decode_bgr233(value) for value in highlight)
    assembly = render_assembly(base, overlay)
    overlay_binary = b"".join(struct.pack("<I", (offset << 8) | value) for offset, value in overlay)
    metrics_for_json = dict(metrics)
    metrics_for_json["hashes"] = {
        "base_sha256": hashlib.sha256(base).hexdigest(),
        "highlight_sha256": hashlib.sha256(highlight).hexdigest(),
        "overlay_sha256": hashlib.sha256(overlay_binary).hexdigest(),
    }
    files = {
        ASSEMBLY_PATH: assembly,
        BASE_BIN_PATH: base,
        OVERLAY_BIN_PATH: overlay_binary,
        PREVIEW_PATH: png_bytes(preview_base_rgb),
        HIGHLIGHT_PREVIEW_PATH: png_bytes(preview_highlight_rgb),
        COMPARISON_PATH: comparison_png(base_source, nearest, base, highlight),
        OBSTACLES_PATH: obstacles_png(base),
        METRICS_PATH: (json.dumps(metrics_for_json, indent=2, sort_keys=True) + "\n").encode("utf-8"),
    }
    if write:
        GENERATED_DIR.mkdir(parents=True, exist_ok=True)
        for path, payload in files.items():
            path.write_bytes(payload)
    return BuildResult(
        source_size=base_source.size,
        sources_opaque=opaque,
        original_difference_offsets=difference_offsets,
        base=base,
        highlight=highlight,
        overlay=overlay,
        preview_base_rgb=preview_base_rgb,
        files=files,
        metrics=metrics,
        candidates=candidates,
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail if generated files are stale")
    args = parser.parse_args()
    result = build(write=False)
    if args.check:
        stale = tuple(
            str(path.relative_to(ROOT))
            for path, expected in result.files.items()
            if not path.exists() or path.read_bytes() != expected
        )
        if stale:
            print("stale generated Town BGR233 files: " + ", ".join(stale))
            return 1
        print("Town BGR233 generated files: PASS")
        return 0
    for path, payload in result.files.items():
        path.write_bytes(payload)
    print(
        json.dumps(
            {
                "selected": result.metrics["selected_candidate"],
                "asphalt": result.metrics["asphalt_bgr233"],
                "overlay_pixels": len(result.overlay),
                "base_bytes": len(result.base),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
