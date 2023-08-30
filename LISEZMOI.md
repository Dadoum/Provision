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
donc assurez-vous de ne pas vous connecter n'importe où, et à conserver précieusement les données ADI à `~/.adi/adi.pb`.

Il y avait *sideload-ipa* aussi précédemment. Le code a été retiré, car il ne fonctionnait de toute façon pas
et que j'aide au développement de [SideServer]() (pas de lien officiel pour le moment), qui fonctionnera AltServer là
où il était disponible avec des fonctions en plus.

## Téléchargements

Vous pouvez télécharger les exécutables depuis la page [Actions](https://github.com/Dadoum/Provision/actions) du projet.

## Conteneur Docker

Si vous souhaitez créer un serveur Anisette pour votre usage personnel ou créer un serveur public, vous pouver utiliser
Docker ou Podman. Dans ce cas, il vous suffira de lancer la commande suivante pour configurer un serveur directement :

```bash
docker run -d -v ${PWD}/provision_config:/home/Chester/.config/Provision/ --restart=always -p 6969:6969 --name anisette dadoum/anisette-server:latest
```

Cette commande récupèrera l'image Docker et l'exécutera immédiatemnt. Le volume
(`provision_config:/home/Chester/.config/Provision/`) mettra en cache la configuration de Provision.

Cette configuration inclut les bibliothèques d'Apple Music (qui ne sont pas redistribuées pour des raisons légales), le
fichier ADI (identifiant un faux Mac auprès d'Apple) et le fichier d'appareil de Provision (indiquant à Provision les 
informations du Mac).

## Dépendances

Pour lancer les programmes vous devrez extraire les bibliothèques de l'application Android Apple
Music. Vous pouvez ne télécharger que la tranche de votre architecture. Placez le dossier lib/
à côté des exécutables. Dans le dossier avec toutes les bibliothèques (fichiers en .so), vous pouvez 
ne garder que libstoreservicescore.so et libCoreADI.so. Ce sont les seuls nécessaires. 

Pour compiler n'importe lequel des projets, vous devez avoir le kit de développement 
pour le D (le compilateur + dub). Si vous le souhaitez, vous pouvez aussi opter pour utiliser
libplist.

## Compilation

Clonez le projet et compilez le avec DUB :

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

## Utilisation de libprovision

L'interface essaie tant bien que mal de rester proche de celle d'AuthKit, même si Provision est écrit en D.

```d
import std.digest: toHexString;
import file = std.file;
import std.path: expandTilde, buildPath;
import std.random: rndGen;
import std.range: take, array;
import std.stdio: stderr, write, writeln;
import std.uni: toUpper;
import std.uuid: randomUUID;

import provision.adi;

void main() {
    string configuration_folder = expandTilde("~/.config/Provision/");
    if (!file.exists(configuration_folder)) {
        file.mkdir(configuration_folder);
    }

    ADI adi = new ADI("lib/" ~ architectureIdentifier);
    adi.provisioningPath = configuration_folder;
    Device device = new Device(configuration_folder.buildPath("device.json"));

    if (!device.initialized) {
        stderr.write("Creating machine... ");
        device.serverFriendlyDescription = "<MacBookPro13,2> <macOS;13.1;22C65> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>";
        device.uniqueDeviceIdentifier = randomUUID().toString().toUpper();
        device.adiIdentifier = (cast(ubyte[]) rndGen.take(2).array()).toHexString().toLower();
        device.localUserUUID = (cast(ubyte[]) rndGen.take(8).array()).toHexString().toUpper();

        stderr.writeln("done !");
    }

    adi.identifier = device.adiIdentifier;
    if (!adi.isMachineProvisioned(-2)) {
        stderr.write("Machine requires provisioning... ");

        ProvisioningSession provisioningSession = new ProvisioningSession(adi, device);
        provisioningSession.provision(-2);
        stderr.writeln("done !");
    }
    
    // Faites ce que vous voulez avec adi !
}
```

## Soutien

Vous pouvez me soutenir en faisant un don avec GitHub Sponsors.
