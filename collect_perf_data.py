#!/usr/bin/env python3
# pylint: disable=missing-module-docstring,missing-function-docstring
import argparse
import datetime
import json
import os
import subprocess
import sys
import tempfile
import time
import uuid

PROJECTS = {
    "mesa": "https://gitlab.freedesktop.org/mesa/mesa/",
    "gnome-builder": "https://github.com/GNOME/gnome-builder",
    "qemu": "https://github.com/qemu/qemu",
    "GNOME-Builder-Plugins": "https://github.com/JCWasmx86/GNOME-Builder-Plugins",
    "gtk": "https://github.com/GNOME/gtk"
}
N_ITERATIONS = 10


def heaptrack(absp, proj_name, is_ci):
    if not is_ci:
        with subprocess.Popen(
            ["heaptrack", "--record-only", absp, "--path", proj_name + "/meson.build"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ) as prof_process:
            stdout, _ = prof_process.communicate()
            lines = stdout.decode("utf-8").splitlines()
            zstfile = lines[-1].strip().split(" ")[2].replace('"', "")
            with subprocess.Popen(
                ["heaptrack_print", zstfile],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            ) as ana_process:
                stdout, _ = ana_process.communicate()
                lines = stdout.decode("utf-8").splitlines()
                return lines
    else:
        # Because Ubuntu has too old software, so --record-only is not known
        # and github has no runners for modern distributions
        with subprocess.Popen(
            ["heaptrack", absp, "--path", proj_name + "/meson.build"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ) as prof_process:
            stdout, _ = prof_process.communicate()
            lines = stdout.decode("utf-8").splitlines()
            zstfile = lines[-1].strip().split(" ")[2].replace('"', "")
            with subprocess.Popen(
                ["heaptrack_print", zstfile],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            ) as ana_process:
                stdout, _ = ana_process.communicate()
                lines = stdout.decode("utf-8").splitlines()
                return lines
    assert False


def analyze_file(file, commit, is_ci):
    ret = {}
    absp = os.path.abspath(file)
    ret["time"] = time.time()
    ret["commit"] = commit
    ret["size"] = os.path.getsize(file)
    stripped = "/tmp/" + str(uuid.uuid4())
    subprocess.run(["strip", "-s", file, "-o", stripped], check=True)
    ret["stripped_size"] = os.path.getsize(stripped)
    ret["projects"] = []
    with tempfile.TemporaryDirectory() as tmpdirname:
        os.chdir(tmpdirname)
        for url in PROJECTS.values():
            subprocess.run(
                ["git", "clone", "--depth=1", url],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True,
            )
        for proj_name in PROJECTS:
            print("Parsing", proj_name, file=sys.stderr)
            projobj = {}
            projobj["name"] = proj_name
            begin = datetime.datetime.now()
            for i in range(0, N_ITERATIONS):
                print("Iteration", i, file=sys.stderr)
                subprocess.run(
                    [absp, "--path", proj_name + "/meson.build"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=True,
                )
            end = datetime.datetime.now()
            projobj["parsing"] = (end - begin).total_seconds() * 1000
            lines = heaptrack(absp, proj_name, is_ci)
            projobj["memory_allocations"] = int(lines[-5].split(" ")[4])
            projobj["temporary_memory_allocations"] = int(lines[-4].split(" ")[3])
            projobj["peak_heap"] = lines[-3].split(" ")[4]
            projobj["peak_rss"] = lines[-2].split("): ")[1]
            ret["projects"].append(projobj)
    print(json.dumps(ret))


def main():
    parser = argparse.ArgumentParser(
        prog="collect_perf_data.py",
        description="Collect performance/memory usage characteristics",
    )
    parser.add_argument("--ci", action="store_true")
    parser.add_argument("filename")
    parser.add_argument("commit")
    args = parser.parse_args()
    analyze_file(args.filename, args.commit, args.ci)


if __name__ == "__main__":
    main()
