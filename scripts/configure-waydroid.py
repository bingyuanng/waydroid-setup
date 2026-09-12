#!/usr/bin/env python3
import argparse
import configparser
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="/var/lib/waydroid/waydroid.cfg")
    parser.add_argument("--width", required=True, type=int)
    parser.add_argument("--height", required=True, type=int)
    parser.add_argument("--max-fps", required=True, type=int)
    parser.add_argument("--fake-touch", required=True)
    parser.add_argument("--multi-windows", choices=("true", "false"), required=True)
    args = parser.parse_args()

    path = Path(args.config)
    if not path.is_file():
        raise SystemExit(f"Waydroid is not initialized: {path} does not exist")

    config = configparser.ConfigParser()
    config.optionxform = str
    config.read(path)
    if not config.has_section("properties"):
        config.add_section("properties")

    properties = {
        "persist.waydroid.width": str(args.width),
        "persist.waydroid.height": str(args.height),
        "persist.waydroid.max_fps": str(args.max_fps),
        "persist.waydroid.fake_touch": args.fake_touch,
        "persist.waydroid.multi_windows": args.multi_windows,
    }
    for key, value in properties.items():
        config.set("properties", key, value)

    with path.open("w") as file:
        config.write(file)


if __name__ == "__main__":
    main()
