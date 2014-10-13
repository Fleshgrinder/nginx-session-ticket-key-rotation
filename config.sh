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


# ------------------------------------------------------------------------------
#                                                    User Configurable Variables
# ------------------------------------------------------------------------------


# The session ticket keys rotation interval as cron mask.
#
# Default is 12 hours which means that a key will reside in memory for 36 hours
# before it's deleted (three keys are used). You shouldn't go for much more
# than 24 hours for the encrypt key.
readonly KEY_ROTATION='0 0,12 * * *'

# The nginx restart interval as cron mask.
#
# This should be after the keys have been rotated (see $KEY_ROTATION). Note
# that keys are only in-use after nginx has been restarted. This is very
# important if you're syncing the keys within a cluster.
readonly SERVER_RELOAD='30 0,12 * * *'

# Absolute path to the web server system startup program.
readonly SERVER_INIT_PATH='/etc/init.d/nginx'

# The minimum version the server has to have for session ticket keys via files.
readonly SERVER_MIN_VERSION='1.5.7'

# Absolute path to the cron program.
readonly CRON_PATH='/etc/cron.d/session_ticket_key_rotation'

# Absolute path to the temporary file system.
readonly KEY_PATH='/mnt/session_ticket_keys'

# Absolute path to the system startup program.
readonly INIT_PATH='/etc/init.d/session_ticket_keys'

# Absolute path to the `filesystems` file.
readonly FILESYSTEMS_PATH='/proc/filesystems'


# ------------------------------------------------------------------------------
#                                                        Global System Variables
# ------------------------------------------------------------------------------


# The comment that should be added to /etc/fstab for easy identification.
readonly FSTAB_COMMENT='# Volatile TLS session ticket key file system.'

# Name of our init script for boot dependency.
readonly INIT_NAME="${INIT_PATH##*/}"

# Name of the server daemon / executable.
readonly SERVER="${SERVER_INIT_PATH##*/}"

# For more information on shell colors and other text formatting see:
# http://stackoverflow.com/a/4332530/1251219
readonly RED=$(tput bold; tput setaf 1)
readonly GREEN=$(tput bold; tput setaf 2)
readonly YELLOW=$(tput bold; tput setaf 3)
readonly UNDERLINE=$(tput smul)
readonly NORMAL=$(tput sgr0)

# This variable can be checked by scripts to see if they were included.
readonly CONFIG_LOADED=true

# Whether to suppress any output.
SILENT=false

# Whether we are verbose in outputting or not.
VERBOSE=false


# ------------------------------------------------------------------------------
#                                                               Global Functions
# ------------------------------------------------------------------------------


# Change owner of a directory and all files in it and ensure shell scripts are
# executable by the new owner only.
#
# ARGS:
#  $1 - Absolute path to the directory.
#  $2 - User and group name of the new owner.
# RETURN:
#  0 - If ownership was changed successfully.
#  1 - If changing ownership failed.
change_owner_and_make_scripts_executable()
{
  chown -R -- "${2}":"${2}" "${1}" || return 1
  chmod -R -- 0755 "${1}" || return 1
  find "${1}" -type f -exec chmod -- 0644 {} \; || return 1
  find "${1}" -name '*.sh' -type f -exec chmod -- 0744 {} \; || return 1
  ok "Repository files owned and executable by ${2} users only"
}

# Check available file systems for availability of a volatile one.
#
# GLOBAL:
#  $FILESYSTEM - After calling this function this global variable is set to the
#    volatile file system that was found on this server. This is either `ramfs`
#    or `tmpfs`. The variable is set to `false` if no volatile file system could
#    be found.
# ARGS:
#  $1 - Absolute path to the `filesystems` file.
# RETURN:
#  0 - Available
#  1 - Not available
check_filesystem()
{
  if grep -qs ramfs "${1}"
  then
    FILESYSTEM='ramfs'
    ok "Using ${YELLOW}ramfs${NORMAL}"
  elif grep -qs tmpfs "${1}"
  then
    FILESYSTEM='tmpfs'
    warn "Using ${YELLOW}tmpfs${NORMAL} which means that your keys \
${UNDERLINE}might${NORMAL} hit persistent storage if you have a swap"
  else
    FILESYSTEM=false
    fail "No support for ${YELLOW}ramfs${NORMAL} nor ${YELLOW}tmpfs${NORMAL} \
on this system"
  fi
}

# Check if an ntp daemon is installed.
#
# A correctly set system clock is imperative if keys are shared in cluster.
#
# NOTE: >&- nor 1>&- works in dash!
# RETURN:
#  0 - Always
check_ntpd()
{
  if type ntp 2>&- >/dev/null
  then
    ok "Found ${YELLOW}ntp${NORMAL}"
  elif type openntpd 2>&- >/dev/null
  then
    ok "Found ${YELLOW}openntpd${NORMAL}"
  elif type ntpdate 2>&- >/dev/null
  then
    warn "Found ${YELLOW}ntpdate${NORMAL} (deprecated)"
  else
    warn "Consider installing an ${YELLOW}ntp daemon${NORMAL} to set your \
system time and ensure all servers are in sync"
  fi
}

# Check program version.
#
# ARGS:
#  $1 - The name of the program to check the version (must support -v option).
#  $2 - The minimum version.
# RETURN:
#  0 - If version is equal or greater.
#  1 - If version is lower.
check_version()
{
  # Get version information from program.
  SERVER_VERSION=$("${1}" -v 2>&1)

  # nginx specific, the format of the output looks like:
  # `nginx version: nginx/1.7.6`
  # We need to strip the part to the left of the slash.
  SERVER_VERSION="${SERVER_VERSION##*/}"

  # Remove dots and leading zeros.
  V1=$(printf '%s' "${SERVER_VERSION}" | tr -d '.')
  V1="${V1##*0}"

  # Remove dots and leading zeros.
  V2=$(printf '%s' "${2}" | tr -d '.')
  V2="${V2##*0}"

  # Greater or equals is what we are interested in.
  if [ "${V1}" -ge "${V2}" ]
  then
    ok "Installed server version is ${YELLOW}${SERVER_VERSION}${NORMAL}"
  else
    fail "Installed server version is ${YELLOW}${SERVER_VERSION}${NORMAL} \
which does not support settings ticket keys via files. You need to install at \
least version ${YELLOW}${2}${NORMAL}"
  fi
}

# Create directory and ensure it's only accessible by given user and group.
#
# ARGS:
#  $1 - Absolute path to the directory that should be created.
#  $2 - User and group name of the owner.
# RETURN:
#  0 - If directory was successfully created.
#  1 - If creation of directory failed.
create_directory()
{
  mkdir -p -- "${1}" || return 1
  chmod -- 0770 "${1}" || return 1
  chown -- "${2}":"${2}" "${1}" || return 1
  ok "Created directory ${YELLOW}${1}${NORMAL}"
}

# Display fail message and exit program.
#
# ARGS:
#  $1 - The message's text.
# RETURN:
#  1 - Always
fail()
{
  if [ "${SILENT}" = false ]
  then
    printf "[%sfail%s] %s.\n" "${RED}" "${NORMAL}" "${1}" >&2
  fi
  return 1
}

# Generate (48 byte) random session ticket key.
#
# We use OpenSSL to generate the random data if available and fallback to dd and
# /dev/urandom if it's not available. Note that we use the unblocking device and
# may risk that the random data isn't that random after all. But don't forget
# that we generate volatile keys and not long lived ones, therefore it shouldn't
# be a problem. Having a blocking device on the other hand could become a huge
# problem if we try to start the server daemon and no keys are present.
#
# LINK: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/dd.html#tag_20_31
# GLOBAL:
#  $RANDOM_COMMAND - Set in order to check only once for the available commands
#    and reused during subsequent calls to this function. The variable contains
#    either `openssl` or `dd`.
# ARGS:
#  $1 - Absolute path to the key file.
# RETURN:
#  0 - If key generation was successful.
#  1 - If key generation failed.
generate_key()
{
  if [ -z "${RANDOM_COMMAND}" ]
  then
    if type openssl 2>&- >/dev/null
    then
      RANDOM_COMMAND='openssl'
    else
      RANDOM_COMMAND='dd'
    fi
  fi

  if [ "${RANDOM_COMMAND}" = 'openssl' ]
  then
    openssl rand 48 >"${1}" || return 1
  else
    dd 'if=/dev/urandom' "of=${1}" 'bs=1' 'count=48' >/dev/null || return 1
  fi
}

# Generate random keys for all servers.
#
# ARGS:
#  $@ - The server names to generate keys for.
# RETURN:
#  0 - Generation of all keys was successful.
#  1 - Generation of keys failed.
generate_keys()
{
  [ "${VERBOSE}" = true ] && printf -- 'Generating random keys ...\n'

  for SERVER in ${@}
  do
    # Copy 2 over 3 and 1 over 2.
    for KEY in 2 1
    do
      OLD_KEY="${KEY_PATH}/${SERVER}.${KEY}.key"
      NEW_KEY="${KEY_PATH}/${SERVER}.$(( ${KEY} + 1 )).key"

      # Only perform copy operation if we actually have something to copy,
      # otherwise create file with random data to avoid web server errors. Note
      # that those files can't be used to decrypt anything, they are simple seed
      # data.
      if [ -f "${OLD_KEY}" ]
      then
        cp -- "${OLD_KEY}" "${NEW_KEY}"
        ok "Copied ${YELLOW}${OLD_KEY}${NORMAL} over ${YELLOW}${NEW_KEY}${NORMAL}"
      else
        generate_key "${NEW_KEY}"
        ok "Newly generated ${YELLOW}${NEW_KEY}${NORMAL}"
      fi
    done

    ENCRYPTION_KEY="${KEY_PATH}/${SERVER}.1.key"
    generate_key "${ENCRYPTION_KEY}"
    ok "Generated new encryption key ${YELLOW}${ENCRYPTION_KEY}${NORMAL}"
  done

  [ "${VERBOSE}" = true ] && printf -- 'Key generation finished!\n'
  return 0
}

# Check if given software is installed.
#
# ARGS:
#  $1 - The software to check.
# RETURN:
#  0 - Installed
#  1 - Not installed
is_installed()
{
  if type "${1}" 2>&- >/dev/null
  then
    ok "${YELLOW}${1}${NORMAL} is installed"
  else
    fail "${YELLOW}${1}${NORMAL} does not seem to be installed"
  fi
}

# Display ok message and continue program.
#
# Note that an ok message is only printed in verbose mode and if not silent.
#
# ARGS:
#  $1 - The message's text.
# RETURN:
#  0 - Message was printed to `stdout`
#  1 - Printing of message failed.
ok()
{
  if [ "${VERBOSE}" = true ] && [ "${SILENT}" = false ]
  then
    printf -- "[ %sok%s ] %s ...\n" "${GREEN}" "${NORMAL}" "${1}"
  fi
}

# Check if super user is executing the program.
#
# RETURN:
#  0 - Super user
#  1 - No super user
super_user()
{
  UID=$(id -u)
  if [ "${UID}" -eq 0 ]
  then
    ok 'root (sudo)'
  else
    fail 'Program must be executed as root (sudo)'
  fi
}

# Uninstall TLS session ticket key rotation.
#
# TODO: Split into reusable, smaller, testable functions.
# RETURN:
#  0 - Uninstalled
#  1 - Failure
uninstall()
{
  [ "${VERBOSE}" = true ] && printf 'Uninstalling ...\n'

  if grep -qs " \$${INIT_NAME}" "${SERVER_INIT_PATH}"
  then
    sed -i'.bak' "s/ \$${INIT_NAME}//g" "${SERVER_INIT_PATH}"
    ok "Removed system startup dependency in ${YELLOW}${SERVER_INIT_PATH}${NORMAL}"
  else
    ok "System startup dependency already removed in ${YELLOW}${SERVER_INIT_PATH}${NORMAL}"
  fi

  update-rc.d -f "${INIT_NAME}" remove 2>&- >/dev/null
  ok "Removed any system startup links for ${YELLOW}${INIT_PATH}${NORMAL}"

  if [ -f "${INIT_PATH}" ]
  then
    rm "${INIT_PATH}"
    ok "Removed system startup program ${YELLOW}${INIT_PATH}${NORMAL}"
  else
    ok "System startup program ${YELLOW}${INIT_PATH}${NORMAL} already removed"
  fi

  if [ -f "${CRON_PATH}" ]
  then
    rm "${CRON_PATH}"
    ok "Removed cron program ${YELLOW}${CRON_PATH}${NORMAL}"
  else
    ok "Cron program ${YELLOW}${CRON_PATH}${NORMAL} already removed"
  fi

  if grep -qs "${FSTAB_COMMENT}" '/etc/fstab'
  then
    sed -i'.bak' "/${FSTAB_COMMENT}/,+1 d" '/etc/fstab'
    ok "Removed ${YELLOW}/etc/fstab${NORMAL} entry"
  else
    ok "No entry found in ${YELLOW}/etc/fstab${NORMAL}"
  fi

  if grep -qs "${KEY_PATH}" '/proc/mounts'
  then
    umount -l "${KEY_PATH}"
    ok "Unmounted ${YELLOW}${KEY_PATH}${NORMAL}"
  else
    ok "${YELLOW}${KEY_PATH}${NORMAL} already unmounted"
  fi

  if [ -d "${KEY_PATH}" ]
  then
    rmdir "${KEY_PATH}"
    ok "Removed directory ${YELLOW}${KEY_PATH}${NORMAL}"
  else
    ok "Directory ${YELLOW}${KEY_PATH}${NORMAL} does not exist"
  fi

  [ "${VERBOSE}" = true ] && printf 'Uninstallation finished!\n'
  return 0
}

# Display usage text.
#
# GLOBAL:
#  $ARGUMENTS - Program argument description.
#  $DESCRIPTION - Description what the program does.
# RETURN:
#  0 - If usage was printed to `stdout`.
#  1 - If printing failed.
usage()
{
  cat << EOT
Usage: ${0##*/} [OPTION]... ${ARGUMENTS}
${DESCRIPTION}

  -h  Display this help and exit.
  -s  Be silent and do not print any message.
  -v  Print message for each successful command.

Report bugs to richard@fussenegger.info
GitHub repository: https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation
For complete documentation, see: README.md
EOT
}

# Display warn message and continue program.
#
# Note that a warn message is only printed if not silent.
#
# ARGS:
#  $1 - The message's text.
# RETURN:
#  0 - Message was printed to `stdout`
#  1 - Printing of message failed.
warn()
{
  if [ "${SILENT}" = false ]
  then
    printf "[%swarn%s] %s ...\n" "${YELLOW}" "${NORMAL}" "${1}"
  fi
}


# ------------------------------------------------------------------------------
#                                                                 Handle Options
# ------------------------------------------------------------------------------


# Check for possibly passed options.
while getopts 'hsv' OPT
do
  case "${OPT}" in
    h) usage && exit 0 ;;
    s) SILENT=true ;;
    v) VERBOSE=true ;;
    *) usage 2>&1 && exit 1 ;;
  esac

  # We have to remove found options from the input for later evaluations of
  # passed arguments in subscripts that are not interested in these options.
  shift $(( $OPTIND - 1 ))
done
