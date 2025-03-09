#!/usr/bin/env python3

from gps import gps, WATCH_ENABLE, WATCH_NMEA
from socket import socket, AF_INET, SOCK_STREAM, IPPROTO_TCP, TCP_NODELAY, SOL_SOCKET, SO_REUSEADDR
from select import select
from threading import Thread
from traceback import print_exc
from time import sleep
from signal import alarm, signal, SIGALRM
from sys import exit

IP = "127.0.0.1"
PORT = 9887
GPSD_IDLE_TIMEOUT_SECONDS = 60

server = socket(AF_INET, SOCK_STREAM)
server.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
server.bind((IP, PORT))
server.listen(5)
server.setsockopt(IPPROTO_TCP, TCP_NODELAY, 1)

rxset = [server]

def feed_wd():
    alarm(GPSD_IDLE_TIMEOUT_SECONDS)

def close_socket(sock):
    if sock in rxset:
        rxset.remove(sock)
        print("Closing client", sock)
    sock.close()


def do_forward(nmea):
    feed_wd()
    for sock in rxset:
        if sock is server:
            continue
        try:
            sock.send(nmea)
        except:
            close_socket(sock)
            print_exc()


def handle_sockets():
    while True:
        rxfds, _, _ = select(rxset, [], [])
        for sock in rxfds:
            if sock is server:
                conn, _ = server.accept()
                conn.setblocking(0)
                conn.setsockopt(IPPROTO_TCP, TCP_NODELAY, 1)
                rxset.append(conn)
                print("Accepted new client", conn)
                continue

            try:
                data = sock.recv(512)
                if not data:
                    close_socket(sock)
            except:
                close_socket(sock)
                print_exc()


def handle_gpsd():
    while True:
        gpsd = gps(mode=WATCH_ENABLE | WATCH_NMEA)
        try:
            while True:
                report = gpsd.next()
                resp = gpsd.response
                if report["class"] == "DEVICE":
                    gpsd.close()
                    gpsd = gps(mode=WATCH_ENABLE | WATCH_NMEA)
                    continue

                if resp and resp[0] == "$":
                    do_forward(resp.encode("ascii"))
        except:
            print_exc()
        sleep(1)

def handle_wd_timeout(signum, frame):
    print("GPSD idle timeout", flush=True)
    exit(1)

def main():
    signal(SIGALRM, handle_wd_timeout)
    feed_wd()

    gpsd_thread = Thread(target=handle_gpsd)
    gpsd_thread.start()
    sock_thread = Thread(target=handle_sockets)
    sock_thread.start()


if __name__ == "__main__":
    main()
