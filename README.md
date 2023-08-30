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

## Docker container

If you wish to run Anisette within docker to host a server public or privately. Make sure to install docker/podman 
and run the following command:

```bash
docker run -d -v ${PWD}/provision_config:/home/Chester/.config/Provision/ --restart=always -p 6969:6969 --name anisette dadoum/anisette-server:latest
```

The above command will pull the image and also run it in the background. The volume 
(`provision_config:/home/Chester/.config/Provision/`) will cache Provision's configuration folder.

It contains Apple Music libraries (from Apple, which are not redistributed for legal reasons), ADI file (identifying the 
device as a Mac computer for Apple) and Provision's device file (storing the corresponding device information for Provision).

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

## libprovision usage

The Provision API tries to be stay close to the AuthKit API, but written in D.

```d
import std.digest: toHexString;
import file = std.file;
import std.path: expandTilde, buildPath;
import std.random: rndGen;
import std.range: take, array;
import std.stdio: stderr, write, writeln;
import std.uni: toUpper;
import std.uuid: randomUUID;

import provision.adi;

void main() {
    string configuration_folder = expandTilde("~/.config/Provision/");
    if (!file.exists(configuration_folder)) {
        file.mkdir(configuration_folder);
    }

    ADI adi = new ADI("lib/" ~ architectureIdentifier);
    adi.provisioningPath = configuration_folder;
    Device device = new Device(configuration_folder.buildPath("device.json"));

    if (!device.initialized) {
        stderr.write("Creating machine... ");
        device.serverFriendlyDescription = "<MacBookPro13,2> <macOS;13.1;22C65> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>";
        device.uniqueDeviceIdentifier = randomUUID().toString().toUpper();
        device.adiIdentifier = (cast(ubyte[]) rndGen.take(2).array()).toHexString().toLower();
        device.localUserUUID = (cast(ubyte[]) rndGen.take(8).array()).toHexString().toUpper();

        stderr.writeln("done !");
    }

    adi.identifier = device.adiIdentifier;
    if (!adi.isMachineProvisioned(-2)) {
        stderr.write("Machine requires provisioning... ");

        ProvisioningSession provisioningSession = new ProvisioningSession(adi, device);
        provisioningSession.provision(-2);
        stderr.writeln("done !");
    }
  
    // Do stuff with adi.
}
```

## Support

Donations are welcome with GitHub Sponsors.
