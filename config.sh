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
# Configuration file for SSL/TLS session ticket rotation scripts.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

# Absolute path to the temporary file system.
KEY_PATH='/mnt/nginx-session-ticket-keys'

# Absolute path to the cron script.
CRON_PATH='/etc/cron.d/nginx-session-ticket-key-rotation'

# The name of the generator file.
GENERATOR='generator'

# Arrays aren't POSIX compliant and we can't easily get the length of the single
# array we have at our disposal.
SERVER_COUNT=0
for SERVER in ${@}
do
  SERVER_COUNT=$(expr ${SERVER_COUNT} + 1)
done

# The options that should be applied to the new file system. Note that not all
# options are available if ramfs (default) is used. See "man mount" for more
# available options.
FILESYSTEM_OPTIONS="async,mode=770,noauto,noatime,nodev,nodiratime,noexec,nosuid,rw,size=${SERVER_COUNT}m"

# The comment that should be added to /etc/fstab for easy identification.
FSTAB_COMMENT='# Volatile nginx TLS session ticket key file system.'

# For more information on shell colors and other text formatting see:
# http://stackoverflow.com/a/4332530/1251219
BLACK=$(tput setaf 0)
RED=$(tput bold; tput setaf 1)
GREEN=$(tput bold; tput setaf 2)
YELLOW=$(tput bold; tput setaf 3)
BLUE=$(tput bold; tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

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
  local V1=$(echo ${1} | tr -d '.')
  local V2=$(echo ${2} | tr -d '.')
  if [ ${V1} -gt ${V2} ]
  then
    return 2
  elif [ ${V1} -lt ${V2} ]
  then
    return 0
  fi
  return 1
}

# Display fail message and exit program.
#
# ARGS:
#   $1 - The message's text.
fail()
{
  echo "[${RED}fail${NORMAL}] ${1}." >&2
  exit 1
}

# Check if the program is executed with privileged user rights and exit if it
# isn't.
is_privileged()
{
  if [ $(whoami) != "root" ]
  then
    fail 'Script cannot be executed with non-privileged user'
  else
    ok 'Privileged user'
  fi
}

# Display ok message and continue program.
#
# ARGS:
#   $1 - The message's text.
ok()
{
  echo "[ ${GREEN}ok${NORMAL} ] ${1} ..."
}

# Display warn message and continue program.
#
# ARGS:
#   $1 - The message's text.
warn()
{
  echo "[${YELLOW}warn${NORMAL}] ${1} ..."
}

# ------------------------------------------------------------------------------
# Start program ...

echo 'Checking environment ...'
is_privileged
