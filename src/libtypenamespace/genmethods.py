#!/usr/bin/env python3
import csv
import sys
from collections import defaultdict


def extract_types(input_str):
    input_str = input_str[5:][:-1]
    paren_cnter = 0
    s = ""
    ret = []
    for ch in input_str:
        if ch == "(":
            paren_cnter += 1
        if ch == ")":
            paren_cnter -= 1
        if paren_cnter == 0 and ch == "|":
            ret.append(s)
            s = ""
        else:
            s += ch
    assert paren_cnter == 0
    if s != "":
        ret.append(s)
    return ret


def fetch_deprecation_data(file_pointer):
    parsed_dict = {}
    csv_reader = csv.reader(file_pointer)
    for row in csv_reader:
        key = row[0]
        data = (row[1], row[2].split("|"))
        parsed_dict[key] = data
    return parsed_dict


def type_to_cpp(t: str):
    if t == "subproject()":
        return 'this->types["subproject"]'
    if t.startswith("dict(") or t.startswith("list("):
        cpp_type = "Dict" if t.startswith("dict(") else "List"
        sub_types = map(type_to_cpp, extract_types(t))
        total_str = "{" + ",".join(sub_types) + "}"
        return f"std::make_shared<{cpp_type}>(std::vector<std::shared_ptr<Type>>{total_str})"
    return f'this->types["{t}"]'


def fetch_since_data(file_pointer):
    parsed_dict = {}
    csv_reader = csv.reader(file_pointer)
    for row in csv_reader:
        parsed_dict[row[0]] = row[1]
    return parsed_dict


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
    with open(sys.argv[4], "r", encoding="utf-8") as filep:
        deprecations = fetch_deprecation_data(filep)
    with open(sys.argv[5], "r", encoding="utf-8") as filep:
        since_data = fetch_since_data(filep)
    with open(sys.argv[2], "w", encoding="utf-8") as output:
        with open(sys.argv[1], "r", encoding="utf-8") as filep:
            lines = filep.readlines()
        print("#include <memory>", file=output)
        print('#include "typenamespace.hpp"', file=output)
        print('#include "type.hpp"', file=output)
        print("#define True true", file=output)
        print("#define False false", file=output)
        print("void TypeNamespace::initMethods() {", file=output)
        idx = 0
        curr_fn_name = None
        args = []
        kwargs = []
        returns = []
        full_data = defaultdict(list)
        while idx <= len(lines):
            if idx == len(lines) or not lines[idx].startswith(" "):
                if curr_fn_name is not None:
                    obj_type = curr_fn_name.split("::")[0]
                    method_name = curr_fn_name.split("::")[1].replace(":", "")
                    full_data[obj_type].append((method_name, args, kwargs, returns))
                    if idx == len(lines):
                        break
                curr_fn_name = lines[idx].strip()
                args = []
                kwargs = []
                returns = []
                idx += 1
            elif lines[idx].startswith("  - args:"):
                idx += 1
                while True:
                    if not lines[idx].startswith("    -"):
                        break
                    arg_name = lines[idx].replace("    -", "").replace(":", "").strip()
                    idx += 1
                    if not arg_name.startswith("@"):
                        optional = "true" in lines[idx]
                        idx += 1
                        varargs = "true" in lines[idx]
                        idx += 1
                        arg_types = []
                        idx += 1  # Skip "- Types:"
                        while True:
                            if not lines[idx].startswith("        -"):
                                break
                            arg_types.append(
                                lines[idx].replace("        -", "").strip()
                            )
                            idx += 1
                        args.append((arg_name, varargs, optional, arg_types))
                    else:
                        optional = "true" in lines[idx]
                        idx += 1
                        arg_types = []
                        idx += 1  # Skip "- Types:"
                        while True:
                            if not lines[idx].startswith("        -"):
                                break
                            arg_types.append(
                                lines[idx].replace("        -", "").strip()
                            )
                            idx += 1
                        kwargs.append((arg_name, optional, arg_types))
            elif lines[idx].startswith("  - returns:"):
                idx += 1
                while idx != len(lines):
                    if not lines[idx].startswith("    -"):
                        break
                    returns.append(
                        lines[idx].replace("    -", "").replace(":", "").strip()
                    )
                    idx += 1
        data_dict = parse_ascii_file(sys.argv[3])
        for obj_name in sorted(full_data.keys()):
            print(
                f'  this->vtables["{obj_name}"] = std::vector<std::shared_ptr<Method>>'
                + "{",
                file=output,
            )
            for idx, method in enumerate(full_data[obj_name]):
                method_id = obj_name + "::" + method[0]
                escaped = (
                    data_dict[method_id]
                    .encode("unicode-escape")
                    .decode("utf-8")
                    .replace('"', '\\"')
                )
                print("    std::make_shared<Method>(", file=output)
                print(f'      "{method[0]}",', file=output)
                print(f'      "{escaped}",', file=output)
                print("      std::vector<std::shared_ptr<Argument>> {", file=output)
                args = method[1]
                kwargs = method[2]
                total_len = len(args) + len(kwargs)
                for idx_, arg in enumerate(args):
                    print("        std::make_shared<PositionalArgument>(", file=output)
                    print(f'          "{arg[0]}",', file=output)
                    print("          std::vector<std::shared_ptr<Type>>{", file=output)
                    for t_idx, t in enumerate(arg[3]):
                        print(
                            "            "
                            + type_to_cpp(t)
                            + ("," if t_idx != len(arg[3]) - 1 else ""),
                            file=output,
                        )
                    print("          },", file=output)
                    print(f"          {arg[2]},", file=output)
                    print(f"          {arg[1]}", file=output)
                    if idx_ == total_len - 1:
                        print("        )", file=output)
                    else:
                        print("        ),", file=output)
                for idx_, arg in enumerate(kwargs):
                    coded_kwarg_name = arg[0]
                    print("        std::make_shared<Kwarg>(", file=output)
                    print(f'          "{coded_kwarg_name[1:]}",', file=output)
                    print("          std::vector<std::shared_ptr<Type>>{", file=output)
                    for t_idx, t in enumerate(arg[2]):
                        print(
                            "            "
                            + type_to_cpp(t)
                            + ("," if t_idx != len(arg[2]) - 1 else ""),
                            file=output,
                        )
                    print("          },", file=output)
                    print(f"          {arg[1]}", file=output)
                    if coded_kwarg_name in deprecations:
                        print(",DeprecationState(", file=output)
                        deprecation_data = deprecations[coded_kwarg_name]
                        print(
                            f'"{deprecation_data[0]}", std::vector<std::string>',
                            file=output,
                        )
                        print(
                            "{" + ",".join([f'"{x}"' for x in deprecation_data[1]]),
                            file=output,
                        )
                        print("})", file=output)
                    if len(args) + idx_ == total_len - 1:
                        print("        )", file=output)
                    else:
                        print("        ),", file=output)
                print("      },", file=output)
                print("      std::vector<std::shared_ptr<Type>>{", file=output)
                for t_idx, t in enumerate(method[3]):
                    print(
                        "        "
                        + type_to_cpp(t)
                        + ("," if t_idx != len(method[3]) - 1 else ""),
                        file=output,
                    )
                print("      },", file=output)
                print(f'     this->types["{obj_name}"]', file=output)
                if method_id in deprecations:
                    print(",DeprecationState(", file=output)
                    deprecation_data = deprecations[method_id]
                    print(
                        f'"{deprecation_data[0]}", std::vector<std::string>',
                        file=output,
                    )
                    print(
                        "{" + ",".join([f'"{x}"' for x in deprecation_data[1]]),
                        file=output,
                    )
                    print("})", file=output)
                if method_id in since_data:
                    if method_id not in deprecations:
                        print(",DeprecationState()", file=output)
                    since = since_data[method_id]
                    print(f',Version("{since}")', file=output)
                if idx == len(full_data[obj_name]) - 1:
                    print("    )", file=output)
                else:
                    print("    ),", file=output)
            print("  };", file=output)
        print("}", file=output)


if __name__ == "__main__":
    main()
