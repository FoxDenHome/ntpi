#!/usr/bin/env python3

from os import getenv, rename, unlink
from subprocess import check_output
from traceback import print_exc
from time import sleep

"""
Reference ID    : 50505300 (PPS)
Stratum         : 1
Ref time (UTC)  : Wed Jul 20 16:55:06 2022
System time     : 0.000000013 seconds fast of NTP time
Last offset     : +0.000000007 seconds
RMS offset      : 0.000000066 seconds
Frequency       : 8.912 ppm fast
Residual freq   : +0.000 ppm
Skew            : 0.001 ppm
Root delay      : 0.000000001 seconds
Root dispersion : 0.000022870 seconds
Update interval : 16.0 seconds
Leap status     : Normal

50505300,PPS,1,1658336361.519034090,-0.000000022,0.000000010,0.000000037,8.912,0.000,0.000,0.000000001,0.000019674,16.0,Normal
"""

CHRONY_COLUMNS = [
    "refid_num",
    False,  # "refid_str",
    "stratum",
    "ref_time",
    "system_time_offset",
    "last_offset",
    "rms_offset",
    "frequency",
    "residual_frequency",
    "skew",
    "root_delay",
    "root_dispersion",
    "update_interval",
    False,  # "leap_status",
]


def process_chrony_stats():
    stats = check_output(["chronyc", "-c", "-n", "tracking"],
                         encoding="utf-8").strip().split(",")

    res = []
    for idx, val in enumerate(stats):
        if not CHRONY_COLUMNS[idx]:
            continue
        res.append(f"chrony_{CHRONY_COLUMNS[idx]} {val}")

    return "\n".join(res)


def main():
    PROMETHEUS_METRICS_FILE = getenv("PROMETHEUS_METRICS_FILE")
    PROMETHEUS_METRICS_FILE_TMP = f"{PROMETHEUS_METRICS_FILE}.tmp"
    while True:
        try:
            stats = process_chrony_stats()
            with open(PROMETHEUS_METRICS_FILE_TMP, "w") as fh:
                fh.write(f"{stats}\n")

            unlink(PROMETHEUS_METRICS_FILE)
            rename(PROMETHEUS_METRICS_FILE_TMP, PROMETHEUS_METRICS_FILE)
        except:
            print_exc()
        sleep(10)


if __name__ == "__main__":
    main()
