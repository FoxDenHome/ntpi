#!/usr/bin/env python3

from gps import gps, WATCH_ENABLE, WATCH_NMEA
from socket import socket, AF_INET, SOCK_STREAM
from select import select
from threading import Thread
from traceback import print_exc
from time import sleep

IP = "127.0.0.1"
PORT = 9887
server = socket(AF_INET, SOCK_STREAM)
server.bind((IP, PORT))
server.listen(5)

rxset = [server]
txset = []


def close_socket(sock):
    sock.close()
    if sock in rxset:
        rxset.remove(sock)


def do_forward(nmea):
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
        rxfds, txfds, exfds = select(rxset, txset, rxset)
        for sock in rxfds:
            if sock is server:
                conn, _ = server.accept()
                conn.setblocking(0)
                rxset.append(conn)
                print("Accepted new client")
                continue

            try:
                sock.recv(512)
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


def main():
    gpsd_thread = Thread(target=handle_gpsd)
    gpsd_thread.start()
    sock_thread = Thread(target=handle_sockets)
    sock_thread.start()


if __name__ == "__main__":
    main()
