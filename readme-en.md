# Provision

## What is this ?

Provision is a tool which will permit to retrieve Anisette headers.

## Compiling

### Dependencies
To compile Provision, you must have installed libc++ (LLVM C++).

## Method

Clone the project and compile it with meson:

```bash
git clone https://github.com/Dadoum/Provision
cd Provision
mkdir build && cd build
cmake ..
make
```

## Execution

Create two folders, lib and apple, next to the executable.

```bash
# We are still in Provision folder
cd build
sudo mkdir ./lib
sudo mkdir ./apple
```

Now, retrieve these libraries from android NDK, and place them in lib/ folder. 

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

Then find these one from Apple Music application and place them in apple/:
Method: Open APK as a zip file, go into `lib/` ~ your architecture, probably x86_64 ~ `/*` and put everything in the folder.

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
./provision
```
