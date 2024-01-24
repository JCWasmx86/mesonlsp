#!/usr/bin/env python3
import sys

from shared import parse_ascii_file


def main():
    with open(sys.argv[2], "w", encoding="utf-8") as output:
        print('#include "typenamespace.hpp"', file=output)
        print("void TypeNamespace::initObjectDocs() {", file=output)
        data_dict = parse_ascii_file(sys.argv[1])
        for key, doc in data_dict.items():
            escaped = doc.encode("unicode-escape").decode("utf-8").replace('"', '\\"')
            print(f'    this->objectDocs["{key}"] = "{escaped}";', file=output)
        print("}", file=output)


if __name__ == "__main__":
    main()
