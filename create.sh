#!/usr/bin/env bash

if [ -z "$2" ]; then
  echo "usage:"
  echo " sudo $0 name size [mkfs]"
  echo " sudo $0 my-container 1024M"
  echo
  echo "default value for mkfs: mkfs.ext4"
fi

name="$1.img"
size="$2"
mkfs="$3"
tempmapped="_cryptstick-temp-$RANDOM"

if [ -z "$mkfs" ]; then
 mkfs="mkfs.ext4"
fi

if [ -f "$name" ]; then
  echo "$name already exists! aborting.	" >&2
  exit 1
fi 	

# create blank image
dd if=/dev/zero of="$name" count="$2" iflag=count_bytes status=progress || exit 2

# create crypt device
cryptsetup -v --cipher aes-xts-plain64 --key-size 256 --hash sha256 --iter-time 2000 --use-urandom --verify-passphrase luksFormat "$name" || exit 3

# prepare the container itself
cryptsetup luksOpen "$name" "$tempmapped" || exit 4
$mkfs "/dev/mapper/$tempmapped" || exit 5
cryptsetup luksClose "$tempmapped" || exit 6

sync || exit 7

echo
echo done.
