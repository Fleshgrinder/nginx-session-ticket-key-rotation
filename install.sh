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
# TLS session ticket key install program.
#
# Note that user-defined function calls aren't documented in this script. Read
# the functions documentation for more information, but usually the name of the
# function should be sufficient to understand what's going on.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

# Check return value of EVERY command / function and bail in case of non-zero.
set -e

# Complete the usage information for this program.
ARGUMENTS='SERVER_NAME...'
DESCRIPTION='Install TLS session ticket key rotation for given server names.'

# Absolute path to the directory of this program.
WD=$(cd -- $(dirname -- "${0}"); pwd)

# Include the configuration with all variables and functions.
. "${WD}/config.sh"

# Make sure that the program was called correctly, we need the servers names.
if [ "${#}" -lt 1 ] 
then
  usage 2>&1
  exit 1
fi

[ "${VERBOSE}" = true ] && printf -- 'Checking environment ...\n'

super_user
check_ntpd
is_installed "${SERVER}"
check_server_version "${SERVER}" "${SERVER_MIN_VERSION}"
check_filesystem "${FILESYSTEMS_PATH}"

# Simple fail only checks, we have to make sure that the currently configured
# paths, etc. won't destroy anything already present on this system. Note that
# some checks are redundant but we want to be on the safe side.
#
# Read the fail message to understand what's going on.

[ -d "${KEY_PATH}" ] && \
fail "Directory ${YELLOW}${KEY_PATH}${NORMAL} exists"

grep -qs -- "${KEY_PATH}" /proc/mounts && \
fail "${YELLOW}${KEY_PATH}${NORMAL} already mounted"

grep -qs -- "${FSTAB_COMMENT}" /etc/fstab && \
fail "${YELLOW}/etc/fstab${NORMAL} entry already exists"

[ -f "${CRON_PATH}" ] && \
fail "Cron program ${YELLOW}${CRON_PATH}${NORMAL} already exists"

[ -f "${INIT_PATH}" ] && \
fail "System startup program ${YELLOW}${INIT_PATH}${NORMAL} already exists"

grep -qs -- " \$${INIT_NAME}" "${SERVER_INIT_PATH}" && \
fail "System startup dependency already exists in ${YELLOW}${SERVER_INIT_PATH}${NORMAL}"

# Use a trap in case of any unforseen signals and rollback.
trap uninstall 1 2 3 6 9 14 15

[ "${VERBOSE}" = true ] && printf -- 'Installing ...\n'

change_owner_and_make_scripts_executable "${WD}" 'root'
create_directory "${KEY_PATH}" 'root'

# Not all options have an effect if the preferred `ramfs` file system is used.
readonly FILESYSTEM_OPTIONS="async,mode=770,noauto,noatime,nodev,nodiratime,noexec,nosuid,rw,size=${#}m"
mount_filesystem "${FILESYSTEM}" "${FILESYSTEM_OPTIONS}" "${KEY_PATH}"
add_fstab_entry "${FILESYSTEM}" "${FILESYSTEM_OPTIONS}" "${KEY_PATH}" '/etc/fstab'
create_cron_job "${CRON_PATH}" "${WD}/generator.sh" "$(echo ${@})"
generate_keys "${@}"
create_init_script "${INIT_PATH}" "${WD}/generator.sh" "$(echo ${@})"
create_init_links "${INIT_PATH}"
create_init_dependency "${INIT_PATH}" "${SERVER_INIT_PATH}"

[ "${VERBOSE}" = true ] && printf 'Installtion successful.\n'
exit 0
