# Provision

## What is this ?

Provision is a tool which will permit to retrieve Anisette headers.

## Compiling

### Dependencies
To compile Provision, you must have installed libc++ (LLVM C++), and everything needed to compile D (ldc, druntime, dub).

## Method

Clone the project and compile it with meson:

```bash
git clone git@github.com:Dadoum/Provision.git
cd Provision
dub fetch plist
dub build plist
meson build
meson compile -C build
```

## Execution

Just copy the lib folder from Apple Music application next to the executable.

You can then launch the executable from your favorite terminal:

```bash
./provision
```
