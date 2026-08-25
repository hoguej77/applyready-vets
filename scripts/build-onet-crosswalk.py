#!/usr/bin/env python3
"""Build the compact in-app military occupation crosswalk from the official ZIP.

Source ZIP:
https://www.onetcenter.org/dl_files/2019/military_crosswalk.zip

The source field dictionary identifies the service-code namespaces. Only active
records with at least one O*NET-SOC link are included. DoD conversion, OPM, and
National Security Personnel System namespaces are intentionally excluded because
they are not user-entered branch occupation codes.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import zipfile
from pathlib import Path


SOURCE_URL = "https://www.onetcenter.org/dl_files/2019/military_crosswalk.zip"
SOURCE_RELEASE = "August 2024"
CSV_PATH = "military_crosswalk/milx0724.csv"
SERVICE_BRANCH = {
    "A": "army",
    "J": "army",
    "Q": "army",
    "F": "air_force",
    "X": "air_force",
    "Y": "air_force",
    "Z": "air_force",
    "C": "coast_guard",
    "M": "marine_corps",
    "N": "navy",
    "P": "navy",
    "S": "navy",
    "V": "navy",
    "H": "space_force",
    "L": "space_force",
    "O": "space_force",
    "U": "space_force",
}


def build(source_zip: Path) -> dict:
    source_bytes = source_zip.read_bytes()
    grouped: dict[tuple[str, str, str, str], set[tuple[str, str]]] = {}
    source_rows = 0

    with zipfile.ZipFile(io.BytesIO(source_bytes)) as archive:
        with archive.open(CSV_PATH) as source:
            rows = csv.DictReader(io.TextIOWrapper(source, encoding="utf-8-sig"))
            for row in rows:
                source_rows += 1
                branch = SERVICE_BRANCH.get(row["SVC"])
                if branch is None or row["STATUS"] != "A":
                    continue
                occupations = {
                    (row[f"ONET{index}"].strip(), row[f"ONET{index}_TITLE"].strip())
                    for index in range(1, 5)
                    if row[f"ONET{index}"].strip()
                }
                if not occupations:
                    continue
                key = (
                    branch,
                    row["MOC"].strip().upper(),
                    row["MOC_TITLE"].strip(),
                    row["MPC"].strip(),
                )
                grouped.setdefault(key, set()).update(occupations)

    records = [
        {
            "b": branch,
            "c": code,
            "t": title,
            "p": personnel_category,
            "o": [
                {"c": onet_code, "t": onet_title}
                for onet_code, onet_title in sorted(occupations)
            ],
        }
        for (branch, code, title, personnel_category), occupations in grouped.items()
    ]
    records.sort(key=lambda record: (record["b"], record["c"], record["t"], record["p"]))

    return {
        "metadata": {
            "dataset": "Military Occupational Classification Crosswalk",
            "sourceAgency": "Defense Manpower Data Center",
            "publisher": "O*NET Resource Center, USDOL/ETA",
            "sourceURL": SOURCE_URL,
            "sourceRelease": SOURCE_RELEASE,
            "sourceSHA256": hashlib.sha256(source_bytes).hexdigest(),
            "sourceRows": source_rows,
            "includedRecords": len(records),
            "rules": "Active service-branch records with one or more O*NET-SOC links; grouped without changing source titles or codes.",
            "attribution": "Military crosswalk source: Defense Manpower Data Center via the O*NET Resource Center. O*NET is a trademark of USDOL/ETA. No agency has approved, endorsed, or tested ApplyReady Vets.",
        },
        "records": records,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_zip", type=Path)
    parser.add_argument("output_json", type=Path)
    args = parser.parse_args()

    dataset = build(args.source_zip)
    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(
        dataset,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    args.output_json.write_bytes(encoded)

    decoded = json.loads(args.output_json.read_text(encoding="utf-8"))
    if decoded["metadata"]["includedRecords"] != len(decoded["records"]):
        raise SystemExit("Generated crosswalk failed its record-count verification.")
    print(
        f"Wrote {len(decoded['records']):,} active mappings "
        f"({len(encoded):,} bytes) to {args.output_json}"
    )


if __name__ == "__main__":
    main()
