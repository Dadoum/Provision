cmake_minimum_required(VERSION 3.17)
project(Provision)

# ==============================================================================
# Generic flags

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_FLAGS "-m32")
set(CMAKE_CXX_FLAGS "-m32")
set(INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}/share/Provision)
add_definitions(-DEnableJNIVMGC)

# ==============================================================================
# Dependency integration

include(cmake/dependencies.cmake)

# ==============================================================================
# Provision target

file(GLOB_RECURSE PROVISION_SOURCES "src/*.cpp")
add_executable(Provision ${PROVISION_SOURCES})
target_include_directories(Provision PUBLIC "include/")
target_link_libraries(Provision hybris jnivm)
