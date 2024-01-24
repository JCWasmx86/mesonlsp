import csv


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


def type_to_cpp(t: str):
    if t == "subproject()":
        return 'this->types.at("subproject")'
    if t.startswith("dict(") or t.startswith("list("):
        cpp_type = "Dict" if t.startswith("dict(") else "List"
        sub_types = list(map(type_to_cpp, extract_types(t)))
        if len(sub_types) == 0:
            return f"std::make_shared<{cpp_type}>()"
        total_str = "{" + ",".join(sub_types) + "}"
        return f"std::make_shared<{cpp_type}>(std::vector<std::shared_ptr<Type>>{total_str})"
    return f'this->types.at("{t}")'


def fetch_deprecation_data(file_pointer):
    parsed_dict = {}
    csv_reader = csv.reader(file_pointer)
    for row in csv_reader:
        key = row[0]
        data = (row[1], row[2].split("|"))
        parsed_dict[key] = data
    return parsed_dict


def fetch_since_data(file_pointer):
    parsed_dict = {}
    csv_reader = csv.reader(file_pointer)
    for row in csv_reader:
        parsed_dict[row[0]] = row[1]
    return parsed_dict
