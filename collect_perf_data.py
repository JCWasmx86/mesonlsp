#!/usr/bin/env python3
# pylint: disable=missing-module-docstring,missing-function-docstring
import argparse
import datetime
import json
import os
import subprocess
import tempfile
import time
import uuid
import logging

PROJECTS = {
    "mesa": "https://gitlab.freedesktop.org/mesa/mesa/",
    "gnome-builder": "https://github.com/GNOME/gnome-builder",
    "qemu": "https://github.com/qemu/qemu",
    "GNOME-Builder-Plugins": "https://github.com/JCWasmx86/GNOME-Builder-Plugins",
    "gtk": "https://github.com/GNOME/gtk",
    "postgres": "https://github.com/postgres/postgres",
}

MISC_PROJECTS = {
    "glib": "https://github.com/GNOME/glib",
    "systemd": "https://github.com/systemd/systemd",
    "gitg": "https://github.com/GNOME/gitg",
    "code": "https://github.com/elementary/code",
    "vte": "https://github.com/GNOME/vte",
    "gnome-shell": "https://github.com/GNOME/gnome-shell",
    "evince": "https://github.com/GNOME/evince",
    "gjs": "https://github.com/GNOME/gjs",
    "rustc-demangle": "https://github.com/JCWasmx86/rustc-demangle",
    "libswiftdemangle": "https://github.com/JCWasmx86/libswiftdemangle",
    "dbus-broker": "https://github.com/bus1/dbus-broker",
    "cinnamon-desktop": "https://github.com/linuxmint/cinnamon-desktop",
    "cglm": "https://github.com/recp/cglm",
    "budgie-desktop": "https://github.com/BuddiesOfBudgie/budgie-desktop",
    "dxvk": "https://github.com/doitsujin/dxvk",
    "hexchat": "https://github.com/hexchat/hexchat",
    "knot-resolver": "https://gitlab.nic.cz/knot/knot-resolver",
    "le": "https://github.com/kirushyk/le",
    "lxc": "https://github.com/lxc/lxc",
    "libvirt": "https://gitlab.com/libvirt/libvirt",
    "libvips": "https://github.com/libvips/libvips",
    "miniz": "https://github.com/richgel999/miniz",
    "bubblewrap": "https://github.com/containers/bubblewrap",
    "scipy": "https://github.com/scipy/scipy",
    "bsdutils": "https://github.com/dcantrell/bsdutils",
    "bzip2": "https://gitlab.com/federicomenaquintero/bzip2",
    "frida-core": "https://github.com/frida/frida-core",
    "igt-gpu-tools": "https://gitlab.freedesktop.org/drm/igt-gpu-tools",
    "fwupd": "https://github.com/fwupd/fwupd",
    "mpv": "https://github.com/mpv-player/mpv",
}

N_ITERATIONS = 10
MISC_N_TIMES = 100


def heaptrack(command, is_ci):
    if not is_ci:
        with subprocess.Popen(
            ["heaptrack", "--record-only"] + command,
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
            ["heaptrack"] + command,
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


def clone_project(url):
    logging.info("Cloning " + url)
    subprocess.run(
        ["git", "clone", "--depth=1", url],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )


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
            clone_project(url)
        for url in MISC_PROJECTS.values():
            clone_project(url)
        ret["misc"] = {}
        projs = []
        for projname in MISC_PROJECTS.keys():
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
        ret["misc"]["parsing"] = (end - begin).total_seconds() * 1000
        ret["misc"]["memory_allocations"] = int(lines[-5].split(" ")[4])
        ret["misc"]["temporary_memory_allocations"] = int(lines[-4].split(" ")[3])
        ret["misc"]["peak_heap"] = lines[-3].split(" ")[4]
        ret["misc"]["peak_rss"] = lines[-2].split("): ")[1]
        for proj_name in PROJECTS:
            logging.info("Parsing " + proj_name)
            projobj = {}
            projobj["name"] = proj_name
            begin = datetime.datetime.now()
            command = [absp, "--path", proj_name + "/meson.build"]
            for i in range(0, N_ITERATIONS):
                logging.info("Iteration " + str(i))
                subprocess.run(
                    command,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=True,
                )
            end = datetime.datetime.now()
            projobj["parsing"] = (end - begin).total_seconds() * 1000
            logging.info("Tracing using heaptrack for " + proj_name)
            lines = heaptrack(command, is_ci)
            if lines[-1].startswith("suppressed leaks:"):
                lines = lines[:-1]
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
    logging.basicConfig(
        format="%(asctime)s %(levelname)-8s %(message)s", level=logging.INFO
    )
    main()
