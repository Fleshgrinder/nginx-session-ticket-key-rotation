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
# TLS session ticket key generator program.
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
Generate TLS session ticket keys for given server names.

Report bugs to richard@fussenegger.info
GitHub repository: https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation
For complete documentation, see: README.md
EOT
  2>&1
  exit 1
fi

# Configuration might already be loaded, this file is included during install.
if [ -z "${KEY_PATH}" ]
then
  . './config.sh'

  echo 'Checking environment ...'
  is_privileged
fi

for SERVER in ${@}
do
  # Copy 2 over 3 and 1 over 2.
  for KEY in 2 1
  do
    OLD_KEY="${KEY_PATH}/${SERVER}.${KEY}.key"
    NEW_KEY="${KEY_PATH}/${SERVER}.$(expr ${KEY} + 1).key"

    # Only perform copy operation if we actually have something to copy,
    # otherwise create file with random data to avoid web server errors. Note
    # that those files can't be used to decrypt anything, they are simple seed
    # data.
    if [ -f "${OLD_KEY}" ]
    then
      cp "${OLD_KEY}" "${NEW_KEY}"
      ok "Copied ${YELLOW}${OLD_KEY}${NORMAL} over ${YELLOW}${NEW_KEY}${NORMAL}"
    else
      openssl rand 48 > "${NEW_KEY}"
      ok "Newly generated ${YELLOW}${NEW_KEY}${NORMAL}"
    fi
  done

  ENCRYPTION_KEY="${KEY_PATH}/${SERVER}.1.key"
  openssl rand 48 > "${ENCRYPTION_KEY}"
  ok "Generated new encryption key ${YELLOW}${ENCRYPTION_KEY}${NORMAL}"
done

echo 'Key generation finished!'
