"""Exit 0 when <project>/.specify/extensions.yml registers the Ahmed review gate
as a mandatory before_implement hook, else print why and exit 1.

Used by ahmed/verify.ps1; parses the YAML instead of regex-matching it.
"""
import sys
from pathlib import Path

import yaml

COMMAND = "speckit.ahmed.review-gate"


def main(project: str) -> int:
    path = Path(project) / ".specify" / "extensions.yml"
    if not path.is_file():
        print(f"missing {path}")
        return 1
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    entries = (data.get("hooks") or {}).get("before_implement") or []
    if isinstance(entries, dict):
        entries = [entries]
    for entry in entries:
        if entry.get("command") == COMMAND:
            if entry.get("optional") is False and entry.get("enabled", True) is not False:
                print(f"before_implement -> {COMMAND} (optional: false, enabled)")
                return 0
            print(f"{COMMAND} is registered but optional={entry.get('optional')!r} enabled={entry.get('enabled')!r}")
            return 1
    print(f"{COMMAND} not found under hooks.before_implement in {path}")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
