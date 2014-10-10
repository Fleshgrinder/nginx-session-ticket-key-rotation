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
# nginx TLS session ticket key uninstaller program.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

# Load configuration and start program.
. './config.sh'

# Start checking the environment by making sure that this program is privileged.
echo 'Checking environment ...'
is_privileged

echo 'Begin uninstall ...'
set -e

warn 'TODO: Uninstall boot program.'
warn 'TODO: Uninstall cron program.'

if grep -qs "${FSTAB_COMMENT}" '/etc/fstab'
then
  sed -i'.bak' "/${FSTAB_COMMENT}/,+1 d" '/etc/fstab'
  ok "Removed ${YELLOW}/etc/fstab${NORMAL} entry"
else
  ok "No entry found in ${YELLOW}/etc/fstab${NORMAL}"
fi

if grep -qs "${KEY_PATH}" '/proc/mounts'
then
  umount -l "${KEY_PATH}"
  ok "Unmounted ${YELLOW}${KEY_PATH}${NORMAL}"
else
  ok "${YELLOW}${KEY_PATH}${NORMAL} already unmounted"
fi

if [ -d "${KEY_PATH}" ]
then
  rmdir "${KEY_PATH}"
  ok "Removed directory ${YELLOW}${KEY_PATH}${NORMAL}"
else
  ok "Directory ${YELLOW}${KEY_PATH}${NORMAL} does not exist"
fi

echo 'Uninstall finished!'
exit 0
