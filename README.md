# zclef Setup

Script pour simplifier la première connection à votre zclef  
Ce service est proposé au abonnés de [Zaclys](www.zaclys.com)
- [Lien vers le service](https://www.zaclys.com/zcle/)
- [Wiki](https://wiki.zaclys.com/index.php/Installation_de_la_zclef_sous_Linux)

## Prérequis

1. Créer votre pair de clef ssh (ex: `ssh-keygen -t ed25519 -f my_zaclys_key`)  
2. Envoyer votre clef public au support [zaclys support](https://www.zaclys.com/contact/) pour obtenir votre nom d'utilisateur

## Utilisation

```bash
./setup.sh --user <my_username> --identityfile <path_to_my_private_key> [--mountpoint your_mount_point]

    -u  |  --user              Username for connection
    -i  |  --identityfile      Path to your personnal private key
    -m  |  --mountpoint        Path to your mount point
```
nb: --mountpoint est optionnel. Par défaut le montage se fera sur `~/zclef`

# OS supportés / testés

* Debian 10
* Ubuntu 20.10
* Fedora 33
* Centos 8
