#!/bin/bash
###
#
# Author: Maël
# Date: 2021/04/28
# Version: 1.0
# Desc:
#   - Configurer la première connexion au sevice zclef de Zaclys
#   - Ce script n'a été testé que sur les distribution / versions suivantes:
#     - Debian 10, Ubuntu 20.10, Fedora 33, Centos 8
#   - Ne necessite sudo ou root que pour l'installation de sshfs.
#     - Si sshfs est déjà installé pas de droits particuliers requis.
#   - Montage par défaut dans ~/zclef
###

# Passer cette variable afin de n'efectuer aucune modification sur le système.
# Seule la fonction debug sera appelé afin de vérifier la cohérence des variables et de leurs contenu.
DEBUG=false

SSHFS_SRV="sshfs.zaclys.com"
SSHFS_PORT="22"
OS="$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')"

function debug(){
  cat << EOF
  User            : $USER
  IdentityFile    : $IDENTITYFILE
  MountPoint      : $MOUNTPOINT
  SSHFS Server    : $SSHFS_SRV
  SSHFS Port      : $SSHFS_PORT
  OS Detected     : $OS
EOF
}

function usage(){
  cat <<EOF

Installation et connexion de votre Zclef

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
# Prerequis

## Si sshfs n'est pas installé sudo sera alors necessaire.
## Si aucun des deux ne sont présents l'utilisateur devra installer sshfs par lui même.
if [ ! $(which sshfs 2> /dev/null) ]; then
  if [ ! $(which sudo 2> /dev/null) ]; then
    _msg ko "Sudo est requis pour installer sshfs."
    cat << EOF
          Si vous ne souhaitez pas installer sudo, vous pouvez installer sshfs par vous même.
          Puis relancer ce script.
EOF
  exit 1
  fi
fi

## Les variables ne doivents pas être vide.
if [ -z $USER ]; then
  _msg ko "Votre nom d'utilisateur est manquant"
  usage
  exit 1
fi

## et les fichiers doivent être accessibles
if [ ! -f $IDENTITYFILE ] || [ -z $IDENTITYFILE ]; then
  _msg ko "Votre clef privé est manquante ou introuvable"
  exit 1
fi

## Si aucun point de montage n'a été défini alors ~/zclef sera utilisé
if [ -z $MOUNTPOINT ];then
  _msg info "Le point de montage n'est pas spécifié. La zclef sera monté sur $HOME/zclef"
  MOUNTPOINT="$HOME/zclef"
fi

## Création du point de montage
if [ ! -d "$MOUNTPOINT" ]; then
  mkdir -p $MOUNTPOINT 2> /dev/null
  if [ $? -ne 0 ]; then
    _msg ko "Impossible de créer $MOUNTPOINT"
    exit 1
  fi
fi

## Installation de sshfs si necessaire.
if [ ! $(which sshfs 2> /dev/null) ]; then
  _msg info "Installation de SSHFS"
  sudo $PKG_MANAGER -qq install $PKG_NAME -y
  if [ $? -eq 0 ]; then
    _msg ok "SSHFS installé avec succès"
  elif [ $? -ne 0 ]; then
    _msg ko "Erreur lors de l'installation de SSHFS"
    exit 1
  fi
fi

# Montage de la zclef
sshfs -o "StrictHostKeyChecking=accept-new" -o "IdentityFile=$IDENTITYFILE" -o "Port=$SSHFS_PORT" "$USER"@"$SSHFS_SRV":zclef $MOUNTPOINT

if [ $? -eq 0 ]; then
  _msg ok "connexion établie"
  cat << EOF

======================================================================================================================================

    Votre Zclef est maintenant connecté et monté sur $MOUNTPOINT.
    Pour la déconnecter:
      umount $MOUNTPOINT

    Pour simplifier l'utilisation futur vous pouvez ajouter la ligne suivante dans /etc/fstab:
    $USER@$SSHFS_SRV:/zclef     $MOUNTPOINT     fuse.sshfs     rw,user,noauto,port=$SSHFS_PORT,allow_other,reconnect,transform_symlinks,_netdev,BatchMode=yes,identityfile=$IDENTITYFILE  0 0

    Puis décommenter la ligne user_allow_other dans /etc/fuse.conf:
      sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf

    Ensuite il vous suffira de monter la zclef avec la commande:
      mount $MOUNTPOINT

    Si vous ne souhaitez ou ne pouvez pas modifier le fstab vous pouvez également ajouter les deux lignes suivantes à votre ~/.bashrc
      alias zclefon='sshfs -o "StrictHostKeyChecking=accept-new" -o "IdentityFile=$IDENTITYFILE" -o "Port=$SSHFS_PORT" $USER@$SSHFS_SRV:zclef $MOUNTPOINT'
      alias zclefoff="umount $MOUNTPOINT"

    Ensuite il vous suffira d'utiliser les deux alias zclefon et zclefoff pour monter et démonter votre zclef.

======================================================================================================================================

EOF
elif [ $? -ne 0 ]; then
  _msg ko "Problème lors de la tentative de connexion"
  exit 1
fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -u | --user)
      USER="$2"
      shift 2
      ;;
    -i | --identityfile)
      # Conversion d'un eventuel chemin relatif en absolue (requis pour sshfs)
      IDENTITYFILE="$(readlink -f $2)";
      shift 2
      ;;
    -m | --mountpoint)
      MOUNTPOINT="$(readlink -f $2)";
      shift 2
      ;;
      *)
      echo "$1 : Option inconnue"
      usage
      exit 1
      ;;
  esac
done

# Detection de la distribution et adaptation du nom du paquet sshfs.
if echo "$OS" | grep -q "debian"; then
  _msg info "OS detecté : Debian"
  PKG_MANAGER="apt"
  PKG_NAME="sshfs"
elif echo "$OS" | grep -q "ubuntu"; then
  _msg info "OS detecté : Ubuntu"
  PKG_MANAGER="apt"
  PKG_NAME="sshfs"
elif echo "$OS" | grep -q "fedora"; then
  _msg info "OS detecté : Fedora"
  PKG_MANAGER="dnf"
  PKG_NAME="fuse-sshfs"
elif echo "$OS" | grep -q "centos"; then
  _msg info "OS detecté : Centos"
  PKG_MANAGER="dnf --enablerepo=powertools"
  PKG_NAME="fuse-sshfs"
else
  _msg ko "Impossible de detecter l'OS"
  exit 1
fi

if $DEBUG; then
  debug
  exit 0
else
  main
fi
