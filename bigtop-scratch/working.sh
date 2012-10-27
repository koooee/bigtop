#!/bin/bash -e

# script to create a working partition table inside a file within the filesystem.
# TODO: need to finagle this into a makefile

WORKING_DIR=/tmp

# file where we build the system
# think of this as a fake hard drive
# file name MUST have an extension.  Used to name other things in this script.
BUILD_FILE_NAME=scratch.img
BUILD_FILE_FULLPATH=$WORKING_DIR/$BUILD_FILE_NAME
BUILD_DIR=$WORKING_DIR/$(echo $BUILD_FILE_NAME | rev | cut -d. -f2);

pushd $WORKING_DIR

# make a 10G empty file
# TODO: this should be way smaller
echo -n "Creating 10G Empty File ..."
dd if=/dev/zero of=$BUILD_FILE_FULLPATH obs=512 count=20971520
echo "Done"

# create root and swap partitions on the empty file
cat <<EOF | fdisk $BUILD_FILE_FULLPATH
n
p
1

+500M
t
82
n
p
2


w
EOF

# check for clean loop environment
if [ $((`losetup -a | grep -c ^`)) -gt 0 ]; then
    echo "ERROR: Make sure your loop device environment is clean."
    echo "use: losetup -d /dev/loop{0..9}"
    echo "to remove loop devices"
    exit
fi

# set up loop devices so he tinks we are real devices.
losetup /dev/loop0 $BUILD_FILE_FULLPATH; 
fdisk -l $BUILD_FILE_FULLPATH | tail -n2 | awk '{print $2}' | while read line; do losetup -o $(($line-1)) /dev/loop$(($i+1)) /dev/loop0; i=$(($i+1)); done

# Per LFS book, we want to ensure a clean fs so use a clean build of e2fsprogs to ensure this.
# otherwise we could encounter boot issues
# TODO: need a good way to decouple this
wget -O - ftp://ftp.lfs-matrix.net/pub/lfs/lfs-packages/7.2/e2fsprogs-1.42.5.tar.gz | tar -xz
pushd e2fsprogs*/
mkdir e2fs_build
pushd e2fs_build

../configure && make

# make the ext3 file system on the root partition
./misc/mke2fs -jv /dev/loop2
tune2fs -c 0 /dev/loop2

# ensure a clean directory stack back at the working directory
dirs -c
pushd $WORKING_DIR

# clean up
rm -rf e2fsprogs*/