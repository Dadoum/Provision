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

Créez un dossier lib et apple à coté de l'exécutable.

```bash
# On est toujours dans le dossier Provision
cd build
sudo mkdir ./lib
sudo mkdir ./apple
```

Maintenant, procurez vous les bibliothèques suivantes depuis l'NDK android, et placez les dans le dossier lib/ (veillez à ce qu'elles soient dans la bonne architecture)

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

Ensuite récupérez celles-ci de l'application Apple Music et placez les dans apple/:
Méthode: Ouvrez l'APK comme un zip, allez dans `lib/` ~ votre architecture, probablement x86_64 ~ `/*` et mettez tout dans le dossier.

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
./provision
```
