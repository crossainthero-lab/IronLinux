#!/usr/bin/env python3
"""Render Iron Linux PNG branding assets from vector/source artwork."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets" / "branding"


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def vertical_gradient(size: tuple[int, int], top: str, bottom: str) -> Image.Image:
    width, height = size
    top_rgb = hex_to_rgb(top)
    bottom_rgb = hex_to_rgb(bottom)
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        color = tuple(lerp(top_rgb[i], bottom_rgb[i], t) for i in range(3))
        for x in range(width):
            pixels[x, y] = color
    return image


def cover_resize(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    target_w, target_h = size
    src_w, src_h = image.size
    scale = max(target_w / src_w, target_h / src_h)
    resized = image.resize((round(src_w * scale), round(src_h * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - target_w) // 2
    top = (resized.height - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))


def add_vignette(image: Image.Image, strength: int = 132) -> Image.Image:
    width, height = image.size
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    margin_x = round(width * 0.09)
    margin_y = round(height * 0.06)
    draw.ellipse((margin_x, margin_y, width - margin_x, height - margin_y), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(round(min(width, height) * 0.16)))
    dark = Image.new("RGB", image.size, "#020303")
    return Image.composite(image, dark, mask.point(lambda p: max(0, p - strength)))


def draw_logo(size: int, transparent: bool = True) -> Image.Image:
    scale = size / 512
    canvas_size = size * 4
    s = canvas_size / 512
    mode = "RGBA"
    image = Image.new(mode, (canvas_size, canvas_size), (0, 0, 0, 0) if transparent else (8, 10, 11, 255))
    draw = ImageDraw.Draw(image, "RGBA")

    def pts(values: list[tuple[float, float]]) -> list[tuple[float, float]]:
        return [(x * s, y * s) for x, y in values]

    def poly(values: list[tuple[float, float]], fill: tuple[int, int, int, int]) -> None:
        draw.polygon(pts(values), fill=fill)

    shield = [(256, 34), (430, 132), (430, 324), (256, 478), (82, 324), (82, 132)]
    inner = [(256, 56), (407, 142), (407, 313), (256, 448), (105, 313), (105, 142)]
    poly(shield, (5, 7, 8, 255))
    draw.line(pts(shield + [shield[0]]), fill=(198, 205, 208, 230), width=round(14 * s), joint="curve")
    draw.line(pts(inner + [inner[0]]), fill=(24, 28, 31, 255), width=round(20 * s), joint="curve")

    mark = [
        (176, 128),
        (336, 128),
        (368, 174),
        (292, 174),
        (292, 338),
        (354, 338),
        (322, 384),
        (182, 384),
        (214, 338),
        (252, 338),
        (252, 174),
        (208, 174),
    ]
    poly(mark, (178, 186, 190, 255))
    draw.line(pts(mark + [mark[0]]), fill=(245, 247, 248, 88), width=round(7 * s), joint="curve")

    # Faceted metallic shadows/highlights that keep the "I" readable at boot size.
    poly([(176, 128), (208, 174), (252, 174), (252, 226), (222, 204)], (239, 243, 244, 110))
    poly([(336, 128), (368, 174), (292, 174), (292, 235), (326, 206)], (62, 70, 75, 150))
    poly([(292, 338), (354, 338), (322, 384), (292, 384)], (224, 229, 231, 122))
    poly([(182, 384), (214, 338), (252, 338), (252, 384)], (47, 53, 57, 172))
    draw.rectangle((round(250 * s), round(174 * s), round(294 * s), round(338 * s)), fill=(114, 122, 127, 255))
    draw.line((round(250 * s), round(174 * s), round(250 * s), round(338 * s)), fill=(239, 242, 243, 74), width=round(5 * s))
    draw.line((round(294 * s), round(174 * s), round(294 * s), round(338 * s)), fill=(0, 0, 0, 92), width=round(5 * s))
    draw.line(pts([(104, 146), (256, 60), (408, 146)]), fill=(255, 255, 255, 55), width=round(4 * s))
    draw.line(pts([(104, 313), (256, 447), (408, 313)]), fill=(0, 0, 0, 120), width=round(6 * s))

    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow, "RGBA")
    shadow_draw.ellipse((70 * s, 88 * s, 442 * s, 484 * s), fill=(0, 0, 0, 72))
    shadow = shadow.filter(ImageFilter.GaussianBlur(round(18 * s)))
    image = Image.alpha_composite(shadow, image)
    return image.resize((size, size), Image.Resampling.LANCZOS)


def splash(size: tuple[int, int]) -> Image.Image:
    image = vertical_gradient(size, "#101416", "#030405").convert("RGBA")
    draw = ImageDraw.Draw(image, "RGBA")
    width, height = size
    for offset, alpha in ((0, 60), (38, 34), (76, 20)):
        draw.line((0, height * 0.63 + offset, width, height * 0.43 + offset), fill=(105, 115, 120, alpha), width=2)
    logo_size = round(height * 0.39)
    logo = draw_logo(logo_size, transparent=True)
    image.alpha_composite(logo, ((width - logo_size) // 2, round(height * 0.34)))
    return image.convert("RGB")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--wallpaper-source", type=Path, required=True)
    args = parser.parse_args()

    BRANDING.mkdir(parents=True, exist_ok=True)

    draw_logo(1024, transparent=True).save(BRANDING / "logo.png")

    source = Image.open(args.wallpaper_source).convert("RGB")
    wallpaper = add_vignette(cover_resize(source, (3840, 2160)), 112)
    wallpaper.save(BRANDING / "wallpaper-4k.png", optimize=True)

    # Greeter and lock screen reuse the same visual language with slightly darker treatment.
    login = add_vignette(wallpaper.filter(ImageFilter.GaussianBlur(0.35)), 148)
    login.save(BRANDING / "login-background.png", optimize=True)

    lock = wallpaper.copy()
    overlay = Image.new("RGB", lock.size, "#050707")
    lock = Image.blend(lock, overlay, 0.18)
    lock.save(BRANDING / "lockscreen.png", optimize=True)

    splash((1920, 1080)).save(BRANDING / "plymouth-splash.png", optimize=True)


if __name__ == "__main__":
    main()
