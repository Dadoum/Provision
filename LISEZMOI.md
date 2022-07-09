# Provision

[English](README.md) ⋅ Français

## Kesako ?

Provision est un jeu d'outils intéragissant avec les serveurs d'Apple sur Linux.

Cela inclut :
 - *libprovision*, utilisé pour enregistrer l'appareil auprès des serveurs d'Apple
 - *retrieve_headers*, qui permet d'enregistrer l'appareil avec libprovision et de retourner 
les en-têtes HTTP à utiliser pour identifier l'appareil.
 - *sideload_ipa*, un exemple d'utilisation de libprovision pour installer une application sur
un appareil Apple.

Note: *sideload_ipa* n'est pas encore fini.

## Dépendances

Pour lancer les programmes vous devrez extraire les bibliothèques de l'application Android Apple
Music. Vous pouvez ne télécharger que la tranche de votre architecture. Placez le dossier lib/
à côté des exécutables. Dans le dossier avec toutes les bibliothèques (fichiers en .so), vous pouvez 
ne garder que libstoreservicescore.so et libCoreADI.so. Ce sont les seuls nécessaire. 

Pour compiler n'importe lequel des projets, vous devez avoir CMake et le kit de développement 
pour le D (le compilateur + dub).

Pour compiler *sideload_ipa*, il est nécessaire en plus d'avoir ce qu'il faut pour développer avec 
GTK+, GMP et libimobiledevice.

## Compilation

Clonez le projet et compilez le avec CMake:

```bash
git clone git@github.com:Dadoum/Provision.git --recursive
cd Provision
mkdir build
cd build
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release 
ninja
```
