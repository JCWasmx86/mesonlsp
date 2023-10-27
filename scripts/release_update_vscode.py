#!/usr/bin/env python3
# pylint: disable=missing-module-docstring,missing-function-docstring,bare-except,line-too-long
import sys


def update_typescript(file):
    with open(file, "r", encoding="utf-8") as filep:
        lines = list(filep.readlines())
    for idx, value in enumerate(lines):
        if 'name: "Swift-MesonLSP-win64.zip",' in value:
            lines[idx + 1] = f'      hash: "{sys.argv[2]}",\n'
        elif 'name: "Swift-MesonLSP-macos12.zip",' in value:
            lines[idx + 1] = f'      hash: "{sys.argv[3]}",\n'
        elif 'name: "Swift-MesonLSP.zip",' in value:
            lines[idx + 1] = f'      hash: "{sys.argv[4]}",\n'
        elif "static override version: string =" in value:
            lines[idx] = f'  static override version: string = "{sys.argv[5]}";\n'
    with open(file, "w", encoding="utf-8") as filep:
        filep.write("".join(lines).strip())


def update_changelog(changelog_file):
    with open(changelog_file, "r", encoding="utf-8") as filep:
        lines = list(filep.readlines())
    old_idx = -1
    for idx, value in enumerate(lines):
        if value.startswith("## ") and "next" not in value:
            old_idx = idx - 1
            break
    new_lines = list(map(lambda x: x.strip(), lines[0:old_idx]))
    if "## next" in new_lines[-1]:
        new_lines.append("")
    new_lines.append(f"- Bump Swift-MesonLSP to {sys.argv[5]}")
    new_lines += list(map(lambda x: x.strip(), lines[old_idx:]))
    with open(changelog_file, "w", encoding="utf-8") as filep:
        filep.write("\n".join(new_lines))


if __name__ == "__main__":
    update_typescript(sys.argv[1])
    update_changelog(sys.argv[6])
