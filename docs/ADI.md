# ADI

ADI is the name of the library managing Anisette Data.

Anisette Data is used by Apple servers to identify a device, and they are using this to trust devices and 
allow them to not go multiple times under 2FA. 

ADI stands for Apple Device Identification (probably).

ADI is implemented in a library called CoreADI, which is implemented in 4 platforms AFAIK.
- macOS
- Windows
- iOS
- Android

I don't exclude the existence of other versions, such as one for the web powering the IDMSA login portal
and one for Roku devices, but I wasn't able to get the app to see it (if you have one open an issue it's 
still interesting).

CoreADI is exposing different C functions, and has a different level of obfuscation across builds.

On most public implementations, CoreADI has two entry points, `vdfut768ig` and `cvu8io98wun`. Some people
tried to reverse engineer those entry points, such as [here](https://github.com/ionescu007/Blackwood-4NT),
but they are hard to do so.

CoreADI in general is obfuscated with all their FairPlay techniques, and since we don't know what they take
in arguments either it's very difficult to reverse.

On some implementations such as the one from Apple TV for Android, the multiple entry points are directly 
exposed in a statically-linked build of CoreADI.

The names used there are still scrambled, but this is seemingly using a hash function to generate those
names, and thus allowing us to make a register of all the Apple obfuscated function names.

Outside of Apple TV for Android, those hashed names are also exported by other libraries using CoreADI
on the system. This is the case of StoreServices.framework and libstoreservicescore. With those, we can
call directly the ADI function, and they will interact with the obfuscated entry points of CoreADI.

All scrambled entry points are not ADI-related. As said before, all FairPlay-related code is treated the
same. We will also put them in a table

All ADI functions in Apple Music for Android are available in Apple TV for Android 

This project makes use of Apple Music for Android libraries as it supports more architectures. Apple Music
for Android is also more flexible than the other libraries as it has entry points to set the identifier
and load library from specific places instead of making a registry lookup as does iCloud for Windows.

TODO make a table for ADI

ADI error prefix: -45xxx ÷\
Note: some FairPlay errors can occur within ADI, like -42049.

TODO make a table for FairPlay

FairPlay error prefix: -42xxx

TODO make a table for FootHill \
TODO check its error code

TODO make a table for Absinthe (NAC)

Absinthe (NAC) error prefix is -44xxx