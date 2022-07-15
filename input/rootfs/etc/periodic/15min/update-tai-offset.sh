#!/bin/sh

# Uses parts from https://github.com/tlhackque/update-leap/blob/master/update-leap
# update-leap is Copyright (C) 2014 - 2022 Timothe Litt litt at acm dot org

# This script may be freely copied, used and modified providing that
# this notice and the copyright statement are included in all copies
# and derivative works.  No warranty is offered, and use is entirely at
# your own risk.  Bugfixes and improvements would be appreciated by the
# author.

set -e

PREFETCH="60 days"
LEAP_FILE=/data/leap-seconds.list

EXPIRES="0"
if [ -f "$LEAP_FILE" ]
then
    EXPIRES="$(sed -e'/^#@/!d' -e's/^#@//' "$LEAP_FILE" | tr -d '[:space:]')"
    EXPIRES="$(($EXPIRES - 2208988800 ))"
fi
if [ $EXPIRES -lt `date -d "NOW + $PREFETCH" +%s` ]
then
        wget -qO "$LEAP_FILE" 'https://www.ietf.org/timezones/data/leap-seconds.list'
        /etc/init.d/ts2phc restart
fi

TAI_OFFSET="$(grep -v '^#' "$LEAP_FILE" | tail -1 | awk '{ print $2 }')"

set-tai "$TAI_OFFSET"

pmc -u -b 0 \
"set GRANDMASTER_SETTINGS_NP
clockClass 10
clockAccuracy 0xf23
offsetScaledLogVariance 0xffff
currentUtcOffset $TAI_OFFSET
leap61 0
leap59 0
currentUtcOffsetValid 1
ptpTimescale 1
timeTraceable 1
frequencyTraceable 0
timeSource 0x20
"
