#!/usr/bin/env python
import argparse
import datetime
import json
import logging
import os
import statistics
import subprocess
import time

PROJECTS = {
    "gnome-builder": "https://github.com/GNOME/gnome-builder",
    "GNOME-Builder-Plugins": "https://github.com/JCWasmx86/GNOME-Builder-Plugins",
    "gtk": "https://github.com/GNOME/gtk",
    "mesa": "https://gitlab.freedesktop.org/mesa/mesa/",
    "postgres": "https://github.com/postgres/postgres",
    "qemu": "https://github.com/qemu/qemu",
}
N_ITERATIONS = 25
MS_IN_S = 1000


def base_path():
    home = os.path.expanduser("~")
    full_path = home + "/.cache/" + "quick-swift-mesonlsp-benchmarks"
    try:
        os.mkdir(full_path)
    except:
        pass
    return full_path


def clone_project(name, url):
    if os.path.exists(name):
        logging.info("Updating %s", url)
        subprocess.run(
            ["git", "-C", name, "fetch", "--unshallow"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        subprocess.run(
            ["git", "-C", name, "pull"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return
    logging.info("Cloning %s", url)
    subprocess.run(
        ["git", "clone", "--depth=1", url, name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )


def clone_projects():
    for name, url in PROJECTS.items():
        clone_project(name, url)


def count_instructions(filename, project_name):
    logging.info(f"Recording insn count with perf for {project_name}")
    command = [
        "perf",
        "record",
        "--call-graph",
        "dwarf",
        filename,
        project_name + "/meson.build",
    ]
    subprocess.run(
        command,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )
    with subprocess.Popen(
        ["perf", "report", "--stdio"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ) as prof_process:
        stdout, _ = prof_process.communicate()
        lines = stdout.decode("utf-8").splitlines()
        for line in lines:
            if line.startswith("# Event count"):
                return int(line.split(":")[1].strip())
    return 0


def get_timing_stats(filename, project_name):
    logging.info(f"Working on {project_name}")
    command = [filename, project_name + "/meson.build"]
    durations = []
    for _ in range(0, N_ITERATIONS):
        begin = datetime.datetime.now()
        subprocess.run(
            command,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
        end = datetime.datetime.now()
        duration = (end - begin).total_seconds() * MS_IN_S
        durations.append(duration)
    return {
        "min": min(durations),
        "max": max(durations),
        "sum": sum(durations),
        "avg": sum(durations) / len(durations),
        "deviation": statistics.pstdev(durations),
        "durations": durations,
    }


def analyze_file(filename, run_name):
    logging.info("Base path: %s", base_path())
    ret = {"time": time.time(), "name": run_name, "filename": filename}
    absp = os.path.abspath(filename)
    os.chdir(base_path())
    clone_projects()
    data = {}
    for name in PROJECTS:
        obj_data = {}
        obj_data["stats"] = get_timing_stats(absp, name)
        obj_data["insn_count"] = count_instructions(absp, name)
        data[name] = obj_data
    ret["data"] = data
    print(json.dumps(ret))


def main():
    parser = argparse.ArgumentParser(
        prog="fast_collect_data.py",
        description="Collect performance/memory usage characteristics",
    )
    parser.add_argument("filename")
    parser.add_argument("name")
    args = parser.parse_args()
    analyze_file(args.filename, args.name)


if __name__ == "__main__":
    logging.basicConfig(
        format="%(asctime)s %(levelname)-8s %(message)s", level=logging.INFO
    )
    main()
