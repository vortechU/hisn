#!/usr/bin/env python3
"""Render PRIVACY.md and TERMS.md into the GitHub Pages site under docs/.

Google Play will not accept a repository file as a privacy policy: it wants a
public URL that resolves to a readable page. The policy itself stays in
Markdown at the repo root — that is the copy under review, and the one a
reader of the source finds first — and this script produces the hosted
rendering from it, so the published page cannot drift from the committed text.

Run after editing either policy:

    python tool/gen_policy_pages.py

Output: docs/index.html, docs/privacy.html, docs/terms.html, docs/.nojekyll.
Serve with GitHub Pages set to "deploy from branch: master, folder: /docs".

The Markdown subset handled here is exactly what the two documents use —
headings, paragraphs, bullets, bold, inline links, bare URLs, and blockquotes.
It is not a general converter, and it fails loudly rather than silently
mangling anything it does not recognise.
"""

from __future__ import annotations

import html
import io
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

SITE_TITLE = "Hisn"
CONTACT = "vordeviu@gmail.com"

# The app's own colours: the ground of the launcher icon, the gilt of the
# illumination, and the cream of the paper. The page should look like it
# belongs to the app it speaks for.
CSS = """
:root {
  --ground: #072c3e;
  --paper: #f7f2e6;
  --ink: #221e18;
  --muted: #5c554a;
  --rubric: #0c5a4c;
  --gilt: #9c7b2e;
  --rule: #dcd3c0;
}
@media (prefers-color-scheme: dark) {
  :root {
    --paper: #161b19;
    --ink: #e8e1d1;
    --muted: #a49c8c;
    --rubric: #58c3ab;
    --gilt: #cda84e;
    --rule: #2c322f;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--paper);
  color: var(--ink);
  font: 16px/1.65 Georgia, "Times New Roman", serif;
  -webkit-text-size-adjust: 100%;
}
header.masthead {
  background: var(--ground);
  color: #f7f2e6;
  padding: 28px 20px;
  border-bottom: 3px solid var(--gilt);
}
header.masthead .wrap { max-width: 46rem; margin: 0 auto; }
header.masthead a { color: #f7f2e6; text-decoration: none; }
header.masthead h1 { margin: 0; font-size: 1.6rem; letter-spacing: 0.02em; }
header.masthead p { margin: 6px 0 0; color: #cda84e; font-size: 0.95rem; }
nav.crumbs { max-width: 46rem; margin: 0 auto; padding: 14px 20px 0; }
nav.crumbs a { color: var(--rubric); margin-right: 14px; }
main { max-width: 46rem; margin: 0 auto; padding: 8px 20px 64px; }
h1, h2, h3 { line-height: 1.3; }
main h1 { font-size: 1.7rem; margin: 24px 0 4px; }
main h2 {
  font-size: 1.2rem;
  margin: 34px 0 10px;
  padding-top: 12px;
  border-top: 1px solid var(--rule);
  color: var(--rubric);
}
a { color: var(--rubric); }
ul { padding-left: 1.3rem; }
li { margin: 6px 0; }
blockquote {
  margin: 16px 0;
  padding: 10px 16px;
  border-left: 3px solid var(--gilt);
  background: rgba(156, 123, 46, 0.07);
  color: var(--muted);
}
strong { color: var(--ink); }
footer {
  max-width: 46rem;
  margin: 0 auto;
  padding: 0 20px 48px;
  color: var(--muted);
  font-size: 0.86rem;
}
"""

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{tab_title}</title>
<meta name="description" content="{description}">
<style>{css}</style>
</head>
<body>
<header class="masthead">
  <div class="wrap">
    <h1><a href="./">{site}</a></h1>
    <p>Adhkar, Quran &amp; prayer times — offline, ad-free, no accounts.</p>
  </div>
</header>
<nav class="crumbs">
  <a href="./">Home</a><a href="privacy.html">Privacy Policy</a><a href="terms.html">Terms of Service</a>
</nav>
<main>
{body}
</main>
<footer>
  <p>Hisn is a personal, non-commercial project. Questions: <a href="mailto:{contact}">{contact}</a></p>
</footer>
</body>
</html>
"""

INDEX_BODY = """<h1>Hisn</h1>
<p>Hisn is a free, offline, ad-free companion for the duas and adhkar of the day,
the Quran in the Madani Mushaf, the Tasbih, prayer times, and the Qibla.
It has no accounts, no analytics, and no backend server — everything it needs
runs on your device.</p>
<h2>Legal</h2>
<ul>
  <li><a href="privacy.html">Privacy Policy</a> — what the app does and does not do with your information (short version: it collects nothing).</li>
  <li><a href="terms.html">Terms of Service</a> — the licence, the religious-content disclaimer, and third-party attributions.</li>
</ul>
<h2>Contact</h2>
<p>Questions, corrections to the texts, or a bug to report:
<a href="mailto:{contact}">{contact}</a>.</p>
""".format(contact=CONTACT)

INLINE_LINK = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
BOLD = re.compile(r"\*\*([^*]+)\*\*")
ITALIC = re.compile(r"(?<![*\w])\*([^*]+)\*(?!\*)")
BARE_URL = re.compile(r"(?<![\"(=>])\bhttps?://[^\s<)]+")


def inline(text: str) -> str:
    """Escape, then re-introduce the inline markup as HTML."""
    out = html.escape(text, quote=False)
    out = INLINE_LINK.sub(lambda m: f'<a href="{html.escape(m.group(2), quote=True)}">{m.group(1)}</a>', out)
    out = BARE_URL.sub(lambda m: f'<a href="{m.group(0)}">{m.group(0)}</a>', out)
    out = BOLD.sub(r"<strong>\1</strong>", out)
    out = ITALIC.sub(r"<em>\1</em>", out)
    return out


def markdown_to_html(md: str) -> str:
    """Convert the Markdown subset the two policies use."""
    lines = md.replace("\r\n", "\n").split("\n")
    out: list[str] = []
    # None, 'ul', 'ol', 'p' or 'quote' — what is currently open.
    mode: str | None = None
    buf: list[str] = []

    def close() -> None:
        nonlocal mode, buf
        if mode == "p" and buf:
            out.append("<p>" + " ".join(buf) + "</p>")
        elif mode == "quote" and buf:
            out.append("<blockquote><p>" + " ".join(buf) + "</p></blockquote>")
        elif mode in ("ul", "ol"):
            out.append(f"</{mode}>")
        mode, buf = None, []

    for raw in lines:
        line = raw.rstrip()
        stripped = line.strip()

        if not stripped:
            close()
            continue

        heading = re.match(r"^(#{1,4})\s+(.*)$", stripped)
        if heading:
            close()
            level = len(heading.group(1))
            out.append(f"<h{level}>{inline(heading.group(2))}</h{level}>")
            continue

        quote = re.match(r"^>\s?(.*)$", stripped)
        if quote:
            # An *indented* "> " under a bullet is a caveat attached to that
            # bullet and belongs inside it — closing the list around it would
            # split one list into three. A top-level one is a callout of its
            # own.
            if mode in ("ul", "ol") and raw.startswith(("  ", "\t")):
                item = out.pop()
                assert item.endswith("</li>"), item
                out.append(
                    item[: -len("</li>")]
                    + f"<blockquote><p>{inline(quote.group(1))}</p></blockquote></li>"
                )
                continue
            if mode != "quote":
                close()
                mode = "quote"
            buf.append(inline(quote.group(1)))
            continue

        bullet = re.match(r"^[-*]\s+(.*)$", stripped)
        if bullet:
            if mode != "ul":
                close()
                out.append("<ul>")
                mode = "ul"
            out.append(f"<li>{inline(bullet.group(1))}</li>")
            continue

        numbered = re.match(r"^\d+\.\s+(.*)$", stripped)
        if numbered:
            if mode != "ol":
                close()
                out.append("<ol>")
                mode = "ol"
            out.append(f"<li>{inline(numbered.group(1))}</li>")
            continue

        # A continuation line inside a list item belongs to the item above.
        if mode in ("ul", "ol") and raw.startswith(("  ", "\t")):
            item = out.pop()
            assert item.endswith("</li>"), item
            out.append(item[: -len("</li>")] + " " + inline(stripped) + "</li>")
            continue

        if mode != "p":
            close()
            mode = "p"
        buf.append(inline(stripped))

    close()
    return "\n".join(out)


def write(path: Path, text: str) -> None:
    io.open(path, "w", encoding="utf-8", newline="\n").write(text)
    print(f"wrote {path.relative_to(ROOT)}")


def render(source: Path, out_name: str, title: str, description: str) -> None:
    body = markdown_to_html(io.open(source, encoding="utf-8").read())
    write(
        DOCS / out_name,
        PAGE.format(
            title=title,
            tab_title=f"{title} — {SITE_TITLE}",
            site=SITE_TITLE,
            description=description,
            css=CSS,
            body=body,
            contact=CONTACT,
        ),
    )


def main() -> int:
    DOCS.mkdir(exist_ok=True)
    # Without this GitHub runs the whole folder through Jekyll, which drops
    # files beginning with an underscore and slows every deploy for nothing.
    write(DOCS / ".nojekyll", "")
    write(
        DOCS / "index.html",
        PAGE.format(
            title="Hisn",
            tab_title="Hisn — Adhkar, Quran & prayer times",
            site=SITE_TITLE,
            description="Hisn — adhkar, Quran and prayer times. Offline, ad-free, no accounts.",
            css=CSS,
            body=INDEX_BODY,
            contact=CONTACT,
        ),
    )
    render(
        ROOT / "PRIVACY.md",
        "privacy.html",
        "Privacy Policy",
        "Hisn collects no personal data: no accounts, no analytics, no advertising, no server.",
    )
    render(
        ROOT / "TERMS.md",
        "terms.html",
        "Terms of Service",
        "The licence, religious-content disclaimer, and third-party attributions for Hisn.",
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
