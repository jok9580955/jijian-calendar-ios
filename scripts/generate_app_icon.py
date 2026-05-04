#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import json
import math

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "极简日历-倒数日-日程提醒与桌面小组件" / "Assets.xcassets" / "AppIcon.appiconset"


def lerp(a, b, t):
    return int(a + (b - a) * t)


def gradient(size, top, bottom, side):
    img = Image.new("RGB", (size, size), top)
    px = img.load()
    for y in range(size):
        for x in range(size):
            ty = y / (size - 1)
            tx = x / (size - 1)
            t = min(1, ty * 0.82 + tx * 0.18)
            r = lerp(top[0], bottom[0], t)
            g = lerp(top[1], bottom[1], t)
            b = lerp(top[2], bottom[2], t)
            r = lerp(r, side[0], max(0, tx - 0.55) * 0.36)
            g = lerp(g, side[1], max(0, tx - 0.55) * 0.36)
            b = lerp(b, side[2], max(0, tx - 0.55) * 0.36)
            px[x, y] = (r, g, b)
    return img


def rounded_rect_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def paste_shadow(base, box, radius, offset, alpha):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    mask = rounded_rect_mask(max(w, h), radius).crop((0, 0, w, h))
    layer = Image.new("RGBA", (w, h), (20, 19, 32, alpha))
    shadow.alpha_composite(layer, (x0 + offset[0], y0 + offset[1]))
    shadow.putalpha(shadow.getchannel("A").filter(ImageFilter.GaussianBlur(32)))
    base.alpha_composite(shadow)
    return mask


def draw_icon(size=1024, mode="light"):
    if mode == "dark":
        bg = gradient(size, (47, 42, 61), (22, 23, 34), (245, 76, 111))
        accent = (255, 102, 132)
        teal = (54, 219, 189)
        paper = (248, 249, 255)
        ink = (76, 78, 92)
    elif mode == "tinted":
        bg = gradient(size, (237, 239, 244), (204, 209, 219), (255, 255, 255))
        accent = (92, 92, 100)
        teal = (122, 122, 132)
        paper = (255, 255, 255)
        ink = (96, 96, 106)
    else:
        bg = gradient(size, (255, 128, 104), (255, 32, 84), (177, 33, 71))
        accent = (248, 67, 98)
        teal = (0, 174, 154)
        paper = (255, 255, 255)
        ink = (92, 94, 108)

    img = bg.convert("RGBA")
    d = ImageDraw.Draw(img)

    # Soft depth behind the calendar sheet.
    sheet = (int(size * 0.235), int(size * 0.215), int(size * 0.765), int(size * 0.745))
    paste_shadow(img, sheet, int(size * 0.075), (0, int(size * 0.035)), 90)
    d.rounded_rectangle(sheet, radius=int(size * 0.075), fill=paper)

    # Top binding.
    top_y = int(size * 0.305)
    d.rounded_rectangle((int(size * 0.305), top_y, int(size * 0.695), top_y + int(size * 0.045)),
                        radius=int(size * 0.022), fill=(238, 240, 246))
    for x in (int(size * 0.345), int(size * 0.655)):
        d.ellipse((x - int(size * 0.036), top_y - int(size * 0.035), x + int(size * 0.036), top_y + int(size * 0.037)),
                  fill=accent)
        d.ellipse((x - int(size * 0.018), top_y - int(size * 0.017), x + int(size * 0.018), top_y + int(size * 0.019)),
                  fill=paper)

    # Calendar date dots.
    start_x = int(size * 0.345)
    start_y = int(size * 0.41)
    gap = int(size * 0.075)
    r = int(size * 0.014)
    active_positions = {(1, 2): accent, (2, 0): teal, (3, 3): accent}
    for row in range(4):
        for col in range(4):
            x = start_x + col * gap
            y = start_y + row * gap
            color = active_positions.get((row, col), (220, 224, 232))
            d.ellipse((x - r, y - r, x + r, y + r), fill=color)

    # Countdown chip.
    chip = (int(size * 0.405), int(size * 0.635), int(size * 0.67), int(size * 0.705))
    d.rounded_rectangle(chip, radius=int(size * 0.035), fill=(245, 247, 252))
    d.ellipse((chip[0] + int(size * 0.032), chip[1] + int(size * 0.023),
               chip[0] + int(size * 0.058), chip[1] + int(size * 0.049)), fill=teal)
    for i, width in enumerate((0.12, 0.08)):
        y = chip[1] + int(size * (0.024 + i * 0.026))
        d.rounded_rectangle((chip[0] + int(size * 0.078), y, chip[0] + int(size * (0.078 + width)), y + int(size * 0.01)),
                            radius=int(size * 0.005), fill=ink)

    # A tiny plus badge in the lower-right corner, useful at small sizes.
    badge_center = (int(size * 0.74), int(size * 0.735))
    badge_r = int(size * 0.078)
    d.ellipse((badge_center[0] - badge_r, badge_center[1] - badge_r,
               badge_center[0] + badge_r, badge_center[1] + badge_r), fill=accent)
    line = int(size * 0.058)
    thick = int(size * 0.014)
    d.rounded_rectangle((badge_center[0] - line // 2, badge_center[1] - thick // 2,
                         badge_center[0] + line // 2, badge_center[1] + thick // 2),
                        radius=thick // 2, fill=(255, 255, 255))
    d.rounded_rectangle((badge_center[0] - thick // 2, badge_center[1] - line // 2,
                         badge_center[0] + thick // 2, badge_center[1] + line // 2),
                        radius=thick // 2, fill=(255, 255, 255))

    # Subtle highlight, no alpha in final App Store icon.
    highlight = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    hd = ImageDraw.Draw(highlight)
    hd.ellipse((-int(size * 0.35), -int(size * 0.45), int(size * 0.85), int(size * 0.45)), fill=(255, 255, 255, 42))
    img.alpha_composite(highlight)
    return img.convert("RGB")


def save_resized(source, filename, size):
    target = ICON_DIR / filename
    source.resize((size, size), Image.Resampling.LANCZOS).save(target, "PNG", optimize=True)


def main():
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    light = draw_icon(1024, "light")
    dark = draw_icon(1024, "dark")
    tinted = draw_icon(1024, "tinted")

    save_resized(light, "AppIcon-1024.png", 1024)
    save_resized(dark, "AppIcon-1024-dark.png", 1024)
    save_resized(tinted, "AppIcon-1024-tinted.png", 1024)

    mac_slots = [
        ("AppIcon-mac-16.png", 16), ("AppIcon-mac-16@2x.png", 32),
        ("AppIcon-mac-32.png", 32), ("AppIcon-mac-32@2x.png", 64),
        ("AppIcon-mac-128.png", 128), ("AppIcon-mac-128@2x.png", 256),
        ("AppIcon-mac-256.png", 256), ("AppIcon-mac-256@2x.png", 512),
        ("AppIcon-mac-512.png", 512), ("AppIcon-mac-512@2x.png", 1024),
    ]
    for filename, icon_size in mac_slots:
        save_resized(light, filename, icon_size)

    contents = {
        "images": [
            {"filename": "AppIcon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}], "filename": "AppIcon-1024-dark.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "tinted"}], "filename": "AppIcon-1024-tinted.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"filename": "AppIcon-mac-16.png", "idiom": "mac", "scale": "1x", "size": "16x16"},
            {"filename": "AppIcon-mac-16@2x.png", "idiom": "mac", "scale": "2x", "size": "16x16"},
            {"filename": "AppIcon-mac-32.png", "idiom": "mac", "scale": "1x", "size": "32x32"},
            {"filename": "AppIcon-mac-32@2x.png", "idiom": "mac", "scale": "2x", "size": "32x32"},
            {"filename": "AppIcon-mac-128.png", "idiom": "mac", "scale": "1x", "size": "128x128"},
            {"filename": "AppIcon-mac-128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128"},
            {"filename": "AppIcon-mac-256.png", "idiom": "mac", "scale": "1x", "size": "256x256"},
            {"filename": "AppIcon-mac-256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256"},
            {"filename": "AppIcon-mac-512.png", "idiom": "mac", "scale": "1x", "size": "512x512"},
            {"filename": "AppIcon-mac-512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512"},
        ],
        "info": {"author": "xcode", "version": 1}
    }
    (ICON_DIR / "Contents.json").write_text(json.dumps(contents, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Generated app icons in {ICON_DIR}")


if __name__ == "__main__":
    main()
