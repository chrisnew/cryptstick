#!/usr/bin/env bash
# ./mount.sh [container]

# you can store your settings in a separate file
CRYPTSTICK_CONFFILE="cs-settings.conf"

# first sleep time (after that it checks use and tries to unmount)
CRYPTSTICK_SLEEP_MAIN="15m"

# loop sleep time
CRYPTSTICK_SLEEP_LOOP="5m"

# mount log filename (we log every single mount) (optional)
CRYPTSTICK_LOG_MOUNTS=".mount.log"

# device mapper prefix
CRYPTSTICK_DEVICEMAPPER_PREFIX="cryptstick"

# mount options (how to mount the device mapped container) (both optional)
CRYPTSTICK_MOUNT_OPTIONS="noatime"
CRYPTSTICK_MOUNT_FILESYSTEM="ext4"

if [ -f "$CRYPTSTICK_CONFFILE" ]; then
 . "$CRYPTSTICK_CONFFILE"
fi

CRYPTSTICK_VERSION="1.0.0"
CRYPTSTICK_PRODUCT="cryptstick $CRYPTSTICK_VERSION"

echo "$CRYPTSTICK_PRODUCT - welcome."

if [ -z "$1" ]; then
  exec xterm -title "$CRYPTSTICK_PRODUCT" -e "sudo $0 - || sleep 5s"
fi

cd "$(dirname "$0")" || exit 1

imageName="$1"

if [ "$1" == "-" ]; then
 imageName=""
 find . -maxdepth 1 -mindepth 1 -type f -name '*.img' -exec basename {} .img \;
 echo -n "what to mount? "
 while [ -z "$imageName" ]; do
  read -r imageName
 done
fi

imageFile="$(pwd)/$imageName.img"
mappedName="$CRYPTSTICK_DEVICEMAPPER_PREFIX-$imageName"
mappedDevice="/dev/mapper/$mappedName"

if [ ! -f "$imageFile" ]; then
  (1>&2 echo "Error: could not find $imageName!")
  exit 1
fi

echo "selected container: $imageName"

# try to bind
if [ ! -e "$mappedDevice" ]; then
  echo -n "...opening luks device: "
  cryptsetup --type luks luksOpen "$imageFile" "$mappedName"  || exit 1
  echo "OK."
fi

echo -n "...checking $mappedDevice: "
(fsck -y "$mappedDevice" > /dev/null)

echo -n "...mounting $mappedDevice: "
mkdir -p "$imageName"

mountCmdLine="mount"

if [ -n "$CRYPTSTICK_MOUNT_FILESYSTEM" ]; then 
 mountCmdLine="$mountCmdLine -t $CRYPTSTICK_MOUNT_FILESYSTEM"
fi

mountCmdLine="$mountCmdLine $mappedDevice $imageName"

if [ -n "$CRYPTSTICK_MOUNT_OPTIONS" ]; then
 mountCmdLine="$mountCmdLine -o $CRYPTSTICK_MOUNT_OPTIONS"
fi

$mountCmdLine

if [ "$?" -ne 0 ]; then
 echo "mount failed, it was called that way:"
 echo "$mountCmdLine"
 
else
 echo "OK."
fi

if [ -n "$CRYPTSTICK_LOG_MOUNTS" ]; then
 mountLogFile="$imageName/$CRYPTSTICK_LOG_MOUNTS"

 if [ -e "$mountLogFile" ]; then
  echo
  echo -n "last usage was at "
  tail -n 1 "$mountLogFile"
  echo -n "count of usages: "
  wc -l < "$mountLogFile" 	
 fi

 touch "$mountLogFile"
 chmod 600 "$mountLogFile"
 date >> "$mountLogFile"
 chmod 400 "$mountLogFile"
fi

echo
echo "we are ready! now you got $CRYPTSTICK_SLEEP_MAIN to do your stuff."
echo

function shutdown {
 echo 

 # kill all accessers
 echo -n "...killing all remaining processes: "
 (fuser -s -k -n file -M -m "$imageName" &> /dev/null)
 echo "OK."

 # unmount and close device
 echo -n "...unmounting $mappedDevice: "
 umount "$mappedDevice" && echo "OK."

 echo -n "...closing $mappedName: "
 cryptsetup --type luks luksClose "$mappedName" && echo "OK."

 echo -n "...removing mount point: "
 rmdir "$imageName" && echo "OK."

 echo -n "...syncing device: "
 sync && echo "OK."

 echo
 echo "goodbye."

 sleep 2s
}

# hook at exit
trap shutdown EXIT

# let the user 15 minutes to do stuff
sleep $CRYPTSTICK_SLEEP_MAIN

# wait for user to complete
while [ -n "$(fuser -n file -M -m "$imageName" 2> /dev/null)" ] ; do
 clear

 echo -en "\a"

 echo 
 echo "Warning: there are still processes accessing the container!"

 echo

 fuser -v -n file -M -m "$imageName" 

 echo

 sleep $CRYPTSTICK_SLEEP_LOOP
done


