from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfgen import canvas


ROOT = Path(r"e:\StudioProjects")
SOURCE = ROOT / "LinguaFlow_Updated_Tech_Stack_2026-05-05.md"
OUTPUT = ROOT / "LinguaFlow_Updated_Tech_Stack_2026-05-05.pdf"


def wrap_text(text: str, max_width: float, font_name: str, font_size: int) -> list[str]:
    words = text.split()
    if not words:
        return [""]
    lines: list[str] = []
    current = words[0]
    for word in words[1:]:
        candidate = f"{current} {word}"
        if pdfmetrics.stringWidth(candidate, font_name, font_size) <= max_width:
            current = candidate
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def build_pdf() -> None:
    c = canvas.Canvas(str(OUTPUT), pagesize=A4)
    width, height = A4
    margin_x = 18 * mm
    margin_top = 18 * mm
    margin_bottom = 16 * mm
    usable_width = width - (2 * margin_x)
    y = height - margin_top

    def new_page() -> None:
        nonlocal y
        c.showPage()
        y = height - margin_top

    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    for raw in lines:
        line = raw.rstrip()
        if line.startswith("# "):
            font_name, font_size, leading = "Helvetica-Bold", 15, 20
            text = line[2:].strip()
            if y < margin_bottom + leading:
                new_page()
            c.setFont(font_name, font_size)
            c.drawString(margin_x, y, text)
            y -= leading
            continue
        if line.startswith("## "):
            font_name, font_size, leading = "Helvetica-Bold", 12, 17
            text = line[3:].strip()
            if y < margin_bottom + leading:
                new_page()
            c.setFont(font_name, font_size)
            c.drawString(margin_x, y, text)
            y -= leading
            continue

        if not line:
            y -= 8
            if y < margin_bottom + 14:
                new_page()
            continue

        bullet = line.startswith("- ")
        body = line[2:].strip() if bullet else line
        font_name, font_size, leading = "Helvetica", 10, 14
        wrapped = wrap_text(body, usable_width - (12 if bullet else 0), font_name, font_size)
        for i, chunk in enumerate(wrapped):
            if y < margin_bottom + leading:
                new_page()
            c.setFont(font_name, font_size)
            if bullet and i == 0:
                c.drawString(margin_x, y, "\u2022")
                c.drawString(margin_x + 10, y, chunk)
            else:
                indent = 10 if bullet else 0
                c.drawString(margin_x + indent, y, chunk)
            y -= leading

    c.save()


if __name__ == "__main__":
    build_pdf()
    print(f"Generated: {OUTPUT}")

