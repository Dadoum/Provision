# Provision

## Kesako ?

Provision est un outil en développement qui permettra de récupérer les identifiants Anisette.

## Compilation

Clonez le projet et compilez le avec CMake:

```bash
git clone https://github.com/Dadoum/Provision
cd Provision
mkdir build && cd build
cmake ..
make
```

## Exécution

Créez un dossier lib32 à coté de l'exécutable.

```bash
# On est toujours dans le dossier build
sudo mkdir ./lib32
```

Maintenant, procurez vous les bibliothèques suivantes depuis un appareil android, l'NDK android et l'APK d'Apple Music.
/!\ Certaines bibliothèques ne sont que factices dans la NDK.

```
ld-android.so
libdl.so
libc.so
libc++_shared.so
liblog.so
libm.so
libz.so
libandroid.so
libxml2.so
libstdc++.so
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
libOpenSLES.so
libandroidappmusic.so
```

Placez les dans le dossier lib32 nouvellement créé puis vous pouvez exécuter.

```bash
./Provision
```
