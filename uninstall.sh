#!/bin/sh

# -----------------------------------------------------------------------------
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
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# SSL/TLS session ticket key script setup.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# -----------------------------------------------------------------------------

# Load configuration file.
source $(pwd)/config.sh

if [ -d "${TMPFS_PATH}" ]
then
  # Unmount the temporary file system and delete the directory and all keys.
  umount ${TMPFS_PATH}
  rm -rf ${TMPFS_PATH}
  echo "You need to edit your nginx configuration and remove all references to used"
  echo "session ticket keys and reload the service afterwards."

  # Remove previously created fstab entry. Note that we use @ as delimiter and
  # avoid escaping of the path variable which contains slashes.
  sed '\@^tmpfs ${TMPFS_PATH}@ d' /etc/fstab > /etc/fstab

  # Remove the linked generator script from the cron directory.
  CRON_LINK="/etc/cron.${CRON_KEYWORD}/${CRON_LINKNAME}"
  if [ -h ${CRON_LINK} ]
  then
    rm -f ${CRON_LINK}
    echo ""
    echo "The symbolic link for automated ticket rotation within your cron directory"
    echo "has been removed."
  fi

  exit 0
else
  echo "Directory ${TMPFS_PATH} does not exist."
  exit 1
fi
