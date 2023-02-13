#!/usr/bin/env python3
import argparse
import os
import uuid
import subprocess
import json
import tempfile
import datetime
import time
import sys


PROJECTS = {
    "mesa": "https://gitlab.freedesktop.org/mesa/mesa/",
    "gnome-builder": "https://github.com/GNOME/gnome-builder",
    "qemu": "https://github.com/qemu/qemu",
    "GNOME-Builder-Plugins": "https://github.com/JCWasmx86/GNOME-Builder-Plugins",
}
N_ITERATIONS = 10


def heaptrack(absp, d, ci):
    if not ci:
        with subprocess.Popen(
            ["heaptrack", "--record-only", absp, "--path", d + "/meson.build"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ) as prof_proces:
            stdout, stderr = prof_proces.communicate()
            lines = stdout.decode("utf-8").splitlines()
            zstfile = lines[-1].strip().split(" ")[2].replace('"', "")
            with subprocess.Popen(
                ["heaptrack_print", zstfile],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            ) as ana_process:
                stdout, stderr = ana_process.communicate()
                lines = stdout.decode("utf-8").splitlines()
                return lines
    else:
        # Because Ubuntu has too old software, so --record-only is not known
        # and github has no runners for modern distributions
        with subprocess.Popen(
            ["heaptrack", absp, "--path", d + "/meson.build"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ) as prof_proces:
            stdout, stderr = prof_proces.communicate()
            lines = stdout.decode("utf-8").splitlines()
            zstfile = lines[-1].strip().split(" ")[2].replace('"', "")
            with subprocess.Popen(
                ["heaptrack_print", zstfile],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            ) as ana_process:
                stdout, stderr = ana_process.communicate()
                lines = stdout.decode("utf-8").splitlines()
                return lines
    assert False


def analyze_file(file, commit, ci):
    ret = {}
    absp = os.path.abspath(file)
    ret["time"] = time.time()
    ret["commit"] = commit
    ret["size"] = os.path.getsize(file)
    stripped = "/tmp/" + str(uuid.uuid4())
    subprocess.run(["strip", "-s", file, "-o", stripped])
    ret["stripped_size"] = os.path.getsize(stripped)
    ret["projects"] = []
    with tempfile.TemporaryDirectory() as tmpdirname:
        os.chdir(tmpdirname)
        for d in PROJECTS:
            projobj = {}
            projobj["name"] = d
            subprocess.run(
                ["git", "clone", "--depth=1", PROJECTS[d]],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            a = datetime.datetime.now()
            for i in range(0, N_ITERATIONS):
                subprocess.run(
                    [absp, "--path", d + "/meson.build"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            b = datetime.datetime.now()
            projobj["parsing"] = (b - a).total_seconds() * 1000
            lines = heaptrack(absp, d, ci)
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
