from __future__ import annotations

import html
import io
import ipaddress
import re
import socket
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

from app.models import DocumentExtraction


class _VisibleTextParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self.hidden = 0

    def handle_starttag(self, tag: str, attrs):
        tag = tag.lower()
        if tag in {"script", "style", "noscript"}:
            self.hidden += 1
        elif tag in {"p", "br", "div", "li", "h1", "h2", "h3", "tr"}:
            self.parts.append("\n")

    def handle_endtag(self, tag: str):
        tag = tag.lower()
        if tag in {"script", "style", "noscript"} and self.hidden:
            self.hidden -= 1
        elif tag in {"p", "div", "li", "h1", "h2", "h3", "tr"}:
            self.parts.append("\n")

    def handle_data(self, data: str):
        if not self.hidden:
            self.parts.append(data)


def html_to_text(source: str) -> str:
    parser = _VisibleTextParser()
    parser.feed(source)
    text = "".join(parser.parts)
    return "\n".join(
        line for line in (re.sub(r"\s+", " ", raw).strip() for raw in text.splitlines()) if line
    )


def extract_document(filename: str, data: bytes, max_bytes: int) -> DocumentExtraction:
    if not data:
        raise ValueError("The uploaded file is empty")
    if len(data) > max_bytes:
        raise ValueError(f"The uploaded file exceeds the {max_bytes // (1024 * 1024)} MB limit")
    suffix = Path(filename).suffix.lower()
    warnings: list[str] = []

    if suffix in {".txt", ".md"}:
        text = data.decode("utf-8", errors="replace")
    elif suffix in {".html", ".htm"}:
        text = html_to_text(data.decode("utf-8", errors="replace"))
    elif suffix == ".rtf":
        raw = data.decode("utf-8", errors="replace")
        text = re.sub(r"\\'[0-9a-fA-F]{2}|\\[a-zA-Z]+-?\d* ?|[{}]", "", raw)
        warnings.append("RTF extraction is best-effort; review the imported text.")
    elif suffix == ".docx":
        try:
            from docx import Document
        except ImportError as exc:
            raise ValueError("DOCX support is not installed on the server") from exc
        doc = Document(io.BytesIO(data))
        parts = [paragraph.text for paragraph in doc.paragraphs if paragraph.text.strip()]
        for table in doc.tables:
            for row in table.rows:
                parts.extend(cell.text for cell in row.cells if cell.text.strip())
        text = "\n".join(parts)
    elif suffix == ".pdf":
        try:
            from pypdf import PdfReader
        except ImportError as exc:
            raise ValueError("PDF support is not installed on the server") from exc
        reader = PdfReader(io.BytesIO(data))
        text = "\n".join(page.extract_text() or "" for page in reader.pages)
        if not text.strip():
            warnings.append("No selectable PDF text was found; this document may require OCR.")
    else:
        raise ValueError("Supported files are TXT, MD, HTML, RTF, DOCX, and PDF")

    return DocumentExtraction(filename=Path(filename).name, text=text.strip(), warnings=warnings)


class _SafeRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        _validate_public_url(newurl)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def extract_public_url(url: str, max_bytes: int = 2_000_000) -> DocumentExtraction:
    _validate_public_url(url)
    opener = urllib.request.build_opener(_SafeRedirectHandler())
    request = urllib.request.Request(url, headers={"User-Agent": "ApplyReadyVets/0.5"})
    try:
        with opener.open(request, timeout=20) as response:
            # Re-validate the effective URL in addition to checking every
            # redirect before urllib follows it.
            _validate_public_url(response.geturl())
            content = response.read(max_bytes + 1)
            if len(content) > max_bytes:
                raise ValueError("The job page exceeds the 2 MB extraction limit")
            content_type = response.headers.get_content_type()
    except urllib.error.URLError as exc:
        raise ValueError(f"Unable to retrieve the job URL: {exc.reason}") from exc
    decoded = content.decode("utf-8", errors="replace")
    text = html_to_text(decoded) if content_type == "text/html" or "<html" in decoded[:1000].lower() else decoded
    return DocumentExtraction(filename=urllib.parse.urlparse(url).netloc, text=html.unescape(text).strip())


def _validate_public_url(url: str) -> None:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        raise ValueError("Only public HTTP and HTTPS job URLs are supported")
    if parsed.username or parsed.password:
        raise ValueError("URLs containing credentials are not supported")
    try:
        default_port = 443 if parsed.scheme == "https" else 80
        addresses = {
            item[4][0]
            for item in socket.getaddrinfo(
                parsed.hostname,
                parsed.port or default_port,
                type=socket.SOCK_STREAM,
            )
        }
    except socket.gaierror as exc:
        raise ValueError("The job URL host could not be resolved") from exc
    for address in addresses:
        ip = ipaddress.ip_address(address.split("%", 1)[0])
        if not ip.is_global:
            raise ValueError("Only globally routable public network URLs are allowed")
