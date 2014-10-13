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
# Test if nginx is actually using the keys and if they are really rotated.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

# Bail on any failed command / function.
set -e
WD=$(cd -- $(dirname -- "${0}"); pwd)
. "${WD}/test.sh"

# Clean-up everything on exit (any: see trap).
teardown()
{
  # Restore the original nginx configuration.
  if [ -f /etc/nginx/nginx.bak ]
  then
    mv -- /etc/nginx/nginx.bak /etc/nginx/nginx.conf
  fi

  # Uninstall everything and reset the files to their original state.
  cd "${WD}/.."
  make clean
  #git reset --hard
}
trap -- teardown 0 1 2 3 6 9 14 15

# We need faster rotation, otherwise this test is going to take days.

# Generate private key and certificate for localhost server.

# Create new nginx configuration, be sure to create a backup of the original.
if [ -f /etc/nginx/nginx.conf ]
then
  cp -- /etc/nginx/nginx.conf /etc/nginx/nginx.bak
fi

# Make sure everything is sane and restart nginx.
nginx -t
service nginx restart

# Install for localhost.
cd "${WD}/.."
make install

# Now we are able to check key rotation.

printf -- '[  %s✔%s ] Integration test was successful, keys are rotated correctly!\n' "${GREEN}" "${NORMAL}"
exit 0
