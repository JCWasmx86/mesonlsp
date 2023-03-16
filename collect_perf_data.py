#!/usr/bin/env python3
# pylint: disable=missing-module-docstring,missing-function-docstring,bare-except
import argparse
import datetime
import json
import logging
import os
import subprocess
import time
import uuid
from functools import reduce

PROJECTS = {
    "gnome-builder": "https://github.com/GNOME/gnome-builder",
    "GNOME-Builder-Plugins": "https://github.com/JCWasmx86/GNOME-Builder-Plugins",
    "gtk": "https://github.com/GNOME/gtk",
    "mesa": "https://gitlab.freedesktop.org/mesa/mesa/",
    "postgres": "https://github.com/postgres/postgres",
    "qemu": "https://github.com/qemu/qemu",
}

MISC_PROJECTS = {
    "bsdutils": "https://github.com/dcantrell/bsdutils",
    "bubblewrap": "https://github.com/containers/bubblewrap",
    "budgie-desktop": "https://github.com/BuddiesOfBudgie/budgie-desktop",
    "bzip2": "https://gitlab.com/federicomenaquintero/bzip2",
    "cglm": "https://github.com/recp/cglm",
    "cinnamon-desktop": "https://github.com/linuxmint/cinnamon-desktop",
    "code": "https://github.com/elementary/code",
    "dbus-broker": "https://github.com/bus1/dbus-broker",
    "dxvk": "https://github.com/doitsujin/dxvk",
    "evince": "https://github.com/GNOME/evince",
    "frida-core": "https://github.com/frida/frida-core",
    "fwupd": "https://github.com/fwupd/fwupd",
    "gitg": "https://github.com/GNOME/gitg",
    "gjs": "https://github.com/GNOME/gjs",
    "glib": "https://github.com/GNOME/glib",
    "gnome-shell": "https://github.com/GNOME/gnome-shell",
    "hexchat": "https://github.com/hexchat/hexchat",
    "igt-gpu-tools": "https://gitlab.freedesktop.org/drm/igt-gpu-tools",
    "knot-resolver": "https://gitlab.nic.cz/knot/knot-resolver",
    "le": "https://github.com/kirushyk/le",
    "libswiftdemangle": "https://github.com/JCWasmx86/libswiftdemangle",
    "libvips": "https://github.com/libvips/libvips",
    "libvirt": "https://gitlab.com/libvirt/libvirt",
    "lxc": "https://github.com/lxc/lxc",
    "miniz": "https://github.com/richgel999/miniz",
    "mpv": "https://github.com/mpv-player/mpv",
    "pipewire": "https://github.com/PipeWire/pipewire",
    "rustc-demangle": "https://github.com/JCWasmx86/rustc-demangle",
    "scipy": "https://github.com/scipy/scipy",
    "systemd": "https://github.com/systemd/systemd",
    "vte": "https://github.com/GNOME/vte",
    "xts": "https://gitlab.freedesktop.org/xorg/test/xts",
    "zrythm": "https://git.sr.ht/%7Ealextee/zrythm",
}

N_ITERATIONS = 10
MISC_N_TIMES = 100
MS_IN_S = 1000
N_REPEATS_IF_TOO_SHORT = 50
TOO_SHORT_THRESHOLD = 1500


def base_path():
    home = os.path.expanduser("~")
    full_path = home + "/.cache/" + "swift-mesonlsp-benchmarks"
    try:
        os.mkdir(full_path)
    except:
        pass
    return full_path


def heaptrack(command, is_ci):
    base_command = ["heaptrack"]
    if not is_ci:
        base_command += ["--record-only"]

    with subprocess.Popen(
        base_command + command,
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
            os.remove(zstfile)
            return lines


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
    for name, url in MISC_PROJECTS.items():
        clone_project(name, url)


def basic_analysis(ret, file, commit):
    ret["time"] = time.time()
    ret["commit"] = commit
    ret["size"] = os.path.getsize(file)
    stripped = "/tmp/" + str(uuid.uuid4())
    subprocess.run(["strip", "-s", file, "-o", stripped], check=True)
    ret["stripped_size"] = os.path.getsize(stripped)
    os.remove(stripped)


def quick_parse(ret, absp):
    for proj_name in reduce(lambda x, y: dict(x, **y), (MISC_PROJECTS, PROJECTS)):
        logging.info("Quick parsing %s", proj_name)
        command = [absp, "--path", proj_name + "/meson.build"]
        begin = datetime.datetime.now()
        subprocess.run(
            command,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
        end = datetime.datetime.now()
        duration = (end - begin).total_seconds() * MS_IN_S
        if duration < TOO_SHORT_THRESHOLD:
            logging.info("Too fast, repeating with more iterations: %s", str(duration))
            command = [absp] + (
                [proj_name + "/meson.build"] * (N_REPEATS_IF_TOO_SHORT * 101)
            )
            begin = datetime.datetime.now()
            subprocess.run(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True,
            )
            end = datetime.datetime.now()
            duration = (
                (end - begin).total_seconds() * MS_IN_S
            ) / N_REPEATS_IF_TOO_SHORT
            logging.info("New duration: %s", str(duration))
        ret["quick"][proj_name] = duration


def misc_parse(ret, absp, is_ci):
    projs = []
    for projname in MISC_PROJECTS:
        projs.append(projname + "/meson.build")
    command = [absp] + (projs * MISC_N_TIMES)
    logging.info("Parsing misc")
    begin = datetime.datetime.now()
    subprocess.run(
        command,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )
    end = datetime.datetime.now()
    logging.info("Tracing using heaptrack for misc")
    lines = heaptrack(command, is_ci)
    if lines[-1].startswith("suppressed leaks:"):
        lines = lines[:-1]
    ret["misc"]["parsing"] = (end - begin).total_seconds() * MS_IN_S
    ret["misc"]["memory_allocations"] = int(lines[-5].split(" ")[4])
    ret["misc"]["temporary_memory_allocations"] = int(lines[-4].split(" ")[3])
    ret["misc"]["peak_heap"] = lines[-3].split(" ")[4]
    ret["misc"]["peak_rss"] = lines[-2].split("): ")[1]


def projects_parse(ret, absp, is_ci):
    for proj_name in PROJECTS:
        logging.info("Parsing %s", proj_name)
        projobj = {}
        projobj["name"] = proj_name
        begin = datetime.datetime.now()
        command = [absp, "--path", proj_name + "/meson.build"]
        for i in range(0, N_ITERATIONS):
            logging.info("Iteration %s", str(i))
            subprocess.run(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True,
            )
        end = datetime.datetime.now()
        projobj["parsing"] = (end - begin).total_seconds() * MS_IN_S
        logging.info("Tracing using heaptrack for %s", proj_name)
        lines = heaptrack(command, is_ci)
        if lines[-1].startswith("suppressed leaks:"):
            lines = lines[:-1]
        projobj["memory_allocations"] = int(lines[-5].split(" ")[4])
        projobj["temporary_memory_allocations"] = int(lines[-4].split(" ")[3])
        projobj["peak_heap"] = lines[-3].split(" ")[4]
        projobj["peak_rss"] = lines[-2].split("): ")[1]
        ret["projects"].append(projobj)


def analyze_file(file, commit, is_ci):
    logging.info("Base path: %s", base_path())
    ret = {}
    basic_analysis(ret, file, commit)
    absp = os.path.abspath(file)
    os.chdir(base_path())
    clone_projects()
    ret["quick"] = {}
    quick_parse(ret, absp)
    ret["misc"] = {}
    misc_parse(ret, absp, is_ci)
    ret["projects"] = []
    projects_parse(ret, absp, is_ci)
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
    logging.basicConfig(
        format="%(asctime)s %(levelname)-8s %(message)s", level=logging.INFO
    )
    main()
