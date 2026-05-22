#!/usr/bin/env python3
"""Genera PDFs simples desde Markdown usando solo biblioteca estandar.

El objetivo es reproducibilidad del handoff sin depender de Pandoc,
wkhtmltopdf, Playwright ni librerias externas.
"""

from __future__ import annotations

import re
import textwrap
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent

DOCS = [
    "CODEMON_HANDOFF_COMPLETO",
    "CODEMON_EQUIPO_A_BACKEND_CORE",
    "CODEMON_EQUIPO_B_FRONTEND",
    "CODEMON_EQUIPO_C_DEVOPS_BACKEND_AUX",
    "CODEMON_CHECKLIST_EJECUTIVA",
]

PAGE_WIDTH = 595
PAGE_HEIGHT = 842
LEFT = 46
TOP = 795
LINE_HEIGHT = 14
MAX_LINES = 52
WRAP = 94


def md_to_lines(text: str) -> list[str]:
    lines: list[str] = []
    in_code = False
    for raw in text.splitlines():
        line = raw.rstrip()
        if line.startswith("```"):
            in_code = not in_code
            lines.append("")
            continue
        if not in_code:
            line = re.sub(r"^#{1,6}\s*", "", line)
            line = line.replace("**", "").replace("__", "")
            line = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", line)
            line = line.replace("|", "  |  ")
        prefix = ""
        stripped = line.lstrip()
        if stripped.startswith("- "):
            prefix = "- "
            line = stripped[2:]
        elif re.match(r"^\d+\. ", stripped):
            prefix = stripped.split(" ", 1)[0] + " "
            line = stripped[len(prefix) :]
        if not line:
            lines.append("")
            continue
        width = WRAP - len(prefix)
        wrapped = textwrap.wrap(line, width=width, replace_whitespace=False) or [""]
        for idx, part in enumerate(wrapped):
            lines.append((prefix if idx == 0 else " " * len(prefix)) + part)
    return lines


def paginate(lines: list[str]) -> list[list[str]]:
    pages: list[list[str]] = []
    current: list[str] = []
    for line in lines:
        if len(current) >= MAX_LINES:
            pages.append(current)
            current = []
        current.append(line)
    if current:
        pages.append(current)
    return pages


def esc_pdf(text: str) -> str:
    text = text.encode("latin-1", "replace").decode("latin-1")
    return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def page_stream(lines: list[str], page_number: int, total_pages: int) -> bytes:
    commands = ["BT", "/F1 10 Tf", f"{LEFT} {TOP} Td", "14 TL"]
    for line in lines:
        commands.append(f"({esc_pdf(line)}) Tj")
        commands.append("T*")
    footer = f"Pagina {page_number} de {total_pages}"
    commands.extend([
        "ET",
        "BT",
        "/F1 8 Tf",
        f"{LEFT} 28 Td",
        f"({esc_pdf(footer)}) Tj",
        "ET",
    ])
    return ("\n".join(commands) + "\n").encode("latin-1", "replace")


def build_pdf(title: str, pages: list[list[str]]) -> bytes:
    objects: list[bytes] = []

    def add(obj: bytes) -> int:
        objects.append(obj)
        return len(objects)

    catalog_id = add(b"")
    pages_id = add(b"")
    font_id = add(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")

    page_ids: list[int] = []
    content_ids: list[int] = []
    for idx, page_lines in enumerate(pages, start=1):
        stream = page_stream(page_lines, idx, len(pages))
        content_id = add(
            b"<< /Length " + str(len(stream)).encode("ascii") + b" >>\nstream\n" + stream + b"endstream"
        )
        page_id = add(
            (
                f"<< /Type /Page /Parent {pages_id} 0 R /MediaBox [0 0 {PAGE_WIDTH} {PAGE_HEIGHT}] "
                f"/Resources << /Font << /F1 {font_id} 0 R >> >> "
                f"/Contents {content_id} 0 R >>"
            ).encode("ascii")
        )
        content_ids.append(content_id)
        page_ids.append(page_id)

    kids = " ".join(f"{pid} 0 R" for pid in page_ids)
    objects[catalog_id - 1] = f"<< /Type /Catalog /Pages {pages_id} 0 R >>".encode("ascii")
    objects[pages_id - 1] = f"<< /Type /Pages /Kids [{kids}] /Count {len(page_ids)} >>".encode("ascii")

    info_id = add(
        (
            "<< /Title (" + esc_pdf(title) + ") "
            "/Creator (Codemon handoff generator) >>"
        ).encode("latin-1", "replace")
    )

    output = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = [0]
    for idx, obj in enumerate(objects, start=1):
        offsets.append(len(output))
        output.extend(f"{idx} 0 obj\n".encode("ascii"))
        output.extend(obj)
        output.extend(b"\nendobj\n")
    xref_at = len(output)
    output.extend(f"xref\n0 {len(objects) + 1}\n".encode("ascii"))
    output.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        output.extend(f"{offset:010d} 00000 n \n".encode("ascii"))
    output.extend(
        (
            f"trailer\n<< /Size {len(objects) + 1} /Root {catalog_id} 0 R /Info {info_id} 0 R >>\n"
            f"startxref\n{xref_at}\n%%EOF\n"
        ).encode("ascii")
    )
    return bytes(output)


def main() -> None:
    for doc in DOCS:
        md_path = BASE_DIR / f"{doc}.md"
        pdf_path = BASE_DIR / f"{doc}.pdf"
        text = md_path.read_text(encoding="utf-8")
        lines = md_to_lines(text)
        pages = paginate(lines)
        pdf_path.write_bytes(build_pdf(doc, pages))
        print(f"generado {pdf_path.name} ({len(pages)} paginas)")


if __name__ == "__main__":
    main()

