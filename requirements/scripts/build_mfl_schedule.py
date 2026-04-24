#!/usr/bin/env python3
"""Build a compact MFL (Market-Frankford "L") schedule bundle from SEPTA's GTFS feed.

Downloads SEPTA's public GTFS zip, extracts the rail bundle, filters to route_id == "L1",
and writes a compact JSON file used by the iOS app as a fallback when the GTFS-realtime
feed has no data for the L line.

Usage:
    python3 scripts/build_mfl_schedule.py [--output PATH] [--gtfs-zip URL_OR_PATH]

Re-run this script when SEPTA publishes a new GTFS feed (typically with each pick).
The default --output writes to the iOS app bundle folder so Xcode's synchronized file
group picks it up automatically.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import io
import json
import os
import sys
import urllib.request
import zipfile
from typing import Any

DEFAULT_GTFS_URL = "https://www3.septa.org/developer/gtfs_public.zip"
ROUTE_ID = "L1"
DEFAULT_OUTPUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "TunnelVision Complete",
    "TunnelVision Complete",
    "mfl_schedule.json",
)


def fetch_zip_bytes(source: str) -> bytes:
    if os.path.exists(source):
        with open(source, "rb") as fh:
            return fh.read()
    print(f"Downloading {source} ...", file=sys.stderr)
    req = urllib.request.Request(source, headers={"User-Agent": "tunnelvision-build/1.0"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read()


def open_inner_zip(outer_zip_bytes: bytes) -> zipfile.ZipFile:
    """SEPTA's public zip contains google_bus.zip and google_rail.zip.

    The Market-Frankford Line (route_id "L1") lives in the bus/metro bundle,
    not in the regional rail bundle.
    """
    outer = zipfile.ZipFile(io.BytesIO(outer_zip_bytes))
    bus_name = next((n for n in outer.namelist() if "bus" in n.lower() and n.endswith(".zip")), None)
    if bus_name is None:
        return outer
    inner_bytes = outer.read(bus_name)
    return zipfile.ZipFile(io.BytesIO(inner_bytes))


def read_csv(zf: zipfile.ZipFile, name: str) -> list[dict[str, str]]:
    with zf.open(name) as fh:
        text = io.TextIOWrapper(fh, encoding="utf-8-sig", newline="")
        return list(csv.DictReader(text))


def parse_gtfs_time(value: str) -> int:
    h, m, s = (int(x) for x in value.strip().split(":"))
    return h * 3600 + m * 60 + s


def build_schedule(gtfs_zip: zipfile.ZipFile) -> dict[str, Any]:
    routes = read_csv(gtfs_zip, "routes.txt")
    if not any(r.get("route_id") == ROUTE_ID for r in routes):
        candidates = sorted({r.get("route_id", "") for r in routes})
        raise SystemExit(f"route_id {ROUTE_ID!r} not found. Available: {candidates}")

    trips = [t for t in read_csv(gtfs_zip, "trips.txt") if t.get("route_id") == ROUTE_ID]
    trip_ids = {t["trip_id"] for t in trips}
    trip_by_id = {t["trip_id"]: t for t in trips}
    service_ids = {t["service_id"] for t in trips}

    calendar_rows = [
        c for c in read_csv(gtfs_zip, "calendar.txt") if c.get("service_id") in service_ids
    ]
    services: dict[str, dict[str, Any]] = {}
    day_keys = ("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday")
    for row in calendar_rows:
        services[row["service_id"]] = {
            "days": [row.get(k) == "1" for k in day_keys],
            "start": row.get("start_date", ""),
            "end": row.get("end_date", ""),
        }

    exceptions: list[dict[str, Any]] = []
    try:
        for row in read_csv(gtfs_zip, "calendar_dates.txt"):
            if row.get("service_id") not in service_ids:
                continue
            exceptions.append(
                {
                    "service": row["service_id"],
                    "date": row["date"],
                    "type": int(row.get("exception_type", "1")),
                }
            )
    except KeyError:
        pass

    stop_times: dict[str, dict[str, list[dict[str, Any]]]] = {}
    seen = 0
    for row in read_csv(gtfs_zip, "stop_times.txt"):
        trip_id = row.get("trip_id")
        if trip_id not in trip_ids:
            continue
        seen += 1
        trip = trip_by_id[trip_id]
        service_id = trip["service_id"]
        headsign = (
            row.get("stop_headsign")
            or trip.get("trip_headsign")
            or ""
        ).strip()
        time_str = (row.get("arrival_time") or row.get("departure_time") or "").strip()
        if not time_str:
            continue
        try:
            secs = parse_gtfs_time(time_str)
        except ValueError:
            continue
        stop_id = row.get("stop_id", "")
        per_stop = stop_times.setdefault(stop_id, {})
        per_service = per_stop.setdefault(service_id, [])
        per_service.append({"t": secs, "headsign": headsign})

    for per_stop in stop_times.values():
        for entries in per_stop.values():
            entries.sort(key=lambda e: e["t"])

    print(
        f"Processed {seen} stop_times across {len(stop_times)} stops "
        f"and {len(services)} services.",
        file=sys.stderr,
    )

    return {
        "generated": dt.date.today().isoformat(),
        "route_id": ROUTE_ID,
        "services": services,
        "exceptions": exceptions,
        "stopTimes": stop_times,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", default=DEFAULT_OUTPUT, help="Path to write mfl_schedule.json")
    parser.add_argument(
        "--gtfs-zip",
        default=DEFAULT_GTFS_URL,
        help="URL or local path to SEPTA's public GTFS zip",
    )
    args = parser.parse_args()

    raw = fetch_zip_bytes(args.gtfs_zip)
    inner_zip = open_inner_zip(raw)
    payload = build_schedule(inner_zip)

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, separators=(",", ":"), ensure_ascii=False)

    size_kb = os.path.getsize(args.output) / 1024
    print(f"Wrote {args.output} ({size_kb:.1f} KB)", file=sys.stderr)


if __name__ == "__main__":
    main()
