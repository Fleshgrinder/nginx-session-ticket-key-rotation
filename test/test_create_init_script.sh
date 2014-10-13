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

EXPECTED="${WD}/test_init_expected"
ACTUAL="${WD}/test_init_actual"

cat << EOT > "${EXPECTED}"
#!/bin/sh

### BEGIN INIT INFO
# Provides:           test_init_actual
# Required-Start:     \$local_fs \$syslog
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

sh '${WD}' example.com localhost

EOT

touch -- "${ACTUAL}"

trap -- "rm -f -- ${EXPECTED} ${ACTUAL}" 0 1 2 3 6 9 14 15

create_init_script "${ACTUAL}" "${WD}" 'example.com localhost'

diff -- "${ACTUAL}" "${EXPECTED}" && test_ok || test_fail
