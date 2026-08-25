#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

function usage() {
  echo "Usage: check-source-policy.command [--require-manifest] <directory-or-zip>"
  echo "       check-source-policy.command --self-test"
  echo
  echo "This checks a staged source directory or ZIP. The live project is expected"
  echo "to contain private local files such as backend/.env, so package-source.command"
  echo "checks a clean staging copy instead of treating the live project as shareable."
}

MODE="scan"
REQUIRE_MANIFEST="0"
TARGET=""

while (( $# > 0 )); do
  case "$1" in
    --self-test)
      MODE="self-test"
      shift
      ;;
    --require-manifest)
      REQUIRE_MANIFEST="1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      usage
      exit 2
      ;;
    *)
      if [[ -n "$TARGET" ]]; then
        echo "Only one directory or ZIP may be checked."
        usage
        exit 2
      fi
      TARGET="$1"
      shift
      ;;
  esac
done

if [[ "$MODE" == "scan" && -z "$TARGET" ]]; then
  echo "A staged source directory or ZIP is required."
  usage
  exit 2
fi

/usr/bin/python3 - "$MODE" "$TARGET" "$REQUIRE_MANIFEST" <<'PY'
from __future__ import annotations

import hashlib
import os
import re
import stat
import sys
import tempfile
import zipfile
from pathlib import Path, PurePosixPath


MODE = sys.argv[1]
TARGET = Path(sys.argv[2]).expanduser() if sys.argv[2] else None
REQUIRE_MANIFEST = sys.argv[3] == "1"
MANIFEST_NAME = "SOURCE_MANIFEST.sha256"
MAX_FILES = 20_000
MAX_FILE_BYTES = 25 * 1024 * 1024
MAX_TOTAL_BYTES = 250 * 1024 * 1024
MAX_REPORTED_VIOLATIONS = 50

DENIED_COMPONENTS = {
    ".automation",
    ".build",
    ".git",
    ".pytest_cache",
    ".ruff_cache",
    ".venv",
    "__macosx",
    "__pycache__",
    "attachments",
    "automation",
    "build",
    "deriveddata",
    "dist",
    "downloads",
    "exports",
    "logs",
    "private",
    "tmp",
    "uploads",
    "xcuserdata",
}
DENIED_EXTENSIONS = {
    ".7z",
    ".app",
    ".cer",
    ".db",
    ".der",
    ".doc",
    ".docx",
    ".dylib",
    ".dSYM".lower(),
    ".gz",
    ".ipa",
    ".key",
    ".log",
    ".mobileprovision",
    ".o",
    ".odt",
    ".p12",
    ".p8",
    ".pages",
    ".pdf",
    ".pem",
    ".pid",
    ".ppt",
    ".pptx",
    ".pyc",
    ".rtf",
    ".sqlite",
    ".sqlite3",
    ".swiftmodule",
    ".tar",
    ".tgz",
    ".xls",
    ".xlsx",
    ".zip",
}
ALLOWED_BINARY_EXTENSIONS = {
    ".gif",
    ".heic",
    ".ico",
    ".jpeg",
    ".jpg",
    ".otf",
    ".png",
    ".ttf",
    ".webp",
    ".woff",
    ".woff2",
}
DENIED_EXACT_NAMES = {
    "credentials.json",
    "id_ed25519",
    "id_rsa",
    "secrets.json",
}
PLACEHOLDER_VALUES = {
    "change_me",
    "changeme",
    "example",
    "placeholder",
    "replace_me",
    "your_api_key",
    "your_server_side_key",
}
STRONG_SECRET_PATTERNS = [
    ("private key", re.compile(r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----")),
    ("OpenAI-style key", re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b")),
    ("AWS access key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("GitHub token", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}\b")),
    ("Google API key", re.compile(r"\bAIza[0-9A-Za-z_-]{30,}\b")),
    ("Slack token", re.compile(r"\bxox[baprs]-[0-9A-Za-z-]{20,}\b")),
]
ENV_ASSIGNMENT = re.compile(
    r"(?m)^[ \t]*(OPENAI_API_KEY|HOGUE_API_TOKEN|AWS_SECRET_ACCESS_KEY|"
    r"AZURE_OPENAI_API_KEY|GOOGLE_API_KEY|GITHUB_TOKEN)[ \t]*=[ \t]*['\"]?([^'\"\s#]+)"
)
JSON_SECRET = re.compile(
    r"(?i)\"(?:api_key|private_key|client_secret|access_token)\"\s*:\s*\"([^\"]{12,})\""
)
MANIFEST_LINE = re.compile(r"^([0-9a-f]{64})  (.+)$")


def normalized_relative(value: str) -> str:
    normalized = value.replace("\\", "/")
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized


def path_violation(relative: str) -> str | None:
    relative = normalized_relative(relative)
    if not relative:
        return None
    if any(ord(character) < 32 for character in relative):
        return "path contains a control character"
    path = PurePosixPath(relative)
    if path.is_absolute() or ".." in path.parts:
        return "path is absolute or escapes its package root"
    lowered_parts = [part.casefold() for part in path.parts]
    for part in lowered_parts:
        if part in DENIED_COMPONENTS:
            return f"contains denied directory '{part}'"
        if part.endswith(".egg-info"):
            return "contains generated Python package metadata"
        if part.endswith(".xcarchive"):
            return "contains an Xcode archive"
    name = path.name.casefold()
    if name == ".env" or (name.startswith(".env.") and name != ".env.example"):
        return "contains a private environment file"
    if name in DENIED_EXACT_NAMES or name.startswith("secrets."):
        return "contains a credential or secret file"
    suffix = PurePosixPath(name).suffix.casefold()
    if suffix in DENIED_EXTENSIONS:
        return f"contains denied file type '{suffix}'"
    if name == ".ds_store" or name.startswith("._") or name.endswith(".xcuserstate"):
        return "contains local macOS or Xcode metadata"
    return None


def placeholder(value: str) -> bool:
    normalized = value.strip().strip("'\"").casefold()
    return (
        not normalized
        or normalized in PLACEHOLDER_VALUES
        or normalized.startswith("${")
        or normalized.startswith("<")
        or normalized.endswith("_here")
    )


def content_violations(relative: str, data: bytes) -> list[str]:
    if len(data) > MAX_FILE_BYTES:
        return [f"file exceeds the {MAX_FILE_BYTES // (1024 * 1024)} MB source limit"]
    suffix = PurePosixPath(relative).suffix.casefold()
    if suffix in ALLOWED_BINARY_EXTENSIONS:
        return []
    if b"\x00" in data[:8192]:
        return ["unexpected binary file is not on the source-asset allowlist"]
    text = data.decode("utf-8", errors="replace")
    findings: list[str] = []
    for label, pattern in STRONG_SECRET_PATTERNS:
        if pattern.search(text):
            findings.append(f"contains a possible {label}")
    for match in ENV_ASSIGNMENT.finditer(text):
        if not placeholder(match.group(2)):
            findings.append(f"contains a populated {match.group(1)} assignment")
    for match in JSON_SECRET.finditer(text):
        if not placeholder(match.group(1)):
            findings.append("contains a populated JSON credential field")
    return findings


def parse_manifest(data: bytes) -> tuple[dict[str, str], list[str]]:
    expected: dict[str, str] = {}
    problems: list[str] = []
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return {}, ["manifest is not UTF-8 text"]
    for number, line in enumerate(text.splitlines(), start=1):
        match = MANIFEST_LINE.fullmatch(line)
        if not match:
            problems.append(f"manifest line {number} has an invalid format")
            continue
        digest, relative = match.groups()
        relative = normalized_relative(relative)
        if relative == MANIFEST_NAME:
            problems.append("manifest must not include its own checksum")
        elif relative in expected:
            problems.append(f"manifest contains duplicate path '{relative}'")
        else:
            expected[relative] = digest
    return expected, problems


def verify_manifest(
    actual: dict[str, str],
    manifest_data: bytes | None,
    require_manifest: bool,
) -> list[str]:
    if manifest_data is None:
        return ["required SHA-256 manifest is missing"] if require_manifest else []
    expected, problems = parse_manifest(manifest_data)
    missing = sorted(set(actual) - set(expected))
    extra = sorted(set(expected) - set(actual))
    changed = sorted(path for path in set(actual) & set(expected) if actual[path] != expected[path])
    problems.extend(f"manifest is missing '{path}'" for path in missing[:10])
    problems.extend(f"manifest names absent file '{path}'" for path in extra[:10])
    problems.extend(f"checksum mismatch for '{path}'" for path in changed[:10])
    if len(missing) > 10 or len(extra) > 10 or len(changed) > 10:
        problems.append("additional manifest mismatches were omitted from this report")
    return problems


def scan_directory(root: Path, require_manifest: bool) -> tuple[list[str], int, int]:
    violations: list[str] = []
    actual: dict[str, str] = {}
    manifest_data: bytes | None = None
    file_count = 0
    total_bytes = 0

    if not root.is_dir():
        return ([f"{root}: directory does not exist"], 0, 0)

    for current, dirnames, filenames in os.walk(root, followlinks=False):
        current_path = Path(current)
        kept_directories: list[str] = []
        for dirname in sorted(dirnames):
            path = current_path / dirname
            relative = path.relative_to(root).as_posix()
            reason = path_violation(relative)
            if path.is_symlink():
                violations.append(f"{relative}: symbolic links are not allowed")
            elif reason:
                violations.append(f"{relative}: {reason}")
            else:
                kept_directories.append(dirname)
        dirnames[:] = kept_directories

        for filename in sorted(filenames):
            path = current_path / filename
            relative = path.relative_to(root).as_posix()
            file_count += 1
            if file_count > MAX_FILES:
                violations.append(f"package exceeds the {MAX_FILES} file limit")
                return violations, file_count, total_bytes
            if path.is_symlink():
                violations.append(f"{relative}: symbolic links are not allowed")
                continue
            reason = path_violation(relative)
            if reason:
                violations.append(f"{relative}: {reason}")
                continue
            try:
                data = path.read_bytes()
            except OSError as exc:
                violations.append(f"{relative}: file could not be read ({type(exc).__name__})")
                continue
            total_bytes += len(data)
            if total_bytes > MAX_TOTAL_BYTES:
                violations.append(
                    f"package exceeds the {MAX_TOTAL_BYTES // (1024 * 1024)} MB uncompressed limit"
                )
                return violations, file_count, total_bytes
            if relative == MANIFEST_NAME:
                manifest_data = data
                continue
            actual[relative] = hashlib.sha256(data).hexdigest()
            violations.extend(f"{relative}: {finding}" for finding in content_violations(relative, data))

    violations.extend(verify_manifest(actual, manifest_data, require_manifest))
    return violations, file_count, total_bytes


def scan_zip(path: Path, require_manifest: bool) -> tuple[list[str], int, int]:
    violations: list[str] = []
    actual_with_prefix: dict[str, str] = {}
    manifests: list[tuple[str, bytes]] = []
    total_bytes = 0

    if not path.is_file():
        return ([f"{path}: ZIP does not exist"], 0, 0)
    try:
        archive = zipfile.ZipFile(path)
    except (OSError, zipfile.BadZipFile):
        return ([f"{path}: file is not a readable ZIP"], 0, 0)

    with archive:
        infos = archive.infolist()
        seen_paths: set[str] = set()
        if len(infos) > MAX_FILES:
            violations.append(f"archive exceeds the {MAX_FILES} member limit")
        for info in infos[: MAX_FILES + 1]:
            relative = normalized_relative(info.filename)
            if relative in seen_paths:
                violations.append(f"{relative}: archive contains a duplicate member path")
                continue
            seen_paths.add(relative)
            reason = path_violation(relative.rstrip("/"))
            if reason:
                violations.append(f"{relative}: {reason}")
                continue
            unix_mode = (info.external_attr >> 16) & 0o170000
            if unix_mode == stat.S_IFLNK:
                violations.append(f"{relative}: symbolic links are not allowed")
                continue
            if info.is_dir():
                continue
            if info.file_size > MAX_FILE_BYTES:
                violations.append(
                    f"{relative}: file exceeds the {MAX_FILE_BYTES // (1024 * 1024)} MB source limit"
                )
                continue
            if info.file_size > 1024 * 1024 and info.compress_size > 0:
                if info.file_size / info.compress_size > 200:
                    violations.append(f"{relative}: suspicious compression ratio")
                    continue
            total_bytes += info.file_size
            if total_bytes > MAX_TOTAL_BYTES:
                violations.append(
                    f"archive exceeds the {MAX_TOTAL_BYTES // (1024 * 1024)} MB uncompressed limit"
                )
                break
            try:
                data = archive.read(info)
            except (OSError, RuntimeError, zipfile.BadZipFile):
                violations.append(f"{relative}: archive member could not be read")
                continue
            if PurePosixPath(relative).name == MANIFEST_NAME:
                manifests.append((relative, data))
                continue
            actual_with_prefix[relative] = hashlib.sha256(data).hexdigest()
            violations.extend(f"{relative}: {finding}" for finding in content_violations(relative, data))

    if len(manifests) > 1:
        violations.append("archive contains more than one SHA-256 manifest")
    manifest_data = manifests[0][1] if manifests else None
    if manifests:
        manifest_parent = PurePosixPath(manifests[0][0]).parent.as_posix()
        prefix = "" if manifest_parent == "." else f"{manifest_parent}/"
        actual: dict[str, str] = {}
        for relative, digest in actual_with_prefix.items():
            if prefix and not relative.startswith(prefix):
                violations.append(f"{relative}: archive member is outside the manifest root")
                continue
            actual[relative[len(prefix):]] = digest
    else:
        actual = actual_with_prefix
    violations.extend(verify_manifest(actual, manifest_data, require_manifest))
    return violations, len(infos) if "infos" in locals() else 0, total_bytes


def run_scan(target: Path, require_manifest: bool) -> tuple[list[str], int, int]:
    if target.is_dir():
        return scan_directory(target, require_manifest)
    return scan_zip(target, require_manifest)


def self_test() -> None:
    with tempfile.TemporaryDirectory(prefix="applyreadyvets-policy-test.") as temporary:
        root = Path(temporary)
        safe = root / "safe"
        safe.mkdir()
        (safe / "README.md").write_text("# Safe source\n", encoding="utf-8")
        (safe / ".env.example").write_text("OPENAI_API_KEY=\n", encoding="utf-8")
        violations, _, _ = scan_directory(safe, require_manifest=False)
        if violations:
            raise RuntimeError(f"safe self-test fixture was rejected: {violations}")

        unsafe = root / "unsafe"
        (unsafe / "backend").mkdir(parents=True)
        (unsafe / "backend" / ".env").write_text(
            "OPENAI_API_KEY=" + "sk-" + "proj-" + "realistic-secret-value-1234567890\n",
            encoding="utf-8",
        )
        violations, _, _ = scan_directory(unsafe, require_manifest=False)
        if not any("environment file" in item for item in violations):
            raise RuntimeError("private environment-file fixture was not rejected")

        leaky = root / "leaky"
        leaky.mkdir()
        (leaky / "notes.md").write_text(
            "HOGUE_API_TOKEN=" + "realistic-local-token-value-1234567890\n",
            encoding="utf-8",
        )
        violations, _, _ = scan_directory(leaky, require_manifest=False)
        if not any("populated HOGUE_API_TOKEN" in item for item in violations):
            raise RuntimeError("populated credential assignment fixture was not rejected")

        generated = root / "generated"
        (generated / "automation" / "Build").mkdir(parents=True)
        (generated / "automation" / "Build" / "App").write_bytes(b"\x00build")
        violations, _, _ = scan_directory(generated, require_manifest=False)
        if not any("denied directory 'automation'" in item for item in violations):
            raise RuntimeError("automation build-output fixture was not rejected")

        tampered = root / "tampered"
        tampered.mkdir()
        (tampered / "README.md").write_text("# Changed after manifest\n", encoding="utf-8")
        (tampered / MANIFEST_NAME).write_text(
            f"{'0' * 64}  README.md\n",
            encoding="utf-8",
        )
        violations, _, _ = scan_directory(tampered, require_manifest=True)
        if not any("checksum mismatch" in item for item in violations):
            raise RuntimeError("tampered manifest fixture was not rejected")

        unsafe_zip = root / "unsafe.zip"
        with zipfile.ZipFile(unsafe_zip, "w") as archive:
            archive.writestr("../escape.txt", "not safe")
            archive.writestr("ApplyReadyVets/tmp/resume.txt", "private document")
        violations, _, _ = scan_zip(unsafe_zip, require_manifest=False)
        if len(violations) < 2:
            raise RuntimeError("unsafe ZIP fixtures were not rejected")
    print(
        "PASS: source-policy self-test rejected private paths, populated credentials, "
        "automation output, manifest tampering, traversal, and unsafe archives."
    )


if MODE == "self-test":
    self_test()
    raise SystemExit(0)

assert TARGET is not None
if TARGET.is_symlink():
    violations, file_count, total_bytes = (
        [f"{TARGET}: top-level symbolic links are not allowed"],
        0,
        0,
    )
else:
    violations, file_count, total_bytes = run_scan(TARGET.resolve(), REQUIRE_MANIFEST)
if violations:
    print(f"FAIL: source policy rejected {TARGET}", file=sys.stderr)
    for violation in violations[:MAX_REPORTED_VIOLATIONS]:
        print(f"  - {violation}", file=sys.stderr)
    if len(violations) > MAX_REPORTED_VIOLATIONS:
        print(
            f"  - {len(violations) - MAX_REPORTED_VIOLATIONS} additional violations omitted",
            file=sys.stderr,
        )
    raise SystemExit(1)

print(
    f"PASS: source policy accepted {TARGET} "
    f"({file_count} files, {total_bytes} uncompressed bytes)."
)
PY
