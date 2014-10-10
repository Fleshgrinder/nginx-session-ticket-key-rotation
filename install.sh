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
# nginx TLS session ticket key install program.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

# Load configuration and start program.
. './config.sh'

# Make sure that the program was invoked correctly.
if [ "${#}" -le 1 ]
then
  cat << EOT
Usage: ${0} SERVER_NAME...
Install nginx TLS session ticket key rotation for given server names.

Report bugs to richard@fussenegger.info
GitHub repository: https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation" 2>&1
For complete documentation, see: README.md
EOT
  2>&1
  exit 1
fi

# Start checking the environment by making sure that this program is privileged.
echo 'Checking environment ...'
is_privileged

# Make sure at least version 1.5.7 of nginx is installed on this system. The
# output of `nginx -v` is sent to stderr (no clue why).
NGINX_VERSION="$(nginx -v 2>&1)"
NGINX_VERSION="${NGINX_VERSION##*/}"
compare_versions "${NGINX_VERSION}" "1.5.7"
if [ "${?}" -lt 1 ]
then
  fail "Installed nginx version is ${YELLOW}${NGINX_VERSION}${NORMAL} which does not support the ${YELLOW}ssl_session_ticket_key${NORMAL} directive. You need at least version ${YELLOW}1.5.7${NORMAL}"
else
  ok "Installed nginx version is ${YELLOW}${NGINX_VERSION}${NORMAL}"
fi

# Ensure either ramfs (preferred) or tmpfs is available.
if grep -qs 'ramfs' '/proc/filesystems'
then
  ok "Using ${YELLOW}ramfs${NORMAL}"
  FILESYSTEM='ramfs'
else
  if grep -qs 'tmpfs' '/proc/filesystems'
  then
    warn "Using ${YELLOW}tmpfs${NORMAL} which means that your keys ${UNDERLINE}might${NORMAL} hit persistent storage"
    FILESYSTEM='tmpfs'
  else
    fail "No support for ${YELLOW}ramfs${NORMAL} nor ${YELLOW}tmpfs${NORMAL} on this system"
  fi
fi

# Make sure mounting directory doesn't exist.
if [ -d "${KEY_PATH}" ]
then
  fail "Directory ${YELLOW}${KEY_PATH}${NORMAL} exists"
fi

# Make sure nothing is mounted on the mounting directory.
if grep -qs "${KEY_PATH}" '/proc/mounts'
then
  fail "${YELLOW}${KEY_PATH}${NORMAL} already mounted"
fi

# Make sure no fstab entry already exists.
if grep -qs "${FSTAB_COMMENT}" '/etc/fstab'
then
  fail "${YELLOW}/etc/fstab${NORMAL} entry already exists"
fi

# Make sure no cron program already exists.
if [ -f "${CRON_PATH}" ]
then
  rm -f "${CRON_PATH}"
  warn "Cron program ${YELLOW}${CRON_PATH}${NORMAL} already exists"
fi

# ------------------------------------------------------------------------------

echo 'Begin installation ...'
set -e

# Create directory for mounting the file system and apply permissions and ensure
# correct owner.
mkdir "${KEY_PATH}"
chmod 0770 "${KEY_PATH}"
chown root:root "${KEY_PATH}"
ok "Created directory ${YELLOW}${KEY_PATH}${NORMAL}"

# The options that should be applied to the new file system. Note that not all
# options are available if ramfs (default) is used. See "man mount" for more
# available options.
FILESYSTEM_OPTIONS="async,mode=770,noauto,noatime,nodev,nodiratime,noexec,nosuid,rw,size=${#}m"

# Mount volatile file system.
mount -t "${FILESYSTEM}" -o "${FILESYSTEM_OPTIONS}" "${FILESYSTEM}" "${KEY_PATH}"
ok "Mounted ${YELLOW}${FILESYSTEM}${NORMAL} on ${YELLOW}${KEY_PATH}${NORMAL}"

# Add entry to /etc/fstab.
echo "${FSTAB_COMMENT}\n${FILESYSTEM} ${KEY_PATH} ${FILESYSTEM} ${FILESYSTEM_OPTIONS} 0 0" >> '/etc/fstab'
ok "Added ${YELLOW}/etc/fstab${NORMAL} entry"

# Generate the cron program.
warn 'TODO: Implement cron program!'

# Generate TLS session ticket keys for each passed server.
. "./${GENERATOR}.sh"

# Create boot program and ensure it's executed before nginx.
warn 'TODO: Implement boot program!'

echo 'Install finished!'
exit 0
