# Provision

## Kesako ?

Provision est un outil en développement qui permettra de récupérer les identifiants Anisette.

## Compilation

### Dépendances
Pour compiler Provision, vous devez avoir libc++ (LLVM C++), et tout ce qu'il faut pour compiler du code en D (ldc, druntime et dub).

## Méthode

Clonez le projet et compilez le avec meson:

```bash
git clone git@github.com:Dadoum/Provision.git
cd Provision
dub fetch plist
dub build plist
meson build
meson compile -C build
```

## Exécution

Copiez le dossier lib de l'APK d'Apple Music dans le dossier build/, à coté de l'exécutable.

Vous pouvez ensuite démarrer l'exécutable depuis votre terminal:

```bash
./provision
```
