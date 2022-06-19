cmake_minimum_required(VERSION 3.20)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake-d/cmake-d)

project(Provision CXX D)
include(cmake/dependencies.cmake)

set(PROVISION_SOURCE_DIR "src/")
file(GLOB_RECURSE PROVISION_D_SOURCES "${PROVISION_SOURCE_DIR}*.d")
file(GLOB_RECURSE PROVISION_CPP_SOURCES "${PROVISION_SOURCE_DIR}*.cpp")

add_executable(provision ${PROVISION_D_SOURCES} ${PROVISION_CPP_SOURCES})
target_include_directories(provision PUBLIC ${PROVISION_SOURCE_DIR})
target_link_libraries(provision hybris plist)

file(COPY "ndk" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
