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

# Copy 2 over 3 and 1 over 2.
for i in 2 1
do
  j = i + 1

  # Only perform copy operation if we actually have something to copy, otherwise
  # create an empty file (prevent nginx errors but don't provide random decrypt
  # key because we have none).
  if [ -f "${TMPFS_PATH}/${KEY_FILENAME}.${i}.key" ]
  then
    cp "${TMPFS_PATH}/${KEY_FILENAME}.${i}.key" "${TMPFS_PATH}/${KEY_FILENAME}.${j}.key"
  else
    touch "${TMPFS_PATH}/${KEY_FILENAME}.${j}.key"
  fi
done

# Generate new key for de- and encryption.
openssl rand 48 > "${TMPFS_PATH}/${KEY_FILENAME}.1.key"

# Reload nginx service and load new keys.
service nginx reload

exit 0
