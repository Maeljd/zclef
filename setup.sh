#!/bin/bash
###
#
# Author: Maël
# Date: 2021/04/28
# Desc:
#   - Configure sshfs connection for Zclef
#
###
#set -e

DEBUG=false

SSHFS_SRV="sshfs.zaclys.com"
SSHFS_PORT="22"

function debug(){
  cat << EOF
  User            : $USER
  IdentityFile    : $IDENTITYFILE
  MountPoint      : $MOUNTPOINT
  SSHFS Server    : $SSHFS_SRV
  SSHFS_PORT      : $SSHFS_PORT
EOF
}

function usage(){
  cat <<EOF

Install and configure your Zclef from zaclys.com

  Usage:
        $0 --user <username> --identityfile <path_to_file> [--mountpoint <mountpoint>]

    -u  |  --user              Username for connection
    -i  |  --identityfile      Path to your personnal private key
    -m  |  --mountpoint        Path to your mount point > Default: $HOME/zclef

EOF
}

function _msg(){
  # Color
  local GREEN="\\033[1;32m"
  local NORMAL="\\033[0;39m"
  local RED="\\033[1;31m"
  local PINK="\\033[1;35m"
  local BLUE="\\033[1;34m"
  local WHITE="\\033[0;02m"
  local YELLOW="\\033[1;33m"

  if [ "$1" == "ok" ]; then
    echo -e "[$GREEN  OK  $NORMAL] $2"
  elif [ "$1" == "ko" ]; then
    echo -e "[$RED ERROR $NORMAL] $2"
  elif [ "$1" == "warn" ]; then
    echo -e "[$YELLOW WARN $NORMAL] $2"
  elif [ "$1" == "info" ]; then
    echo -e "[$BLUE INFO $NORMAL] $2"
  fi
}

function main(){
# Prerequisites
## Check Variables
if [ -z $USER ]; then
  _msg ko "User is missing !"
  usage
  exit 1
fi

if [ ! -f $IDENTITYFILE ] || [ -z $IDENTITYFILE ]; then
  _msg ko "Your IdentityFile is not fount or missing"
  exit 1
fi

## Check if MountPoint is define, if not use the default $HOME/zclef
if [ -z $MOUNTPOINT ];then
  _msg info "Mount point not specified, use $HOME/zclef instead"
  MOUNTPOINT="$HOME/zclef"
fi

## Create MountPoint
if [ ! -d "$MOUNTPOINT" ]; then
  mkdir -p $MOUNTPOINT 2> /dev/null
  if [ $? -ne 0 ]; then
    _msg ko "Unable to create $MOUNTPOINT"
    exit 1
  fi
fi

## Check if sshfs is present

apt -qq install sshfs -y
if [ $? -eq 0 ]; then
  _msg ok "SSHFS succesfully installed"
elif [ $? -ne 0 ]; then
  _msg ko "Unable to install SSHFS"
  exit 1
fi

## Put current user in fuse group
#if grep -q fuse /etc/group ;then
#  usermod -a -G fuse $(whoami)


# Time to mount Zclef
sshfs -o "StrictHostKeyChecking=accept-new" -o "IdentityFile=$IDENTITYFILE" -o "Port=$SSHFS_PORT" "$USER"@"$SSHFS_SRV":zclef $MOUNTPOINT

if [ $? -eq 0 ]; then
  _msg ok "Connection established"
  cat << EOF

===================================================================

    Your Zclef is now connected.
    To disconnect use:
      umount $MOUNTPOINT

    For futur you can put this line in your /etc/fstab:
    "$USER"@"$SSHFS_SRV":/zclef     $MOUNTPOINT     fuse.sshfs     rw,user,noauto,port="$SSH_PORT",allow_other,reconnect,transform_symlinks,_netdev,BatchMode=yes,identityfile=$IDENTITYFILE  0 0

    And after just type this command to mount your zclef
      mount $MOUNTPOINT

===================================================================

EOF
elif [ $? -ne 0 ]; then
  _msg ko "Unable to connect"
  exit 1
fi
}

while [[ $# -gt 0 ]]; do
  key="$1"

  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -u | --user)
      USER="$2"
      shift                         # past argument
      shift                         # past value
      ;;
    -i | --identityfile)
      IDENTITYFILE="$2";
      shift                         # past argument
      shift                         # past value
      ;;
    -m | --mountpoint)
      MOUNTPOINT="$2";
      shift                         # past argument
      shift                         # past value
      ;;
      *)                            # unknown option
      echo "$1 : unknown option"
      usage
      exit 1
      ;;
  esac
done

if $DEBUG; then
  debug
  exit 0
else
  main
fi
