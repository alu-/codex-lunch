#!/usr/bin/env python3
"""
Convert HTML or text files into cleaned plain text for AI parsing.
"""

from __future__ import annotations

import argparse
import html
import re
from html.parser import HTMLParser
from pathlib import Path


BLOCK_TAGS = {
    "address",
    "article",
    "aside",
    "blockquote",
    "br",
    "div",
    "figcaption",
    "footer",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "header",
    "hr",
    "li",
    "main",
    "nav",
    "ol",
    "p",
    "section",
    "table",
    "td",
    "th",
    "tr",
    "ul",
}

SKIP_TAGS = {"script", "style", "svg", "noscript", "template"}


class TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []
        self.skip_depth = 0

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag in SKIP_TAGS:
            self.skip_depth += 1
            return
        if self.skip_depth == 0 and tag in BLOCK_TAGS:
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in SKIP_TAGS:
            if self.skip_depth > 0:
                self.skip_depth -= 1
            return
        if self.skip_depth == 0 and tag in BLOCK_TAGS:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if self.skip_depth == 0:
            self.parts.append(data)

    def get_text(self) -> str:
        return "".join(self.parts)


def normalize_text(raw: str) -> str:
    parser = TextExtractor()
    parser.feed(raw)
    text = html.unescape(parser.get_text())
    text = text.replace("\r", "\n")
    text = re.sub(r"[ \t\f\v]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text


def clean_lines(text: str) -> list[str]:
    lines: list[str] = []
    seen: set[str] = set()

    for raw_line in text.splitlines():
        line = re.sub(r"\s+", " ", raw_line).strip()
        if not line:
            continue
        if len(line) < 2:
            continue
        key = line.casefold()
        if key in seen:
            continue
        seen.add(key)
        lines.append(line)

    return lines


def process_file(path: Path) -> str:
    raw = path.read_text(encoding="utf-8", errors="ignore")
    text = normalize_text(raw)
    lines = clean_lines(text)

    title = f"== {path} =="
    if not lines:
        return f"{title}\n(no text extracted)"
    return f"{title}\n" + "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", help="HTML or text files to inspect")
    args = parser.parse_args()

    results = []
    for raw_path in args.paths:
        path = Path(raw_path)
        if not path.exists():
            results.append(f"== {path} ==\n(file not found)")
            continue
        results.append(process_file(path))

    print("\n\n".join(results))


if __name__ == "__main__":
    main()
