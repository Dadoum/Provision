# Provision

[English](README.md) ⋅ Français

> **Warning** **(attention)**  \
> N'utilisez pas votre compte Apple personnel ! Préférez un compte secondaire sans importance.  \
> Je **NE** suis **PAS** responsable si quoi que ce soit advient à votre compte Apple. 

## Description

Provision est un jeu d'outils intéragissant avec les serveurs d'Apple sur Linux.

Cela inclut :
 - *libprovision*, utilisé pour enregistrer l'appareil auprès des serveurs d'Apple.
 - *anisette_server*, un serveur d'approvisionnement Anisette pour des logiciels tiers comme 
[AltServer-Linux](https://github.com/NyaMisty/AltServer-Linux).
 - *retrieve_headers*, qui permet d'enregistrer l'appareil avec libprovision et de retourner 
les en-têtes HTTP à utiliser pour identifier l'appareil.

Plus précisément, libprovision enregistre l'appareil auprès d'apple et récupère les données ADI pour celui-ci.
Une fois connecté avec cette machine, les serveurs d'Apple se rappeleront de votre appareil comme sûre,
donc assurez vous de ne pas vous connecter n'importe où, et à conserver précieusement les données ADI à `~/.adi/adi.pb`.

Il y avait *sideload-ipa* aussi précédemment. Le code a été retiré, car il ne fonctionnait de toute façon pas
et que j'aide au développement de [SideServer]() (pas de lien officiel pour le moment), qui fonctionnera AltServer là
où il était disponible avec des fonctions en plus.

## Téléchargements

Vous pouvez télécharger les exécutables depuis la page [Actions](https://github.com/Dadoum/Provision/actions) du projet.

## Dépendances

Pour lancer les programmes vous devrez extraire les bibliothèques de l'application Android Apple
Music. Vous pouvez ne télécharger que la tranche de votre architecture. Placez le dossier lib/
à côté des exécutables. Dans le dossier avec toutes les bibliothèques (fichiers en .so), vous pouvez 
ne garder que libstoreservicescore.so et libCoreADI.so. Ce sont les seuls nécessaires. 

Pour compiler n'importe lequel des projets, vous devez avoir le kit de développement 
pour le D (le compilateur + dub). Si vous le souhaitez, vous pouvez aussi opter pour utiliser
libplist.

## Compilation

Clonez le projet et compilez le avec DUB:

```bash
git clone https://github.com/Dadoum/Provision --recursive
cd Provision
dub build -b release
```

ou CMake:

```bash
git clone https://github.com/Dadoum/Provision --recursive
cd Provision
mkdir build
cd build
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release 
ninja
```

## Soutien

Vous pouvez me soutenir en faisant un don avec GitHub Sponsor.
