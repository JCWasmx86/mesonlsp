#!/usr/bin/env python3
import sys

from shared import (
    fetch_deprecation_data,
    fetch_since_data,
    parse_ascii_file,
    type_to_cpp,
)


def main():
    data_dict = parse_ascii_file(sys.argv[3])
    with open(sys.argv[4], "r", encoding="utf-8") as filep:
        deprecations = fetch_deprecation_data(filep)
    with open(sys.argv[5], "r", encoding="utf-8") as filep:
        since_data = fetch_since_data(filep)
    with open(sys.argv[2], "w", encoding="utf-8") as output:
        with open(sys.argv[1], "r", encoding="utf-8") as filep:
            lines = filep.readlines()
        print('#include "typenamespace.hpp"', file=output)
        print('#include "type.hpp"', file=output)
        print("#define True true", file=output)
        print("#define False false", file=output)
        print("void TypeNamespace::initFunctions() {", file=output)
        idx = 0
        curr_fn_name = None
        args = []
        kwargs = []
        returns = []
        while idx <= len(lines):
            if idx == len(lines) or not lines[idx].startswith(" "):
                if curr_fn_name is not None:
                    print(
                        f'  this->functions["{curr_fn_name}"] = std::make_shared<Function>(',
                        file=output,
                    )
                    escaped = (
                        data_dict[curr_fn_name]
                        .encode("unicode-escape")
                        .decode("utf-8")
                        .replace('"', '\\"')
                    )
                    print(f'    "{curr_fn_name}",', file=output)
                    print(f'    "{escaped}",', file=output)
                    print("    std::vector<std::shared_ptr<Argument>>{", file=output)
                    total_len = len(args) + len(kwargs)
                    for idx_, arg in enumerate(args):
                        print(
                            "      std::make_shared<PositionalArgument>(", file=output
                        )
                        print(f'        "{arg[0]}",', file=output)
                        print(
                            "        std::vector<std::shared_ptr<Type>>{", file=output
                        )
                        for t_idx, t in enumerate(arg[3]):
                            print(
                                "          "
                                + type_to_cpp(t)
                                + ("," if t_idx != len(arg[3]) - 1 else ""),
                                file=output,
                            )
                        print("        },", file=output)
                        print(f"        {arg[2]},", file=output)
                        print(f"        {arg[1]}", file=output)
                        if idx_ == total_len - 1:
                            print("      )", file=output)
                        else:
                            print("      ),", file=output)
                    for idx_, arg in enumerate(kwargs):
                        coded_kwarg_name = arg[0]
                        print("      std::make_shared<Kwarg>(", file=output)
                        print(f'        "{coded_kwarg_name[1:]}",', file=output)
                        print(
                            "        std::vector<std::shared_ptr<Type>>{", file=output
                        )
                        for t_idx, t in enumerate(arg[2]):
                            print(
                                "          "
                                + type_to_cpp(t)
                                + ("," if t_idx != len(arg[2]) - 1 else ""),
                                file=output,
                            )
                        print("        },", file=output)
                        print(f"        {arg[1]}", file=output)
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
                            print("      )", file=output)
                        else:
                            print("      ),", file=output)
                    print("    },", file=output)
                    print("    std::vector<std::shared_ptr<Type>>{", file=output)
                    for t_idx, t in enumerate(returns):
                        print(
                            "        "
                            + type_to_cpp(t)
                            + ("," if t_idx != len(returns) - 1 else ""),
                            file=output,
                        )
                    print("    }", file=output)
                    if curr_fn_name in deprecations:
                        print(",DeprecationState(", file=output)
                        deprecation_data = deprecations[curr_fn_name]
                        print(
                            f'"{deprecation_data[0]}", std::vector<std::string>',
                            file=output,
                        )
                        print(
                            "{" + ",".join([f'"{x}"' for x in deprecation_data[1]]),
                            file=output,
                        )
                        print("})", file=output)
                    if curr_fn_name in since_data:
                        if curr_fn_name not in deprecations:
                            print(",DeprecationState()", file=output)
                        since = since_data[curr_fn_name]
                        print(f',Version("{since}")', file=output)
                    print("  );", file=output)
                    if idx == len(lines):
                        break
                curr_fn_name = lines[idx].replace(":", "").strip()
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
        print("}", file=output)


if __name__ == "__main__":
    main()
