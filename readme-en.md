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
meson build
meson compile -C build
```

## Execution

Just copy the lib folder from Apple Music application next to the executable.

You can then launch the executable from your favorite terminal:

```bash
./provision
```
