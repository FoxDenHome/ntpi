#!/usr/bin/env python3
from abc import ABC, abstractmethod
from re import split
from traceback import print_exc
from requests import get
from datetime import datetime, timedelta
from subprocess import check_call
from sys import stderr
from time import sleep
from cffi import FFI

LEAP_FILE = "/data/leap-seconds.list"
LEAP_FILE_URL = "https://data.iana.org/time-zones/data/leap-seconds.list"
NTP_UTC_OFFSET = 2208988800
LEAP_FILE_RENEWAL_TIMEOUT = timedelta(days=60)

WAIT_TIME_CONFIGURATE = 15 * 60


def ntp2datetime(time):
    return datetime.fromtimestamp(time - NTP_UTC_OFFSET, datetime.timezone.utc)


class LeapFile():
    def __init__(self, file, url, renewal_timeout):
        self.file = file
        self.url = url
        self.renewal_timeout = renewal_timeout
        self.expiry = None
        self.loaded = False

        self.time_map = {}
        self.times_sorted = []

    def reload(self):
        with open(self.file, "r") as fh:
            data = fh.read()
            self.parse(data)
        self.loaded = True

    def load(self):
        if self.loaded:
            return
        self.reload()

    def current_utc_tai_offset(self):
        self.load()
        now = datetime.utcnow()
        for time in self.times_sorted:
            if time <= now:
                return self.time_map[time]
        return 0

    def update(self, force=False):
        try:
            self.load()
        except FileNotFoundError:
            pass

        min_expiry = datetime.utcnow() + self.renewal_timeout
        if (not force) and self.expiry is not None and (self.expiry >= min_expiry):
            return False

        res = get(url=self.url, timeout=10)
        res.raise_for_status()
        with open(self.file, "w") as fh:
            fh.write(res.text)

        if self.loaded:
            self.reload()

        return True

    def parse(self, data):
        self.time_map = {}
        self.times_sorted = []

        for line in data.split("\n"):
            line = line.strip()
            if len(line) < 1:
                continue
            if line[0] == "#":
                if len(line) < 2:
                    continue
                if line[1] == "@":
                    self.expiry = ntp2datetime(int(line[2:].strip(), 10))
            else:
                spl = split("\\s+", line)
                time = int(spl[0], 10)
                offset = int(spl[1], 10)
                self.time_map[ntp2datetime(time)] = offset

        self.times_sorted = sorted(self.time_map.keys(), reverse=True)


class Configuator(ABC):
    @abstractmethod
    def configure(self, did_update):
        pass


class PTP4LConfigurator(Configuator):
    def __init__(self, leapfile):
        self.leapfile = leapfile
        self.clock_class = 10
        self.clock_accuracy = 0x23
        self.time_source = 0x20
        self.time_traceable = True
        self.frequency_traceable = False
        self.offset_scaled_log_variance = 0xFFFF

    def configure(self, did_update):
        check_call([
            "pmc", "-u", "-b", "0", "-f", "/etc/ptp4l.conf",
            f"""set GRANDMASTER_SETTINGS_NP
clockClass {self.clock_class}
clockAccuracy {self.clock_accuracy:#04x}
offsetScaledLogVariance {self.offset_scaled_log_variance:#04x}
currentUtcOffset {self.leapfile.current_utc_tai_offset()}
leap61 0
leap59 0
currentUtcOffsetValid 1
ptpTimescale 1
timeTraceable {int(self.time_traceable)}
frequencyTraceable {int(self.frequency_traceable)}
timeSource {self.time_source:#02x}
"""
        ])


ADJ_TAI = 0x0080


class KernelConfigurator(Configuator):
    def __init__(self, leapfile):
        self.leapfile = leapfile
        self.ffi = FFI()
        self.ffi.cdef("""
typedef long time_t;
typedef long suseconds_t;

struct timex
{
    unsigned modes;
    long offset, freq, maxerror, esterror;
    int status;
    long constant, precision, tolerance;
    struct timeval time;
    long tick, ppsfreq, jitter;
    int shift;
    long stabil, jitcnt, calcnt, errcnt, stbcnt;
    int tai;
    int __padding[11];
};

struct timeval
{
    time_t tv_sec;
    suseconds_t tv_usec;
};

int adjtimex(struct timex *buf);
""")
        self.ffi_lib = self.ffi.dlopen(None)

    def configure(self, did_update):
        offset = self.leapfile.current_utc_tai_offset()

        tx = self.ffi.new("struct timex*")
        tx.modes = ADJ_TAI
        tx.constant = offset
        self.ffi_lib.adjtimex(tx)
        if tx.tai != offset:
            raise ValueError("Could not use adjtimex to update UTC-TAI offset")


def print_stderr(msg):
    stderr.write(f"{msg}\n")
    stderr.flush()


def main():
    leapfile = LeapFile(LEAP_FILE, LEAP_FILE_URL, LEAP_FILE_RENEWAL_TIMEOUT)

    configuators = []

    def add_configurator(ConfiguratorClass):
        try:
            configurator = ConfiguratorClass(leapfile=leapfile)
            configuators.append(configurator)
        except Exception:
            stderr.write(f"Error loading configurator {ConfiguratorClass}:\n")
            print_exc()
            stderr.flush()

    #add_configurator(PTP4LConfigurator)
    add_configurator(KernelConfigurator)

    did_update = True
    while True:
        stderr.write("Running check loop...\n")
        stderr.flush()

        for configuator in configuators:
            try:
                configuator.configure(did_update)
            except Exception:
                stderr.write(f"Error running configuator {configuator}:\n")
                print_exc(file=stderr)
                stderr.flush()

        try:
            did_update = leapfile.update()
        except Exception:
            stderr.write("Error updating leapfile:\n")
            print_exc(file=stderr)
            stderr.flush()

        stderr.write("Check loop complete!\n")
        stderr.flush()

        sleep(WAIT_TIME_CONFIGURATE)


if __name__ == "__main__":
    main()
