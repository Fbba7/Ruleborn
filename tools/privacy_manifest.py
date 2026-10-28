#!/usr/bin/env python3
"""The iPhone build's privacy manifest and export-compliance key, written into
client/export_presets.cfg from the server's declaration.

    python3 tools/privacy_manifest.py            # write the iOS preset's options
    python3 tools/privacy_manifest.py --check    # fail if they have drifted

Apple asks for the same answers twice: in App Store Connect's App Privacy form
(server/declarations.md) and in the app's own PrivacyInfo.xcprivacy, which
Godot 4.7.2 writes from the iOS preset's `privacy/collected_data/*` options.
Both are read from server/privacy.json here, so the two cannot disagree. The
export-compliance key (ITSAppUsesNonExemptEncryption) is read from
server/ratings.json's answer.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PRESETS = ROOT / "client" / "export_presets.cfg"
PRIVACY = ROOT / "server" / "privacy.json"
RATINGS = ROOT / "server" / "ratings.json"

#: App Store Connect's data type names (privacy.json's "apple") as Godot's
#: preset names them.
GODOT_TYPE = {
    "User ID": "user_id", "Device ID": "device_id", "Purchase History": "purchase_history",
    "Gameplay Content": "gameplay_content", "Other User Content": "other_user_content",
    "Other Usage Data": "other_usage_data", "Product Interaction": "product_interaction",
    "Crash Data": "crash_data", "Other Data Types": "other_data_types",
    "Customer Support": "customer_support", "Performance Data": "performance_data",
    "Other Diagnostic Data": "other_diagnostic_data", "Coarse Location": "coarse_location",
}

#: Godot's collection-purpose flags, in its order.
GODOT_PURPOSE = {"Analytics": 1, "App Functionality": 2, "Developer Advertising": 4,
                 "Third-party Advertising": 8, "Product Personalization": 16, "Other Purposes": 32}


def collected() -> dict[str, int]:
    """Each Godot data type the server collects, with its purpose flags —
    every data type is linked to the user and none is used for tracking
    (declarations.md)."""
    doc = json.loads(PRIVACY.read_text(encoding="utf-8"))
    out: dict[str, int] = {}

    def add(type_name: str, purposes) -> None:
        if type_name == "none":
            return
        apple = doc["types"][type_name]["apple"][1]
        key = GODOT_TYPE[apple]
        for p in purposes:
            out[key] = out.get(key, 0) | GODOT_PURPOSE[doc["purposes"][p]["apple"]]

    for table in doc["tables"].values():
        for col in table["columns"].values():
            for t in [col["type"], *col.get("also", [])]:
                add(t, col.get("purposes", table["purposes"]))
    return dict(sorted(out.items()))


def lines() -> list[str]:
    """The preset lines this owns, in order."""
    ratings = json.loads(RATINGS.read_text(encoding="utf-8"))
    uses = not ratings["export"]["answer"].startswith("No")
    plist = (f"<key>ITSAppUsesNonExemptEncryption</key><{'true' if uses else 'false'}/>")
    out = [f'application/additional_plist_content="{plist}"', "privacy/tracking_enabled=false",
           "privacy/tracking_domains=PackedStringArray()"]
    for key, flags in collected().items():
        out += [f"privacy/collected_data/{key}/collected=true",
                f"privacy/collected_data/{key}/linked_to_user=true",
                f"privacy/collected_data/{key}/used_for_tracking=false",
                f"privacy/collected_data/{key}/collection_purposes={flags}"]
    return out


OWNED = re.compile(r"^(application/additional_plist_content|privacy/tracking_enabled|privacy/tracking_domains|"
                   r"privacy/collected_data/[a-z_]+/[a-z_]+)=")


def written(text: str) -> str:
    """The presets with the iOS preset's owned options replaced by `lines()`."""
    head, sep, rest = text.partition("[preset.1.options]\n")
    if not sep:
        raise SystemExit("client/export_presets.cfg has no [preset.1.options]")
    body, nxt, tail = rest.partition("\n[preset.")
    kept = [l for l in body.split("\n") if not OWNED.match(l)]
    while kept and kept[-1] == "":
        kept.pop()
    return head + sep + "\n".join(kept + lines()) + "\n" + (nxt + tail if nxt else "")


def owned_values(text: str) -> dict[str, str]:
    """The iOS preset's owned options as written, by key: what the check
    compares, whatever order the editor saved them in. A data type Godot
    lists as not collected is the same as one not listed."""
    body = text.partition("[preset.1.options]\n")[2].partition("\n[preset.")[0]
    out = {}
    for line in body.split("\n"):
        if OWNED.match(line):
            key, _, value = line.partition("=")
            out[key] = value
    for key in [k for k, v in out.items() if k.endswith("/collected") and v == "false"]:
        prefix = key.rsplit("/", 1)[0]
        for k in [k for k in out if k.startswith(prefix + "/")]:
            del out[k]
    return out


def main() -> int:
    text = PRESETS.read_text(encoding="utf-8")
    new = written(text)
    if "--check" in sys.argv:
        if owned_values(new) != owned_values(text):
            print("client/export_presets.cfg's privacy manifest has drifted from server/privacy.json: "
                  "python3 tools/privacy_manifest.py")
            return 1
        print(f"client/export_presets.cfg: the privacy manifest's {len(collected())} data types match "
              "server/privacy.json")
        return 0
    PRESETS.write_text(new, encoding="utf-8")
    print(f"wrote the iOS preset's privacy manifest: {len(collected())} data types")
    return 0


if __name__ == "__main__":
    sys.exit(main())
