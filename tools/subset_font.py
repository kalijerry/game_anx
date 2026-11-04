"""Build the bundled UI font: a subset of Noto Sans SC that holds every character the game uses.

Web and mobile builds have no system Chinese font, so the game ships this file.
Re-run after adding new text:

    pip install fonttools
    python tools/subset_font.py path/to/NotoSansSC[wght].ttf

Source font: https://github.com/google/fonts/tree/main/ofl/notosanssc (SIL Open Font License 1.1).
"""
import pathlib
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "fonts" / "anx_ui.ttf"
SOURCES = ["data", "scripts"]
WEIGHT = 500  # the source is a variable font; pin one weight so text is not drawn hairline-thin


def used_characters() -> str:
    chars = {chr(c) for c in range(32, 127)}  # all printable ASCII, for the byte readout
    chars |= set("·：，。！？、（）《》“”‘’…—←→")
    for folder in SOURCES:
        for path in (ROOT / folder).rglob("*.gd"):
            chars |= set(path.read_text(encoding="utf-8"))
    return "".join(sorted(c for c in chars if c.isprintable()))


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    text = used_characters()
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    font = TTFont(sys.argv[1], lazy=False)
    if "fvar" in font:
        font = instancer.instantiateVariableFont(font, {"wght": WEIGHT})
    sub = subset.Subsetter(options)
    sub.populate(text=text)
    sub.subset(font)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    subset.save_font(font, str(OUT), options)
    print(f"{len(text)} characters -> {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
