cmake_minimum_required(VERSION 3.20)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake-d/cmake-d)

project(Provision D)
include(cmake/dependencies.cmake)

set(PROVISION_SOURCE_DIR "lib/")
file(GLOB_RECURSE PROVISION_D_SOURCES "${PROVISION_SOURCE_DIR}*.d")

add_library(provision ${PROVISION_D_SOURCES})
target_include_directories(provision PUBLIC ${PROVISION_SOURCE_DIR})

if(UNIX AND NOT APPLE)
    target_link_libraries(provision PUBLIC hybris stdc++)
endif()

target_link_libraries(provision PUBLIC plist)

set(RETRIEVE_HEADERS_SOURCE_DIR "retrieve_headers/")
file(GLOB_RECURSE RETRIEVE_HEADERS_D_SOURCES "${RETRIEVE_HEADERS_SOURCE_DIR}*.d")

add_executable(retrieve_headers ${RETRIEVE_HEADERS_D_SOURCES})
target_include_directories(retrieve_headers PUBLIC ${RETRIEVE_HEADERS_SOURCE_DIR})
target_link_libraries(retrieve_headers provision)

set(SIDELOAD_IPA_SOURCE_DIR "sideload_ipa/")
file(GLOB_RECURSE SIDELOAD_IPA_D_SOURCES "${SIDELOAD_IPA_SOURCE_DIR}*.d")

add_executable(sideload_ipa ${SIDELOAD_IPA_D_SOURCES})
target_include_directories(sideload_ipa PUBLIC ${SIDELOAD_IPA_SOURCE_DIR})
target_link_libraries(sideload_ipa provision gtk-d)
