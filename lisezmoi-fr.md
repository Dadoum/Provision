# Provision

## Kesako ?

Provision est un outil en développement qui permettra de récupérer les identifiants Anisette.

## Compilation

### Dépendances
Pour compiler Provision, vous devez avoir libc++ (LLVM C++).

## Méthode

Clonez le projet et compilez le avec meson:

```bash
git clone https://github.com/Dadoum/Provision
cd Provision
meson build
meson compile -C build
```

## Exécution

Copiez le dossier lib de l'APK d'Apple Music dans le dossier build/, à coté de l'exécutable.

Vous pouvez ensuite démarrer l'exécutable depuis votre terminal:

```bash
./provision
```
