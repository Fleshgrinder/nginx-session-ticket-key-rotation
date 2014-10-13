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
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

WD=$(cd -- $(dirname -- "${0}"); pwd)
. "${WD}/test.sh"

TEST_SCRIPT='/etc/init.d/nginx_session_ticket_key_rotation_test_script'
TEST_FILE="${TEST_SCRIPT##*/}"

cat << EOT > "${TEST_SCRIPT}"
#!/bin/sh

### BEGIN INIT INFO
# Provides:           ${TEST_FILE}
# Required-Start:
# Required-Stop:
# Default-Start:      2 3 4 5
# Default-Stop:
# Short-Description:
# Description:
### END INIT INFO

EOT

test_create_init_links_teardown()
{
  update-rc.d -f "${TEST_FILE}" remove >/dev/null
  rm -f ${TEST_SCRIPT}
}

trap -- test_create_init_links_teardown 0 1 2 3 6 9 14 15

create_init_links "${TEST_SCRIPT}" && test_ok || test_fail

for RUNLEVEL in 2 3 4 5
do
  [ -e "/etc/rc${RUNLEVEL}.d/S10${TEST_FILE}" ] && test_ok || test_fail
done
