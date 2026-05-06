"""Text preprocessing for multilingual scam classification."""
from __future__ import annotations

import re
import unicodedata

URL_RE = re.compile(r"https?://\S+|www\.\S+")
EMAIL_RE = re.compile(r"\b[\w.+-]+@[\w-]+\.[\w.-]+\b")
PHONE_RE = re.compile(r"\+?\d[\d\s().-]{6,}\d")
WHITESPACE_RE = re.compile(r"\s+")


def normalize(text: str) -> str:
    text = unicodedata.normalize("NFKC", text)
    return WHITESPACE_RE.sub(" ", text).strip()


def mask_pii(text: str) -> str:
    text = URL_RE.sub(" <URL> ", text)
    text = EMAIL_RE.sub(" <EMAIL> ", text)
    text = PHONE_RE.sub(" <PHONE> ", text)
    return WHITESPACE_RE.sub(" ", text).strip()


def preprocess(text: str, mask: bool = True) -> str:
    text = normalize(text)
    if mask:
        text = mask_pii(text)
    return text
