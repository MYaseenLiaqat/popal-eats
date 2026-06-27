"""Download royalty-free Pexels food photos and save optimized WebP assets."""

from __future__ import annotations

import io
import urllib.request
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "images" / "cuisines"
OUT.mkdir(parents=True, exist_ok=True)

# Pexels License — free for commercial use, no attribution required.
PHOTOS: dict[str, str] = {
    "pakistani": "https://images.pexels.com/photos/1624487/pexels-photo-1624487.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "afghan": "https://images.pexels.com/photos/2338407/pexels-photo-2338407.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "turkish": "https://images.pexels.com/photos/3298683/pexels-photo-3298683.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "arabic": "https://images.pexels.com/photos/3601109/pexels-photo-3601109.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "chinese": "https://images.pexels.com/photos/1907248/pexels-photo-1907248.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "italian": "https://images.pexels.com/photos/2147491/pexels-photo-2147491.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "american": "https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "indian": "https://images.pexels.com/photos/2474661/pexels-photo-2474661.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "thai": "https://images.pexels.com/photos/842614/pexels-photo-842614.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "japanese": "https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "korean": "https://images.pexels.com/photos/842571/pexels-photo-842571.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "mexican": "https://images.pexels.com/photos/2092507/pexels-photo-2092507.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "fast_food": "https://images.pexels.com/photos/1630315/pexels-photo-1630315.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "seafood": "https://images.pexels.com/photos/566345/pexels-photo-566345.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "vegetarian": "https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
    "desserts": "https://images.pexels.com/photos/291528/pexels-photo-291528.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop",
}

HEADERS = {"User-Agent": "PopalEatsAssetBot/1.0"}


def main() -> None:
    for key, url in PHOTOS.items():
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
        img = Image.open(io.BytesIO(data)).convert("RGB")
        img = img.resize((640, 640), Image.Resampling.LANCZOS)
        out = OUT / f"{key}.webp"
        quality = 88
        while quality >= 60:
            buf = io.BytesIO()
            img.save(buf, format="WEBP", quality=quality, method=6)
            size = buf.tell()
            if size <= 350_000 or quality == 60:
                out.write_bytes(buf.getvalue())
                print(f"{key}.webp  {size // 1024}KB  q={quality}")
                break
            quality -= 4


if __name__ == "__main__":
    main()
