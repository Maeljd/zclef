#!/bin/bash
###
#
# Author: Maël
# Date: 2021/04/28
# Desc:
#   - Configure sshfs connection for Zclef
#
###

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

Installation et connection de votre Zclef

  Utilisation:
        $0 --user <username> --identityfile <path_to_file> [--mountpoint <mountpoint>]

    -h  |  --help              Affiche cette aide
    -u  |  --user              Votre nom d'utilisateur fourni par zaclys
    -i  |  --identityfile      Chemin vers votre clef privé
    -m  |  --mountpoint        Chemin vers le point de montage > Défaut: $HOME/zclef

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

if [ ! $(which sshfs) ]; then
  if [ ! $(which sudo) ]; then
    cat << EOF

    Sudo est requis pour installer sshfs.
    Si vous ne souhaitez pas installer sudo, vous pouvez installer sshfs par vous même.
      apt install sshfs -y
EOF
  fi
fi

if [ -z $USER ]; then
  _msg ko "Votre nom d'utilisateur est manquant"
  usage
  exit 1
fi

if [ ! -f $IDENTITYFILE ] || [ -z $IDENTITYFILE ]; then
  _msg ko "Votre clef privé est manquante ou introuvable"
  exit 1
fi

## Check if MountPoint is define, if not use the default $HOME/zclef
if [ -z $MOUNTPOINT ];then
  _msg info "Le point de montage n'est pas spécifié. La zclef sera monté sur $HOME/zclef"
  MOUNTPOINT="$HOME/zclef"
fi

## Create MountPoint
if [ ! -d "$MOUNTPOINT" ]; then
  mkdir -p $MOUNTPOINT 2> /dev/null
  if [ $? -ne 0 ]; then
    _msg ko "Impossible de créer $MOUNTPOINT"
    exit 1
  fi
fi

## Check if sshfs is installed
if [ ! $(which sshfs) ]; then
  _msg info "Installation de SSHFS"
  sudo apt -qq install sshfs -y
  if [ $? -eq 0 ]; then
    _msg ok "SSHFS installé avec succès"
  elif [ $? -ne 0 ]; then
    _msg ko "Erreur lors de l'installation de SSHFS"
    exit 1
  fi
fi

# Time to mount Zclef
sshfs -o "StrictHostKeyChecking=accept-new" -o "IdentityFile=$IDENTITYFILE" -o "Port=$SSHFS_PORT" "$USER"@"$SSHFS_SRV":zclef $MOUNTPOINT

if [ $? -eq 0 ]; then
  _msg ok "Connection établie"
  cat << EOF

===================================================================

    Votre Zclef est maintenant connecté et monté sur $MOUNTPOINT.
    Pour la déconnecter:
      umount $MOUNTPOINT

    Pour simplifier l'utilisation futur vous pouvez ajouter la ligne suivante dans /etc/fstab:
    $USER@$SSHFS_SRV:/zclef     $MOUNTPOINT     fuse.sshfs     rw,user,noauto,port=$SSH_PORT,allow_other,reconnect,transform_symlinks,_netdev,BatchMode=yes,identityfile=$IDENTITYFILE  0 0

    Ensuite il vous suffira de monter la zclef avec la commande:
      mount $MOUNTPOINT

    Si vous ne souhaitez pas modifier le fstab vous pouvez également ajouter les deux lignes suivantes à votre ~/.bashrc
      alias zclefon='sshfs -o "StrictHostKeyChecking=accept-new" -o "IdentityFile=$IDENTITYFILE" -o "Port=$SSHFS_PORT" $USER@$SSHFS_SRV:zclef $MOUNTPOINT'
      alias zclefoff="umount $MOUNTPOINT"

    Ensuite il vous suffira d'utiliser les deux alias zclefon et zclefoff pour monter et démonter votre zclef.

===================================================================

EOF
elif [ $? -ne 0 ]; then
  _msg ko "Problème lors de la tentative de connection"
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
      shift # past argument
      shift # past value
      ;;
    -i | --identityfile)
      # Convert relativ path to absolute path (required by sshfs options)
      IDENTITYFILE="$(readlink -f $2)";
      shift
      shift
      ;;
    -m | --mountpoint)
      MOUNTPOINT="$2";
      shift
      shift
      ;;
      *)
      echo "$1 : Option inconnue"
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
