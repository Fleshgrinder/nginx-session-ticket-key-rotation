#!/bin/sh

# ------------------------------------------------------------------------------
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# is_installed() unit test
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

WD=$(cd -- $(dirname -- "${0}"); pwd)
. "${WD}/test.sh"

# Create random file name and be sure to delete it on exit.
TMP=/tmp/filesystems-$(od -N4 -tu -- /dev/urandom | awk -- 'NR==1 {print $2} {}')
trap -- "rm -f ${TMP}" 0 1 2 3 6 9 14 15

# ------------------------------------------------------------------------------
# This fstab is taken from a Mint installation with ramfs.
cat << EOT > "${TMP}"
nodev	sysfs
nodev	rootfs
nodev	ramfs
nodev	bdev
nodev	proc
nodev	cgroup
nodev	cpuset
nodev	tmpfs
nodev	devtmpfs
nodev	debugfs
nodev	securityfs
nodev	sockfs
nodev	pipefs
nodev	anon_inodefs
nodev	devpts
	ext3
	ext2
	ext4
nodev	hugetlbfs
	vfat
nodev	ecryptfs
	fuseblk
nodev	fuse
nodev	fusectl
nodev	pstore
nodev	mqueue
nodev	binfmt_misc
nodev	vboxsf
	xfs
	jfs
	msdos
	ntfs
	minix
	hfs
	hfsplus
	qnx4
	ufs
	btrfs
EOT
check_filesystem "${TMP}" && test_ok || test_fail
[ "${FILESYSTEM}" = ramfs ] && test_ok || test_fail

# ------------------------------------------------------------------------------
# This fstab is taken from an OVZ VPS.
cat << EOT > "${TMP}"
nodev   cgroup
nodev   devpts
nodev   mqueue
        ext4
nodev   nfs
nodev   nfs4
nodev   delayfs
nodev   devtmpfs
nodev   sysfs
nodev   proc
nodev   tmpfs
nodev   binfmt_misc
nodev   fusectl
nodev   fuse
EOT
check_filesystem "${TMP}" && test_ok || test_fail
[ "${FILESYSTEM}" = tmpfs ] && test_ok || test_fail

# ------------------------------------------------------------------------------
# Well, you guessed.
cat /dev/null > "${TMP}"
check_filesystem "${TMP}" && test_fail || test_ok
