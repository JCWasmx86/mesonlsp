#!/usr/bin/env python3
import sys

from collections import defaultdict

def type_to_cpp(t: str):
    if t == "subproject()":
        return "this->types[\"subproject\"]"
    if t.startswith("dict(") or t.startswith("list("):
        cpp_type = "Dict" if t.startswith("dict(") else "List"
        sub_types = []
        curr_sub_type = ""
        sub_type_str = t[5:][:-1]
        for char in sub_type_str:
            if char == "|":
                sub_types.append(type_to_cpp(curr_sub_type))
                curr_sub_type = ""
            else:
                curr_sub_type += char
        sub_types.append(type_to_cpp(curr_sub_type))
        total_str = "{" + ",".join(sub_types) + "}"
        return f"std::make_shared<{cpp_type}>(std::vector<std::shared_ptr<Type>>{total_str})"
    return f"this->types[\"{t}\"]"

def main():
    with open(sys.argv[2], "w", encoding="utf-8") as output:
        with open(sys.argv[1], "r", encoding="utf-8") as filep:
            lines = filep.readlines()
        print('#include <memory>', file=output)
        print('#include "typenamespace.hpp"', file=output)
        print('#include "type.hpp"', file=output)
        print('#define True true', file=output)
        print('#define False false', file=output)
        print("void TypeNamespace::initMethods() {", file=output)
        idx = 0
        curr_fn_name = None
        args = []
        kwargs = []
        returns = []
        full_data = defaultdict(list)
        while idx != len(lines):
            if not lines[idx].startswith(" "):
                if curr_fn_name is not None:
                    obj_type = curr_fn_name.split("::")[0]
                    method_name = curr_fn_name.split("::")[1].replace(":", "")
                    full_data[obj_type].append((method_name, args, kwargs, returns))
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
                        idx += 1 # Skip "- Types:"
                        while True:
                            if not lines[idx].startswith("        -"):
                                break
                            arg_types.append(lines[idx].replace("        -", "").strip())
                            idx += 1
                        args.append((arg_name, varargs, optional, arg_types))
                    else:
                        optional = "true" in lines[idx]
                        idx += 1
                        arg_types = []
                        idx += 1 # Skip "- Types:"
                        while True:
                            if not lines[idx].startswith("        -"):
                                break
                            arg_types.append(lines[idx].replace("        -", "").strip())
                            idx += 1
                        kwargs.append((arg_name, optional, arg_types))
            elif lines[idx].startswith("  - returns:"):
                idx += 1
                while idx != len(lines):
                    if not lines[idx].startswith("    -"):
                        break
                    returns.append(lines[idx].replace("    -", "").replace(":", "").strip())
                    idx += 1
        for obj_name in sorted(full_data.keys()):
            print(f"  this->vtables[\"{obj_name}\"] = std::vector<std::shared_ptr<Method>>" + "{", file=output)
            for idx, method in enumerate(full_data[obj_name]):
                print("    std::make_shared<Method>(", file=output)
                print(f"      \"{method[0]}\",", file=output)
                print("      std::vector<std::shared_ptr<Argument>> {", file=output)
                args = method[1]
                kwargs = method[2]
                total_len = len(args) + len(kwargs)
                for idx_, arg in enumerate(args):
                    print("        std::make_shared<PositionalArgument>(", file=output)
                    print(f"          \"{arg[0]}\",", file=output)
                    print("          std::vector<std::shared_ptr<Type>>{", file=output),
                    for t_idx, t in enumerate(arg[3]):
                        print("            " + type_to_cpp(t) + ("," if t_idx != len(arg[3]) - 1 else ""), file=output)
                    print("          },", file=output)
                    print(f"          {arg[2]},", file=output)
                    print(f"          {arg[1]}", file=output)
                    if idx_ == total_len - 1:
                        print("        )", file=output)
                    else:
                        print("        ),", file=output)
                for idx_, arg in enumerate(kwargs):
                    print("        std::make_shared<Kwarg>(", file=output)
                    print(f"          \"{arg[0][1:]}\",", file=output)
                    print("          std::vector<std::shared_ptr<Type>>{", file=output),
                    for t_idx, t in enumerate(arg[2]):
                        print("            " + type_to_cpp(t) + ("," if t_idx != len(arg[2]) - 1 else ""), file=output)
                    print("          },", file=output)
                    print(f"          {arg[1]}", file=output)
                    if len(args) + idx_ == total_len - 1:
                        print("        )", file=output)
                    else:
                        print("        ),", file=output)
                print("      },", file=output)
                print("      std::vector<std::shared_ptr<Type>>{", file=output)
                for t_idx, t in enumerate(method[3]):
                    print("        " + type_to_cpp(t) + ("," if t_idx != len(method[3]) - 1 else ""), file=output)
                print("      },", file=output)
                print(f"     this->types[\"{obj_name}\"]", file=output)
                if idx == len(full_data[obj_name]) - 1:
                    print("    )", file=output)
                else:
                    print("    ),", file=output)
            print("  };", file=output)
        print("}", file=output)
if __name__ == "__main__":
    main()