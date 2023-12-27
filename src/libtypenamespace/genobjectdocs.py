#!/usr/bin/env python3
import sys


def parse_ascii_file(file_path):
    data_dict = {}
    current_section = None

    with open(file_path, "r", encoding="utf-8") as file:
        for line in file:
            line = line.strip()

            if line.startswith("@"):
                # Removing '@' at the beginning and ':' at the end
                section_name = line[1:-1]
                data_dict[section_name] = ""
                current_section = section_name
            elif current_section is not None:
                data_dict[current_section] += line + "\n"
    for section, content in data_dict.items():
        data_dict[section] = content.rstrip("\n")

    return data_dict


def main():
    with open(sys.argv[2], "w", encoding="utf-8") as output:
        print('#include "typenamespace.hpp"', file=output)
        print('#include "type.hpp"', file=output)
        print("void TypeNamespace::initObjectDocs() {", file=output)
        data_dict = parse_ascii_file(sys.argv[1])
        for key, doc in data_dict.items():
            escaped = doc.encode("unicode-escape").decode("utf-8").replace('"', '\\"')
            print(f'    this->types["{key}"]->docs = "{escaped}";', file=output)
        print("}", file=output)


if __name__ == "__main__":
    main()
