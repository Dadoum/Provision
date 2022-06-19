# Provision

<p align="center">
    English | <a href="LISEZMOI.md">Français</a>
</p>

## What is this ?

Provision is a tool which retrieves Anisette headers and outputs them in JSON.

## Compiling

### Dependencies
To compile Provision, you need CMake and D SDK (a D compiler + dub).

## Method

Clone the project and compile it with meson:

```bash
git clone git@github.com:Dadoum/Provision.git --recursive
cd Provision
mkdir build
cd build
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release 
ninja
```

## Execution

Just copy the lib folder from Apple Music application next to the executable.

You can then launch the executable from your favorite terminal:

```bash
./provision
```
