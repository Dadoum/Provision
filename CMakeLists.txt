cmake_minimum_required(VERSION 3.20)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -nostdinc++ -nodefaultlibs -lc -isystem /usr/include/c++/v1 -lgcc_s")
set(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -L=-l:libc++.a -L=-l:libc++abi.a")
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake-d/cmake-d)

project(Provision CXX D)
include(cmake/dependencies.cmake)

set(PROVISION_SOURCE_DIR "src/")
file(GLOB_RECURSE PROVISION_D_SOURCES "${PROVISION_SOURCE_DIR}*.d")
file(GLOB_RECURSE PROVISION_CPP_SOURCES "${PROVISION_SOURCE_DIR}*.cpp")

add_executable(provision ${PROVISION_D_SOURCES} ${PROVISION_CPP_SOURCES})
target_include_directories(provision PUBLIC ${PROVISION_SOURCE_DIR})
target_link_libraries(provision hybris jnivm systemd plist)

file(COPY "ndk" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
