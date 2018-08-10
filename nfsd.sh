#!/bin/bash

set -e

# disable expansion of * in strngs
set -f

if [ -z "${ALLOWED_CLIENTS}" ]; then
	echo "Please set ALLOWED_CLIENTS"
	exit 1
fi

> /etc/exports
for CLIENT in ${ALLOWED_CLIENTS}; do
	echo "/export ${CLIENT}(fsid=root,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)" >> /etc/exports
done
set +f

# Make sure we react to these signals by running stop() when we see them - for clean shutdown
# And then exiting
trap "stop; exit 0;" SIGTERM SIGINT

stop()
{
  set +e
  # We're here because we've seen SIGTERM, likely via a Docker stop command or similar
  # Let's shutdown cleanly
  echo "SIGTERM caught, terminating NFS process(es)..."
  /usr/sbin/exportfs -uav
  pid1=$(pidof rpc.nfsd)
  pid2=$(pidof rpc.mountd)
  kill -TERM $pid1 $pid2 > /dev/null 2>&1
  echo "Terminated."
  exit
}

#echo "Starting rpcbind..."
#/sbin/rpcbind -w

echo "Starting rpc.nfsd in the background..."
/usr/sbin/rpc.nfsd --debug 8 --no-udp --no-nfs-version 2 --no-nfs-version 3
if [ $? != 0 ]; then
	echo
	echo "Unable to start rpc.nfsd - is the container running in privileged mode?"
	exit 1
fi

echo "Exporting File System..."
/usr/sbin/exportfs -rv
/usr/sbin/exportfs

echo "Starting rpc.mountd in the background..."
/usr/sbin/rpc.mountd --debug all --no-udp --no-nfs-version 2 --no-nfs-version 3
if [ $? != 0 ]; then
	echo
	echo "Unable to start rpc.mountd"
	exit 1
fi

echo "NFS server is listening on port 2049."
while true; do

	if [ -z $(pidof rpc.mountd) ]; then
		echo "rpc.mountd died - exiting"
		break
	fi

	sleep 1
done
