"""Generate a branded QR code that points to a release's APK download URL.

Usage:
    python scripts/make_release_qr.py v1.0.11

Produces docs/assets/rethicsec-<tag>-qr.png: a designed card (cream background,
rounded earth-brown QR modules, a title and a "scan to download / Android" caption)
encoding the GitHub release download URL for rethicsec-<tag>.apk. Scanning it on a
phone downloads the APK.

Upload it to the release with:
    gh release upload <tag> docs/assets/rethicsec-<tag>-qr.png --clobber
"""
import sys
import qrcode
from qrcode.constants import ERROR_CORRECT_H
from qrcode.image.styledpil import StyledPilImage
from qrcode.image.styles.moduledrawers.pil import RoundedModuleDrawer
from qrcode.image.styles.colormasks import SolidFillColorMask
from PIL import Image, ImageDraw, ImageFont

REPO = "Wilsons-Navid/Capstone-Project"

# Earth palette, consistent with the app and the README diagrams
CREAM   = (251, 247, 241)
BROWN   = (62, 43, 32)
GOLD    = (200, 133, 26)
GREEN   = (46, 125, 52)
MUTED   = (122, 110, 98)
BORDER  = (230, 220, 205)
WHITE   = (255, 255, 255)


def _font(path: str, size: int):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def _centered(draw, cx, y, text, font, fill):
    l, t, r, b = draw.textbbox((0, 0), text, font=font)
    draw.text((cx - (r - l) / 2, y), text, font=font, fill=fill)
    return b - t


def build_card(tag: str, url: str, out: str) -> Image.Image:
    # 1. The QR itself: rounded modules in earth brown on white.
    qr = qrcode.QRCode(error_correction=ERROR_CORRECT_H, box_size=12, border=2)
    qr.add_data(url)
    qr.make(fit=True)
    qr_img = qr.make_image(
        image_factory=StyledPilImage,
        module_drawer=RoundedModuleDrawer(radius_ratio=1.0),
        color_mask=SolidFillColorMask(front_color=BROWN, back_color=WHITE),
    ).convert("RGB")

    QR = 560
    qr_img = qr_img.resize((QR, QR), Image.LANCZOS)

    # 2. The card.
    W, H = 820, 1000
    card = Image.new("RGB", (W, H), CREAM)
    d = ImageDraw.Draw(card)

    # rounded border + a gold accent bar across the top
    d.rounded_rectangle([8, 8, W - 8, H - 8], radius=36, outline=BORDER, width=3)
    d.rounded_rectangle([8, 8, W - 8, 70], radius=36, fill=GOLD)
    d.rectangle([8, 40, W - 8, 70], fill=GOLD)

    f_title = _font("C:/Windows/Fonts/arialbd.ttf", 70)
    f_sub   = _font("C:/Windows/Fonts/arial.ttf", 30)
    f_cap   = _font("C:/Windows/Fonts/arialbd.ttf", 40)
    f_foot  = _font("C:/Windows/Fonts/arial.ttf", 28)

    cx = W // 2
    _centered(d, cx, 110, "Rethicsec", f_title, BROWN)
    _centered(d, cx, 196, "AI scam detection for Africa", f_sub, MUTED)

    # white tile behind the QR for crisp contrast
    tile = QR + 56
    tx, ty = cx - tile // 2, 260
    d.rounded_rectangle([tx, ty, tx + tile, ty + tile], radius=28,
                        fill=WHITE, outline=BORDER, width=2)
    card.paste(qr_img, (cx - QR // 2, ty + 28))

    # caption + footer
    cap_y = ty + tile + 28
    _centered(d, cx, cap_y, "Scan to download the Android app", f_cap, BROWN)

    # a small green Android dot + footer line
    foot = f"Android device required   .   {tag}"
    _centered(d, cx, cap_y + 64, foot, f_foot, MUTED)

    card.save(out)
    return card


def main(tag: str) -> None:
    url = f"https://github.com/{REPO}/releases/download/{tag}/rethicsec-{tag}.apk"
    out = f"docs/assets/rethicsec-{tag}-qr.png"
    img = build_card(tag, url, out)
    print(f"saved {out} ({img.size[0]}x{img.size[1]}) -> {url}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: python scripts/make_release_qr.py <tag>  e.g. v1.0.11")
    main(sys.argv[1])
