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
# Configuration file for TLS session ticket rotation program.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

# The session ticket keys rotation interval as cron mask.
#
# Default is 12 hours which means that a key will reside in memory for 36 hours
# before it's deleted (three keys are used). You shouldn't go for much more
# than 24 hours for the encrypt key.
KEY_ROTATION='0 0,12 * * *'

# The nginx restart interval as cron mask.
#
# This should be after the keys have been rotated (see $KEY_ROTATION). Note
# that keys are only in-use after nginx has been restarted. This is very
# important if you're syncing the keys within a cluster.
SERVER_RELOAD='30 0,12 * * *'

# Absolute path to the cron program.
CRON_PATH='/etc/cron.d/session_ticket_key_rotation'

# Absolute path to the temporary file system.
KEY_PATH='/mnt/session_ticket_keys'

# Absolute path to the system startup program.
INIT_PATH='/etc/init.d/session_ticket_keys'
INIT_NAME="${INIT_PATH##*/}"

# Absolute path to the web server system startup program.
SERVER_INIT_PATH='/etc/init.d/nginx'
SERVER_DAEMON="${SERVER_INIT_PATH##*/}"

# The name of the generator file.
GENERATOR='generator'

# The comment that should be added to /etc/fstab for easy identification.
FSTAB_COMMENT='# Volatile TLS session ticket key file system.'

# Get absolute path to the program.
WD="$(cd $(dirname ${0}); pwd)"

# For more information on shell colors and other text formatting see:
# http://stackoverflow.com/a/4332530/1251219
RED="$(tput bold; tput setaf 1)"
GREEN="$(tput bold; tput setaf 2)"
YELLOW="$(tput bold; tput setaf 3)"
UNDERLINE="$(tput smul)"
NORMAL="$(tput sgr0)"

# Compare two version strings. Note that I'm using a very simple approach to
# compare the versions because I expect properly formatted version strings from
# nginx.
#
# RETURN:
#  0 - first lower than second
#  1 - equal
#  2 - first higher than second
compare_versions()
{
  local V1="$(echo ${1} | tr -d '.')"
  local V2="$(echo ${2} | tr -d '.')"
  if [ "${V1}" -gt "${V2}" ]
  then
    return 2
  elif [ "${V1}" -lt "${V2}" ]
  then
    return 0
  fi
  return 1
}

# Check if the program is executed with privileged user rights and exit if it
# isn't.
is_privileged()
{
  if [ "$(whoami)" = 'root' ]
  then
    ok 'Privileged user'
  else
    fail 'Program cannot be executed with non-privileged user'
  fi
}

# Display fail message and exit program.
#
# ARGS:
#   $1 - The message's text.
fail()
{
  printf "[%sfail%s] %s.\n" "${RED}" "${NORMAL}" "${1}" >&2
  exit 1
}

# Display ok message and continue program.
#
# ARGS:
#   $1 - The message's text.
ok()
{
  printf "[ %sok%s ] %s ...\n" "${GREEN}" "${NORMAL}" "${1}"
}

# Display warn message and continue program.
#
# ARGS:
#   $1 - The message's text.
warn()
{
  printf "[%swarn%s] %s ...\n" "${YELLOW}" "${NORMAL}" "${1}"
}
