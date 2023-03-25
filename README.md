# Provision

English ⋅ [Français](LISEZMOI.md)

> **Warning**  \
> Don't use your main Apple account! Prefer a secondary Apple account.  \
> I am NOT responsible if something happens with your Apple account.

## What is this ?

Provision is a set of tools interracting with Apple servers on Linux.

It includes:

- *libprovision*, a library used to register device on Apple servers.
- *anisette_server*, an Anisette provisioning server for other software such as
  [AltServer-Linux](https://github.com/NyaMisty/AltServer-Linux).
- *retrieve_headers*, which registers the device with libprovision and returns in the terminal in
  JSON the headers to use to identify the device on future requests.

More precisely, libprovision registers the device to Apple servers and retrieve ADI data for your device.
Once you logged in once with your machine, your machine is remembered as safe by Apple using this data
Be careful to log-in only on trusted machines, and don't leak your ADI data, which is stored in `~/.adi/adi.pb`.

There used to be a software called *sideload-ipa* listed here. The code has now been removed, as it was not working,
and that I am now helping the development of [SideServer]() (no official link yet), which reimplements the full AltServer
with few more features.

## Downloads

You can download the executables in the [Actions](https://github.com/Dadoum/Provision/actions) tab of the project.

## Docker

If you wish to run Anisette within docker to host a server public or privately. Make sure to install docker/podman and run the following command:

```bash
docker run -d -v lib_cache:/opt/lib/ --restart=always -p 6969:6969 --name anisette dadoum/anisette-server:latest
```

The above command will pull the image and also run it in the background. The volume (lib_cache:/opt/lib/) will cache the libraries needed that are fetched at runtime. This is done as to not redistribute Applemusic lib's.

## Dependencies

At runtime, libprovision requires some Apple libraries to be next to the executables. You should
download Apple Music APK (or just the architecture slice for your device if you prefer), and extract
the lib/ folder next to the executables. If you want to reduce further the size, you can remove in the lib/
folder all the libraries except libstoreservicescore.so and libCoreADI.so, since they are the only one
needed to run the app.

To build any of these projects, you need the D SDK, with the compiler and dub. As an option, you can also use libplist.

## Compilation

Clone the project and compile it with DUB:

```bash
git clone https://github.com/Dadoum/Provision --recursive
cd Provision
dub build -b release
```

or with CMake:

```bash
git clone https://github.com/Dadoum/Provision --recursive
cd Provision
mkdir build
cd build
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release 
ninja
```

## Support

Donations are welcome with GitHub Sponsor.
