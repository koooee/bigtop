# Makefile for building a bare bones linux distribution for running the apache hadoop ecosystem
SHELL := /bin/bash
WORKING_DIR=/tmp

BUILD_FILE_NAME=scratch.img
BUILD_FILE_FULLPATH=$(WORKING_DIR)/$(BUILD_FILE_NAME)
BUILD_DIR=$(WORKING_DIR)/$(echo $BUILD_FILE_NAME | rev | cut -d. -f2);
E2FS=ftp://ftp.lfs-matrix.net/pub/lfs/lfs-packages/7.2/e2fsprogs-1.42.5.tar.gz
#10G
#HD_SIZE=10737418240
HD_SIZE=1000000000
BLOCK_SIZE=512
BLOCKS=$(shell echo $(HD_SIZE)/$(BLOCK_SIZE) | bc)

scratch: partitions

partitions: create_blank_file create_filelayout setup_loopdevices build_e2fs create_filesystem clean_e2fs

clean: clean_e2fs clean_partition
clean_e2fs:
	rm -rf $(WORKING_DIR)/e2fsprogs*/
clean_partition:
	rm $(BUILD_FILE_FULLPATH)
clean_loopdevices: 
	losetup -d /dev/loop{1..2}; losetup -d /dev/loop0;

create_blank_file:
	@echo "Creating blank file..."
	dd if=/dev/zero of=$(BUILD_FILE_FULLPATH) obs=$(BLOCK_SIZE) count=$(BLOCKS)
	@echo "Done"
create_filelayout: create_blank_file

#sketchy.  Is this really the way to do this without make a seperate file?
	@echo "n" > temp.txt
	@echo "p" >> temp.txt
	@echo "1" >> temp.txt
	@echo "" >> temp.txt
	@echo "+500M" >> temp.txt
	@echo "t" >> temp.txt
	@echo "82" >> temp.txt
	@echo "n" >> temp.txt
	@echo "p" >> temp.txt
	@echo "2" >> temp.txt
	@echo "" >> temp.txt
	@echo "" >> temp.txt
	@echo "w" >> temp.txt

	fdisk $(BUILD_FILE_FULLPATH) < temp.txt
	rm temp.txt

check_loopdevices:
# check for clean loop environment
	@if [ "$(shell expr `losetup -a | grep -c ^` \> 0)" -eq "1" ]; then \
		echo "$(shell expr `losetup -a | grep -c ^` \> 0)"; \
		echo "ERROR: Make sure your loop device environment is clean."; \
		echo "use: losetup -d /dev/loop{0..9}"; \
		echo "to remove loop devices"; \
		exit 2; \
	else \
		echo "Loop Devices Clean"; \
	fi


# so he tinks we are real devices.
setup_loopdevices: create_filelayout check_loopdevices
	losetup /dev/loop0 $(BUILD_FILE_FULLPATH); \
	fdisk -l $(BUILD_FILE_FULLPATH) \
	| tail -n2 | awk '{print $$2}' \
	| while read line; do \
		echo $$line; \
		losetup -o $$(echo "$$line-1" | bc) /dev/loop$$(echo "$$i+1" | bc) /dev/loop0; i=$$(echo "$$i+1" | bc); done
# Do this to ensure a clean FS toolchain
# if we use the system built FS toolchain funky boot stuff can happen, per LFS book
build_e2fs: setup_loopdevices
	pushd $(WORKING_DIR); wget -O - $(E2FS) | tar -xz; pushd e2fsprogs*/; mkdir e2fs_build; pushd e2fs_build; ../configure; make
	dirs -c
create_filesystem: build_e2fs
	pushd $(WORKING_DIR)/e2fsprogs*/e2fs_build; ./misc/mke2fs -jv /dev/loop2; ./misc/tune2fs -c 0 /dev/loop2;
	dirs -c
