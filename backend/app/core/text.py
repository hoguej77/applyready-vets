from __future__ import annotations

import re
from collections import Counter


STOPWORDS = {
    "a", "an", "and", "or", "the", "but", "with", "for", "to", "from", "on", "in", "at", "as",
    "by", "of", "be", "is", "are", "was", "were", "will", "would", "can", "could", "that", "this",
    "your", "you", "we", "our", "they", "their", "role", "job", "position", "work", "team", "years",
    "experience", "required", "requirements", "preferred", "must", "have", "including", "responsible",
    "company", "title",
}

CLAIM_QUALIFIER_GROUPS: list[tuple[str, re.Pattern[str]]] = [
    (
        "negation",
        re.compile(
            r"\b(?:no|not|never|without|lack(?:ed|ing|s)?|cannot|can't|couldn't|didn't|"
            r"doesn't|don't|wasn't|weren't)\b|didn[’']t|couldn[’']t|doesn[’']t|don[’']t",
            re.I,
        ),
    ),
    (
        "limited proficiency",
        re.compile(
            r"\b(?:basic|beginner|elementary|foundational|fundamentals|introductory|limited|"
            r"familiarity|exposure)\b",
            re.I,
        ),
    ),
    (
        "training or study",
        re.compile(r"\b(?:training|coursework|course|studied|learning)\b", re.I),
    ),
    (
        "supporting role",
        re.compile(
            r"\b(?:assist(?:ed|ing|s)?|support(?:ed|ing|s)?|help(?:ed|ing|s)?|"
            r"contribut(?:ed|ing|es)|participat(?:ed|ing|es))\b",
            re.I,
        ),
    ),
]

# A skill mentioned only in one of these contexts is not an affirmative claim
# of proficiency. Supporting-role wording still proves some domain exposure, so
# it is preserved for keyword matching while remaining protected during rewrites.
UNASSERTED_SKILL_CONTEXTS = CLAIM_QUALIFIER_GROUPS[:3]


def clean_tokens(text: str) -> list[str]:
    tokens: list[str] = []
    for raw in re.findall(r"[A-Za-z][A-Za-z0-9+#./-]{1,}", text or ""):
        token = raw.strip("./-").lower()
        if len(token) > 1 and token not in STOPWORDS:
            tokens.append(token)
    return tokens


def affirmed_tokens(text: str) -> list[str]:
    tokens: list[str] = []
    for line in normalized_lines(text):
        if any(pattern.search(line) for _label, pattern in UNASSERTED_SKILL_CONTEXTS):
            continue
        tokens.extend(clean_tokens(line))
    return tokens


def missing_claim_qualifier(source: str, proposal: str) -> str | None:
    for label, pattern in CLAIM_QUALIFIER_GROUPS:
        if pattern.search(source) and not pattern.search(proposal):
            return label
    return None


def ranked_keywords(text: str, limit: int = 30) -> list[str]:
    counts = Counter(clean_tokens(text))
    first_seen: dict[str, int] = {}
    for index, token in enumerate(clean_tokens(text)):
        first_seen.setdefault(token, index)
    ordered = sorted(counts, key=lambda token: (-counts[token], first_seen[token], token))
    return ordered[:limit]


def normalized_lines(text: str) -> list[str]:
    result: list[str] = []
    for raw in (text or "").splitlines():
        line = re.sub(r"\s+", " ", raw).strip(" \t•-|")
        if line:
            result.append(line)
    return result


def numbers(text: str) -> set[str]:
    return set(re.findall(r"(?<!\w)(?:\$)?\d+(?:[.,]\d+)*(?:%|[KkMm])?(?!\w)", text or ""))
