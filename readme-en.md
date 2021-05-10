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

Create a lib32 folder next to executable

```bash
# We're still in build folder
sudo mkdir ./lib32
```

Now, retrieve these Android libraries from Android device, NDK and Apple Music APK.
/!\ some libraries are stub in NDK.

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

Place these library in the new lib32 folder and run the executable:

```bash
./Provision
```
