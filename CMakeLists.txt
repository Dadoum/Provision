cmake_minimum_required(VERSION 3.17)
project(Provision)

set(CMAKE_CXX_STANDARD 17)
include(FetchContent)
include(ExternalProject)

add_executable(Provision main.cpp LibraryLoader.cpp)
set(CMAKE_C_FLAGS "-m32")
set(CMAKE_CXX_FLAGS "-m32")
set(INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}/share/Provision)

add_definitions(-DEnableJNIVMGC)
FetchContent_Declare(
        libjnivm
        GIT_REPOSITORY https://github.com/ChristopherHX/libjnivm
        GIT_TAG main
)
FetchContent_MakeAvailable(libjnivm)

FetchContent_Declare(
        libhybris
        GIT_REPOSITORY https://github.com/Dadoum/libhybris
        GIT_TAG master
)
FetchContent_MakeAvailable(libhybris)

add_dependencies(Provision hybris jnivm)
target_link_libraries(Provision hybris jnivm)
