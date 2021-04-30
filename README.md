# zclef Setup

Script pour simplifier la première connection à votre zclef  
Ce service est proposé au abonnés de [Zaclys](www.zaclys.com)
- [Lien vers le service](https://www.zaclys.com/zcle/)
- [Wiki](https://wiki.zaclys.com/index.php/Installation_de_la_zclef_sous_Linux)

## Prérequis

### Créer une paire de clef SSH
Pour optimiser la sécurité, la connexion au serveur zclef par mot de passe n'est pas autorisée.  
Il est donc nécessaire de créer une paire de clef.  

Dans un terminal taper la commande suivante:  
```
ssh-keygen -t ed25519 -f ~/.ssh/zaclys_key
```
nb: Il est préférable pour augmenter la sécurité de votre clef d'indiquer un mot de passe (ou phrase de passe) mais ce n'est pas obligatoire.  


### Demander la création de votre Zclef

Afficher la clef publique précédemment crée:
```
john@doe:~$cat ~/.ssh/zaclys_key.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICjyNAEgg7H0FojAh9yyXNzlzYIsr+3+JFjoxs+fBgvz
```

Puis l'envoyer au support [zaclys support](https://www.zaclys.com/contact/) afin de demander la création de votre Zclef

### Préparer l'ordinateur ou le serveur qui se connectera à votre zclef

Le logiciel sshfs devra être installé, si vous êtes habituellement autoriser à installer des paquets via sudo alors vous n'avez rien à faire.  
Sinon avant de poursuivre vous devez demander à votre administrateur l'installation de sshfs.  

## Installation

Une fois le mail confirmant la création de votre compte reçu vous êtes prêt à vous connecter.  

La manipulations suivantes devront être effectuées dans un terminal avec l'utilisateur destiné à se connecter à votre zclef.  

Récupérer le script avec git:
```
cd /tmp
git clone git@gitlab.com:maelj/zclef.git .
```

ou le récupérer avec wget:
```
cd /tmp
wget https://gitlab.com/maelj/zclef/-/raw/master/setup.sh
```

Première connexion à votre zclef
```bash
cd /tmp
./setup.sh --user <username> --identityfile <path_to_file> [--mountpoint <mountpoint>]
```
nb: --mountpoint est optionnel. Par défaut le montage se fera sur `~/zclef`


## Utilisation

Une fois la première connexion établie le script affichera deux options pour votre utilisation futur.  

### Via fstab

Si vous le souhaitez vous pouvez ajouter la ligne suivante dans votre fichier /etc/fstab:

```
<username>@sshfs.zaclys.com:/zclef     <mount_point>     fuse.sshfs     rw,user,noauto,port=22,allow_other,reconnect,transform_symlinks,_netdev,BatchMode=yes,identityfile=<ssh_key>  0 0
```
Pensez à personnaliser votre `username`, `mount_point`, `ssh_key`  
nb: il est important d'indiquer un chemin absolue pour votre clef publique

Il est également necessaire de décommenter la ligne user_allow_other dans /etc/fuse.conf:
```
sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf
```

### Via alias

Si vous ne souhaitez ou ne pouvez pas modifier le fstab vous pouvez simplement ajouter les deux lignes suivantes à votre ~/.bashrc

```
alias zclefon='sshfs -o "StrictHostKeyChecking=accept-new" -o "IdentityFile=<ssh_key>" -o "Port=22" <username>@sshfs.zaclys.com:zclef <mount_point>'
alias zclefoff="umount <mount_point>"
```

Ensuite il vous suffira d'utiliser les deux alias zclefon et zclefoff pour monter et démonter votre zclef


# OS supportés / testés

* Debian 10
* Ubuntu 20.10
* Fedora 33
* Centos 8
