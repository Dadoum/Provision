# Provision

<p align="center">
    <a href="README.md">English</a> | Français
</p>

## Kesako ?

Provision est un outil qui permet de récupérer les identifiants Anisette et les retourne en JSON.

## Compilation

### Dépendances
Pour compiler Provision, vous devez avoir CMake et le kit de développement pour le D (le compilateur + dub)

## Méthode

Clonez le projet et compilez le avec meson:

```bash
git clone git@github.com:Dadoum/Provision.git --recursive
cd Provision
mkdir build
cd build
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release 
ninja
```

## Exécution

Copiez le dossier lib de l'APK d'Apple Music dans le dossier build/, à coté de l'exécutable.

Vous pouvez ensuite démarrer l'exécutable depuis votre terminal:

```bash
./provision
```
