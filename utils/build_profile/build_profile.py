#!/usr/bin/env python3
"""Build sl3_profile.json: an OSCAL profile of NIST SP 800-53 rev. 5 with RAND's SL3 control text."""
import json
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path

RAND = Path("achieving-ai-model-weight-sl3")
NIST_CATALOG = (
    "https://raw.githubusercontent.com/usnistgov/oscal-content/"
    "5006f18c8047643eaa70e35dd0d20a58bcc41856/"
    "nist.gov/SP800-53/rev5/json/NIST_SP-800-53_rev5_catalog.json"
)
OSCAL_VERSION = "1.2.3"


def oscal_id(rand_id):
    """Turn RAND's control ID (SC-28, AC-2(1)) into NIST's OSCAL ID (sc-28, ac-2.1)."""
    family, number, enhancement = re.fullmatch(r"([A-Z]{2})-(\d+)(?:\((\d+)\))?", rand_id).groups()
    return f"{family.lower()}-{number}" + (f".{enhancement}" if enhancement else "")


def alter(control):
    """Replace NIST's statement with RAND's SL3 enhanced control text."""
    control_id = oscal_id(control["control_id"])
    statement = {"id": f"{control_id}_smt", "name": "statement", "prose": control["enhanced_control_text"]}
    return {
        "control-id": control_id,
        "removes": [{"by-name": "statement"}],
        "adds": [{"position": "starting", "parts": [statement]}],
    }


source = (RAND / "sl3-controls-data.js").read_text()
data = json.loads(source[source.index("{"):source.rindex("}") + 1])
controls = data["controls"]

profile = {
    "profile": {
        "uuid": str(uuid.uuid4()),
        "metadata": {
            "title": "RAND Security Level 3 controls for AI model weights",
            "last-modified": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "version": data["metadata"]["version"],
            "oscal-version": OSCAL_VERSION,
            "remarks": (RAND / "LICENSE.txt").read_text(),
        },
        "imports": [
            {
                "href": NIST_CATALOG,
                "include-controls": [{"with-ids": [oscal_id(c["control_id"]) for c in controls]}],
            }
        ],
        "modify": {"alters": [alter(c) for c in controls]},
    }
}

Path("sl3_profile.json").write_text(json.dumps(profile, indent=2, ensure_ascii=False) + "\n")
print(f"sl3_profile.json: {len(controls)} controls")
