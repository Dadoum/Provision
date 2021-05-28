# Provision

## What is this ?

Provision is a tool which will permit to retrieve Anisette headers.

## Compiling

Clone the project and compile it with CMake:

```bash
git clone https://github.com/Dadoum/Provision
cd Provision
mkdir build && cd build
cmake ..
make
```

## Running

Create two folders, lib32 and apple32, next to the executable exécutable.

```bash
# We are still in Provision folder
cd build
sudo mkdir ./lib32
sudo mkdir ./apple32
```

Now, retrieve these library from an android device, or from android NDK, and place them in lib32/ folder
/!\ Some libraries, such as libc, only contains stubs !

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

Then find these one from Apple Music application and place them in apple32/:

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

Once you got everything set-up, you can launch Provision executable !

```bash
./Provision
```
