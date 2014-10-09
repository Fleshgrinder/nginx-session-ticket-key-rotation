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
# SSL/TLS session ticket key generator script.
#
# TODO: Error handling?
# TODO: Different OpenSSL system version than nginx is using?
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# -----------------------------------------------------------------------------

# Load configuration file.
. ./config.sh

for SERVER in ${SERVER_COUNT}
do
  # Copy 2 over 3 and 1 over 2.
  for OLD_KEY in 2 1
  do
    NEW_KEY=`expr ${OLD_KEY} + 1`

    # Only perform copy operation if we actually have something to copy,
    # otherwise create file with random data to avoid nginx errors. Note that
    # those files can't be used to decrypt anything, they are simple seed data.
    if [ -f "${TMPFS_PATH}/${SERVER}.${OLD_KEY}.key" ]
    then
      cp "${TMPFS_PATH}/${SERVER}.${OLD_KEY}.key" "${TMPFS_PATH}/${SERVER}.${NEW_KEY}.key"
    else
      openssl rand 48 > "${TMPFS_PATH}/${SERVER}.${NEW_KEY}.key"
    fi
  done

  # Generate new key for de- and encryption.
  openssl rand 48 > "${TMPFS_PATH}/${SERVER}.1.key"

  # Write generation timestamp to file for syncing servers.
  date +%s > "${TMPFS_PATH}/${SERVER}.tsp"
done

# Reload nginx service and load new keys.
#
# TODO: A different script should reload the services at the same time on all
#       servers of a cluster to ensure that none is going to start encrypting
#       before all have the newly generated key.
service nginx reload

exit 0
