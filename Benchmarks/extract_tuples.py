#!/usr/bin/env python3
import subprocess
import datetime
import sys
import json


def extract_day_hour(date_str):
    date = datetime.datetime.strptime(date_str, '"%a %b %d %H:%M:%S %Y %z"')
    return date.strftime("%A"), date.strftime("%H")


if __name__ == "__main__":
    try:
        git_log = subprocess.check_output(
            ["git", "log", '--pretty=format:"%ad"'], stderr=subprocess.STDOUT
        ).decode("utf-8")
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e.returncode}")
        print(e.output.decode("utf-8"))
        sys.exit(1)
    commit_entries = git_log.split("\n")
    commit_data = {}
    for entry in commit_entries:
        if entry:
            day, hour = extract_day_hour(entry)
            if (day, hour) not in commit_data:
                commit_data[(day, hour)] = 1
            else:
                commit_data[(day, hour)] += 1
    json_data = []
    days_of_week = [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday",
    ]

    for day in days_of_week:
        for hour in range(24):
            hour_str = str(hour).zfill(2)
            if (day, hour_str) in commit_data:
                json_data.append(
                    {
                        "day": day,
                        "hour": hour_str,
                        "commits": commit_data[(day, hour_str)],
                    }
                )
            else:
                json_data.append(
                    {
                        "day": day,
                        "hour": hour_str,
                        "commits": 0,
                    }
                )
    json_output = json.dumps(json_data, indent=2)
    print(json_output)
