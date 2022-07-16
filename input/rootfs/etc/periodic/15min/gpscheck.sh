#!/bin/sh
export PATH=/usr/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin

echo -n 'Checking gpsd... '
if ! timeout 5s gpspipe -w -n 5 > /dev/null
then
	echo 'FAIL! Restarting...'
	killall gpsd
	/etc/init.d/gpsd restart
else
	echo 'OK.'
fi
