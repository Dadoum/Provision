# Provision

## Kesako ?

Provision est un outil en développement qui permettra de récupérer les identifiants Anisette.

## Compilation

### Dépendances
Pour compiler Provision, il requiert d'avoir libc++ (LLVM C++) en 32 bits d'installé !
Il y a de grandes chances que vous ayez à le compiler vous meme et à ce qu'il ne soit pas disponnible dans votre distribution par défaut.

## Méthode

Clonez le projet et compilez le avec CMake:

```bash
git clone https://github.com/Dadoum/Provision
cd Provision
meson build
meson compile -C build
```

## Exécution

Créez un dossier lib32 et apple32 à coté de l'exécutable.

```bash
# On est toujours dans le dossier Provision
cd build
sudo mkdir ./lib32
sudo mkdir ./apple32
```

Maintenant, procurez vous les bibliothèques suivantes depuis un appareil android, ou l'NDK android, et placez les dans le dossier lib32/
/!\ Certaines bibliothèques ne sont que factices dans la NDK, tel que libc.so.

```
ld-android.so
libdl.so
libc.so
liblog.so
libm.so
libz.so
libOpenSLES.so
libstdc++.so
libandroid.so
```

Ensuite récupérez celles-ci de l'application Apple Music et placez les dans apple32/:

```
libxml2.so
libc++_shared.so
libcurl.so
libCoreADI.so
libCoreLSKD.so
libCoreFP.so
libBlocksRuntime.so
libdispatch.so
libicudata_sv_apple.so
libicuuc_sv_apple.so
libicui18n_sv_apple.so
libdaapkit.so
libCoreFoundation.so
libmediaplatform.so
libstoreservicescore.so
libmedialibrarycore.so
libandroidappmusic.so
```

Une fois tout placé, vous pouvez lancer l'exécutable !

```bash
./Provision
```
