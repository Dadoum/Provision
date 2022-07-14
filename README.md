# Provision

English ⋅ [Français](LISEZMOI.md)

## What is this ?

Provision is a set of tools interracting with Apple servers on Linux.

It includes:
- *libprovision*, a library used to register device on Apple servers.
- *anisette_server*, an Anisette provisioning server for other software such as 
[AltServer-Linux](https://github.com/NyaMisty/AltServer-Linux).
- *retrieve_headers*, which registers the device with libprovision and returns in the terminal in
JSON the headers to use to identify the device on future requests.
- *sideload_ipa*, an example on how to use libprovision and continue requests to install application
on an Apple device. 

Note: *sideload_ipa* isn't finished yet.

## Dependencies
At runtime, libprovision requires some Apple libraries to be next to the executables. You should
download Apple Music APK (or just the architecture slice for your device if you prefer), and extract
the lib/ folder next to the executables. If you want to reduce further the size, you can remove in the lib/
folder all the libraries except libstoreservicescore.so and libCoreADI.so, since they are the only one
needed to run the app.

To build any of these projects, you need CMake, a C and C++ compiler, the D SDK, with the compiler
and dub and libplist development packages.

To build *sideload_ipa*, you also need GTK+ and libimobiledevice development packages. 

## Compilation

Clone the project and compile it with CMake:

```bash
git clone git@github.com:Dadoum/Provision.git --recursive
cd Provision
mkdir build
cd build
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release 
ninja
```
