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
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

if [ "${#}" -le 1 ]
then
  cat << EOT
Usage: ${0} SERVER_NAME...
Install TLS session ticket key rotation for given server names.

Report bugs to richard@fussenegger.info
GitHub repository: https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation" 2>&1
For complete documentation, see: README.md
EOT
  2>&1
  exit 1
fi

. './config.sh'

echo 'Checking environment ...'
is_privileged

chown -R root:root "${WD}"
chmod 0770 "${WD}/*.sh"
ok 'Repository files owned and executable by root users only'

NGINX_VERSION="$(nginx -v 2>&1)"
NGINX_VERSION="${NGINX_VERSION##*/}"
compare_versions "${NGINX_VERSION}" "1.5.7"
if [ "${?}" -lt 1 ]
then
  fail "Installed nginx version is ${YELLOW}${NGINX_VERSION}${NORMAL} which does not support the ${YELLOW}ssl_session_ticket_key${NORMAL} directive. You need at least version ${YELLOW}1.5.7${NORMAL}"
else
  ok "Installed nginx version is ${YELLOW}${NGINX_VERSION}${NORMAL}"
fi

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

if [ -d "${KEY_PATH}" ]
then
  fail "Directory ${YELLOW}${KEY_PATH}${NORMAL} exists"
fi

if grep -qs "${KEY_PATH}" '/proc/mounts'
then
  fail "${YELLOW}${KEY_PATH}${NORMAL} already mounted"
fi

if grep -qs "${FSTAB_COMMENT}" '/etc/fstab'
then
  fail "${YELLOW}/etc/fstab${NORMAL} entry already exists"
fi

if [ -f "${CRON_PATH}" ]
then
  rm -f "${CRON_PATH}"
  warn "Cron program ${YELLOW}${CRON_PATH}${NORMAL} already exists"
fi

echo 'Begin installation ...'
set -e

mkdir "${KEY_PATH}"
chmod 0770 "${KEY_PATH}"
chown root:root "${KEY_PATH}"
ok "Created directory ${YELLOW}${KEY_PATH}${NORMAL}"

# Not all options have an effect if the preferred ramfs file system is used.
FILESYSTEM_OPTIONS="async,mode=770,noauto,noatime,nodev,nodiratime,noexec,nosuid,rw,size=${#}m"

mount -t "${FILESYSTEM}" -o "${FILESYSTEM_OPTIONS}" "${FILESYSTEM}" "${KEY_PATH}"
ok "Mounted ${YELLOW}${FILESYSTEM}${NORMAL} on ${YELLOW}${KEY_PATH}${NORMAL}"

echo "${FSTAB_COMMENT}\n${FILESYSTEM} ${KEY_PATH} ${FILESYSTEM} ${FILESYSTEM_OPTIONS} 0 0" >> '/etc/fstab'
ok "Added ${YELLOW}/etc/fstab${NORMAL} entry"

cat << EOT > "${CRON_PATH}"
# ------------------------------------------------------------------------------
# TLS session ticket key rotation.
#
# LINK: https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation
# ------------------------------------------------------------------------------

${KEY_ROTATION} sh '${WD}/${GENERATOR}.sh' ${@}
${SERVER_RELOAD} service nginx reload

EOT
ok "Created cron rotation job ${YELLOW}${CRON_PATH}${NORMAL}"

. "./${GENERATOR}.sh"

cat << EOT > "${INIT_PATH}"
#!/bin/sh

### BEGIN INIT INFO
# Provides:           session_ticket_keys
# Required-Start:     $local_fs $syslog
# Required-Stop:
# Default-Start:      2 3 4 5
# Default-Stop:
# Short-Description:  Generates random TLS session ticket keys on boot.
# Description:
#  The script will generate random TLS session ticket keys for all servers that
#  were defined during the installation of the program. The web server service
#  should specify this script as a dependency, this ensures that keys are
#  available on boot.
### END INIT INFO

# ------------------------------------------------------------------------------
# TLS session ticket key rotation.
#
# LINK: https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation
# ------------------------------------------------------------------------------

sh '${WD}/${GENERATOR}.sh' ${@}

EOT
update-rc.d -n "${INIT_PATH##*/}" start 10 2 3 4 5 .
ok "Created system startup program ${YELLOW}${INIT_PATH}${NORMAL} for generate keys on boot"

echo 'Install finished!'
exit 0
