cmake_minimum_required(VERSION 3.17)
project(Provision)

set(CMAKE_CXX_STANDARD 17)
include(FetchContent)

add_executable(Provision main.cpp LibraryLoader.cpp)
set(CMAKE_C_FLAGS "-m32")
set(CMAKE_CXX_FLAGS "-m32")

FetchContent_Declare(
        libjnivm
        GIT_REPOSITORY https://github.com/ChristopherHX/libjnivm
        GIT_TAG        main
)
FetchContent_MakeAvailable(libjnivm)

target_link_libraries(Provision hybris-common jnivm)
target_link_directories(Provision PUBLIC /opt/hybris32/lib)
target_include_directories(Provision PUBLIC /opt/hybris32/include)
