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
  rm -f -- /etc/nginx/cert.key
  rm -f -- /etc/nginx/cert.pem

  # Restore the original nginx configuration.
  if [ -f /etc/nginx/nginx.bak ]
  then
    mv -- /etc/nginx/nginx.bak /etc/nginx/nginx.conf
  fi

  # Uninstall everything and reset the files to their original state.
  cd "${WD}/.."
  TEST_NAME='integration_test_uninstall'
  make clean >/dev/null 2>&1 || test_fail
  TEST_NAME='integration_test_git_reset'
  #git reset --hard >/dev/null 2>&1 || test_fail
  unset TEST_NAME
}
trap -- teardown 0 1 2 3 6 9 14 15

# We need faster rotation, otherwise this test is going to take days.

# Generate private key and certificate for localhost server.
TEST_NAME='integration_test_key_cert'
openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
  -keyout /etc/nginx/cert.key -out /etc/nginx/cert.pem << EOT >/dev/null 2>&1 || test_fail
XX
State
City
Company

root
root@localhost
EOT
unset TEST_NAME

# Create new nginx configuration, be sure to create a backup of the original.
if [ -f /etc/nginx/nginx.conf ]
then
  cp -- /etc/nginx/nginx.conf /etc/nginx/nginx.bak
fi

# Create simple TLS server configuration for localhost.
cat << EOT > /etc/nginx/nginx.conf
worker_processes  1;
events {
  worker_connections  1024;
}
http {
  server {
    listen                     443 ssl;
    server_name                localhost;
    ssl_certificate            cert.pem;
    ssl_certificate_key        cert.key;
    ssl_ciphers                HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers  on;
    ssl_session_ticket_key     ${KEY_PATH}/localhost.1.key;
    ssl_session_ticket_key     ${KEY_PATH}/localhost.2.key;
    ssl_session_ticket_key     ${KEY_PATH}/localhost.3.key;
  }
}
EOT

# Install for localhost.
cd "${WD}/.."
TEST_NAME='integration_test_install'
make install >/dev/null 2>&1
unset TEST_NAME

# Make sure everything is sane.
TEST_NAME='integration_test_nginx_conf'
nginx -t >/dev/null 2>&1 || test_fail
unset TEST_NAME

# Restart or start nginx.
TEST_NAME='integration_test_nginx_start'
if service nginx status >/dev/null
then
  service nginx restart >/dev/null || test_fail
else
  service nginx start >/dev/null || test_fail
fi
unset TEST_NAME

# Now we are able to check key rotation.

printf -- '[ %s✔%s ] Integration test was successful, keys are rotated correctly!\n' "${GREEN}" "${NORMAL}"
exit 0
