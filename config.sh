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
# Configuration file for SSL/TLS session ticket rotation scripts.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# -----------------------------------------------------------------------------

# Absolute path to the temporary file system.
TMPFS_PATH="/mnt/ngxtmpfs"

# Total server count; this may not have to reflect your actual server count.
# Read the provided documentation carefully.
SERVER_COUNT=1

# The cron keyword where the rotation script should be linked in.
CRON_KEYWORD="daily"

# The name of the symbolic link within the cron directory.
CRON_LINKNAME="rotate-nginx-session-tickets"

# ------------------------------------------------------------------------------
# The code after this line shouldn't be changed unless you know what you're
# doing.
# ------------------------------------------------------------------------------

# The name of the generator file.
GENERATOR="generator"

# For more information on shell colors and other text formatting see:
# http://stackoverflow.com/a/4332530/1251219
BLACK=$(tput setaf 0)
RED=$(tput bold; tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

# Compare two version strings: http://stackoverflow.com/a/3511118/1251219
#
# RETURN:
#  -1 - first lower than second
#   0 - equal
#   1 - first higher than second
compare_versions()
{
  for i in {1..4}
  do
    echo ${i}
  done
  return 0

#  typeset    IFS='.'
#  typeset -a v1=( $1 )
#  typeset -a v2=( $2 )
#  typeset    n diff
#
#  for (( n=0; n<4; n+=1 )); do
#    diff=$((v1[n]-v2[n]))
#    if [ $diff -ne 0 ] ; then
#      [ $diff -lt 0 ] && echo '-1' || echo '1'
#      return
#    fi
#  done
#  echo  '0'
}

# Check the return code of the last executed command and exit with non-zero code
# if the command returned a non-zero code. The message "Last command failed!"
# will be displayed to the user.
exit_on_error()
{
  if [ $? != 0 ]
  then
    "${RED}ABORTING:${NORMAL} Last command failed with exit code ${?}!"
    exit 1
  fi
}

# Print a line to the CLI consisting of 80 dashes and followed by a line feed.
line()
{
  tput ich 80 "-"
}
