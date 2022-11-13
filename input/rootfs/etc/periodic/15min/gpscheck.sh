#!/bin/sh
export PATH=/usr/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin

echo -n 'Checking gpsd... '
if ! timeout 5s gpspipe -w -n 5 > /dev/null
then
	echo 'FAIL! Restarting...'
	s6-svc -k -wr /run/service/gpsd
else
	echo 'OK.'
fi
