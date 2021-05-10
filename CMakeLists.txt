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
        androidh
        SVN_REPOSITORY https://github.com/ubports/android-headers/trunk/29
)
FetchContent_GetProperties(androidh
        SOURCE_DIR androidh_SOURCE_DIR)

if(NOT androidh_POPULATED)
    FetchContent_Populate(androidh)
endif()

ExternalProject_Add(
        libhybris
        GIT_REPOSITORY https://github.com/libhybris/libhybris
        GIT_TAG master
        CONFIGURE_COMMAND CFLAGS=-m32 CXXFLAGS=-m32 ../libhybris/hybris/autogen.sh --with-android-headers=${androidh_SOURCE_DIR} --enable-wayland --enable-arch=x86 --prefix=${INSTALL_PREFIX}/hybris
        BUILD_COMMAND make
        INSTALL_COMMAND ""
)

ExternalProject_Get_property(libhybris SOURCE_DIR BINARY_DIR)
target_link_directories(Provision PUBLIC ${BINARY_DIR}/common/.libs/)
target_include_directories(Provision PUBLIC ${SOURCE_DIR}/hybris/include)

add_dependencies(Provision libhybris jnivm)
target_link_libraries(Provision hybris-common jnivm)
