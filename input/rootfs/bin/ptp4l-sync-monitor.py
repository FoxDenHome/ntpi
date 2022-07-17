#!/usr/bin/env python3

from dataclasses import dataclass
from datetime import datetime
from os import getenv, rename, unlink
from sys import stderr, stdout, argv
from subprocess import Popen, PIPE
from threading import Thread
from queue import Queue
from time import sleep
from signal import alarm, signal, SIGALRM, SIGTERM
from re import match
from typing import Optional


NO_UPDATE_TIMEOUT = 15
METRIC_TIMEOUT = 5


class AsynchronousFileReader(Thread):
    def __init__(self, fd):
        assert callable(fd.readline)
        Thread.__init__(self, daemon=True)
        self._fd = fd
        self.queue = Queue()

    def run(self):
        for line in iter(self._fd.readline, ""):
            self.queue.put(line)

    def eof(self):
        return not self.is_alive() and self.queue.empty()


def write_stderr(text):
    stderr.write(text)
    stderr.flush()


@dataclass
class Ptp4LSyncSlave:
    name: str
    master: str
    offset: int
    state: int
    frequency: int
    delay: Optional[int]
    time: float


class Ptp4LSyncMonitor:
    args: list[str]
    process: Popen
    slaves: map
    metrics_file: str

    def __init__(self, metrics_file, args):
        self.args = args
        self.metrics_file = metrics_file
        self.metrics_file_tmp = f"{metrics_file}.tmp"
        self.process = None
        self.slaves = {}
        signal(SIGALRM, self.sighandler)

    def send_console(self, line):
        self.process.stdin.write(f"{line.strip()}\n")
        self.process.stdin.flush()

    def reset_alarm(self):
        alarm(NO_UPDATE_TIMEOUT)

    def sighandler(self, _, __):
        self.stop()

    def stop(self):
        if self.process is not None:
            self.process.send_signal(SIGTERM)

    def wait(self):
        if self.process is not None:
            self.process.wait()

    def run(self):
        self.process = Popen(self.args, stdin=PIPE,
                             stdout=PIPE, stderr=PIPE, encoding="utf-8")

        stdout_reader = AsynchronousFileReader(self.process.stdout)
        stdout_reader.start()
        stderr_reader = AsynchronousFileReader(self.process.stderr)
        stderr_reader.start()

        self.reset_alarm()

        while not stdout_reader.eof() or not stderr_reader.eof():
            while not stdout_reader.queue.empty():
                line = stdout_reader.queue.get()
                self.handle_line(line, stdout)

            while not stderr_reader.queue.empty():
                line = stderr_reader.queue.get()
                self.handle_line(line, stderr)

            sleep(.1)

        self.process.stdout.close()
        self.process.stderr.close()
        self.process.stdin.close()

        stdout_reader.join()
        stderr_reader.join()

        self.process.wait()
        self.process = None
        self.slaves = {}

    def produce_prometheus_metrics(self, fh):
        fh.write("# TYPE ptp4l_sync_offset gauge\n")
        fh.write("# TYPE ptp4l_sync_frequency gauge\n")
        fh.write("# TYPE ptp4l_sync_delay gauge\n")
        fh.write("# TYPE ptp4l_sync_state gauge\n")

        fh.write("# HELP ptp4l_sync_offset PTP4L Sync offset in nanoseconds\n")
        fh.write(
            "# HELP ptp4l_sync_frequency PTP4L Sync frequency correction in ppb\n")
        fh.write("# HELP ptp4l_sync_delay PTP4L Sync delay in ns\n")
        fh.write(
            "# HELP ptp4l_sync_state PTP4L Sync state (1 = unlocked, 2 = locked)\n")

        now_time = datetime.now().timestamp()
        for slave in self.slaves.values():
            if now_time - METRIC_TIMEOUT > slave.time:
                continue
            tags = f"{{slave=\"{slave.name}\",master=\"{slave.master}\"}}"
            fh.write(f"ptp4l_sync_offset{tags} {slave.offset}\n")
            fh.write(f"ptp4l_sync_frequency{tags} {slave.frequency}\n")
            fh.write(f"ptp4l_sync_state{tags} {slave.state}\n")
            if slave.delay is not None:
                fh.write(f"ptp4l_sync_delay{tags} {slave.delay}\n")

    def write_prometheus_metrics(self):
        with open(self.metrics_file_tmp, "w") as fh:
            self.produce_prometheus_metrics(fh)

        try:
            unlink(self.metrics_file)
        except FileNotFoundError:
            pass

        rename(self.metrics_file_tmp, self.metrics_file)

    def handle_line(self, line, stream):

        m = match(
            "\\w+\\[[^\\]]+\\]:?\\s+([^\\s]+)\\s+([^\\s]+)\\s+offset\\s+([-+\\d]+)\\s+s(\d+)\s+freq\\s+([-+\\d]+)(?:\\s+delay\\s+([-+\\d]+))?", line)

        if not m:
            stream.write(line)
            stream.flush()
            return

        slave = Ptp4LSyncSlave(time=datetime.now().timestamp(), name=m[1], master=m[2],
                               offset=int(m[3], 10), state=int(m[4], 10), frequency=int(m[5], 10), delay=None)
        if m[6]:
            slave.delay = int(m[6], 10)

        self.slaves[slave.name] = slave

        self.reset_alarm()
        self.write_prometheus_metrics()


def main():
    mon = Ptp4LSyncMonitor(metrics_file=getenv(
        "PROMETHEUS_METRICS_FILE"), args=argv[1:])
    while True:
        mon.run()


if __name__ == "__main__":
    main()

# [96.342] CLOCK_REALTIME phc offset 1657942939174066955 s0 freq      +0 delay 876567
# [586.277] eth0.2 master offset -157271327 s2 freq -100000000
# phc2sys[12688.853]: CLOCK_REALTIME phc offset    -16516 s0 freq      +0 delay  58777
