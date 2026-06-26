"""Generate a QR code that points to a release's APK download URL.

Usage:
    python scripts/make_release_qr.py v1.0.10

Produces docs/assets/rethicsec-<tag>-qr.png encoding the GitHub release
download URL for rethicsec-<tag>.apk. Scanning it on a phone downloads the APK.
Upload it to the release with:
    gh release upload <tag> docs/assets/rethicsec-<tag>-qr.png --clobber
"""
import sys
import qrcode
from qrcode.constants import ERROR_CORRECT_H

REPO = "Wilsons-Navid/Capstone-Project"


def main(tag: str) -> None:
    url = f"https://github.com/{REPO}/releases/download/{tag}/rethicsec-{tag}.apk"
    qr = qrcode.QRCode(error_correction=ERROR_CORRECT_H, box_size=12, border=4)
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="#2E2A1F", back_color="white")
    out = f"docs/assets/rethicsec-{tag}-qr.png"
    img.save(out)
    print(f"saved {out} ({img.size[0]}x{img.size[1]}) -> {url}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: python scripts/make_release_qr.py <tag>  e.g. v1.0.10")
    main(sys.argv[1])
