#!/usr/bin/env python3
import argparse
import configparser
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--width", required=True, type=int)
    parser.add_argument("--height", required=True, type=int)
    parser.add_argument(
        "--config", default=str(Path.home() / ".config" / "kwinrulesrc")
    )
    args = parser.parse_args()

    path = Path(args.config)
    path.parent.mkdir(parents=True, exist_ok=True)

    config = configparser.ConfigParser(interpolation=None, strict=False)
    config.optionxform = str
    config.read(path)
    if not config.has_section("General"):
        config.add_section("General")

    rule_id = "waydroid-setup"
    rules = [item for item in config.get("General", "rules", fallback="").split(",") if item]
    if rule_id not in rules:
        rules.append(rule_id)
    config.set("General", "rules", ",".join(rules))
    config.set("General", "count", str(len(rules)))

    if not config.has_section(rule_id):
        config.add_section(rule_id)
    values = {
        "Description": "Decorate and size Waydroid window",
        "noborder": "false",
        "noborderrule": "2",
        "size": f"{args.width},{args.height}",
        "sizerule": "3",
        "wmclass": "Waydroid",
        "wmclasscomplete": "false",
        "wmclassmatch": "1",
    }
    for key, value in values.items():
        config.set(rule_id, key, value)

    with path.open("w") as file:
        config.write(file, space_around_delimiters=False)


if __name__ == "__main__":
    main()
