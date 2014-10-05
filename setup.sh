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
source $(pwd)/ngx-config.sh

if [ -d "${TMPFS_PATH}" ]
  echo "Directory ${TMPFS_PATH} already exists."$'\n'
  exit 1
then
  # Create mount point for temporary file system.
  mkdir "${TMPFS_PATH}"

  # Apply very permissive permissions.
  chmod 700 "${TMPFS_PATH}"

  # Mount temporary file system and precise it's size.
  mount -t tmpfs -o size=1M tmpfs "${TMPFS_PATH}"

  # Automatically create temporary file system on start up in the future.
  echo $'\n'"tmpfs ${TMPFS_PATH} tmpfs defaults,size=1M 0 0"$'\n' >> /etc/fstab

  # Generate session ticket key for encryption and fake decrypt files.
  sh $(pwd)/ngx-ticket-generator.sh

  echo "Please add the following lines to your nginx configuration:"
  for i in 1 2 3
  do
    echo "    ssl_session_key ${TMPFS_PATH}/${KEY_FILENAME}.${i}.key"
  done
  echo "And reload the service afterwards."$'\n'
  echo "Make sure that you create a link to the 'ngx-ticket-generator.sh' script"
  echo "in your crontab for ticket rotation, e.g.:"
  echo "    ln -s /path/to/nginx-session-ticket-key-rotation/generator.sh /etc/cron.daily/ngx-rotate"$'\n'

  exit 0
fi
