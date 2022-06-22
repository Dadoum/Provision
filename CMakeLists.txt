cmake_minimum_required(VERSION 3.20)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake-d/cmake-d)

project(Provision D CXX)
option(build_sideloadipa "Build Sideload IPA" ON)

include(cmake/dependencies.cmake)

set(PROVISION_SOURCE_DIR "lib/")
file(GLOB_RECURSE PROVISION_D_SOURCES "${PROVISION_SOURCE_DIR}*.d")

add_library(provision STATIC ${PROVISION_D_SOURCES})
target_include_directories(provision PUBLIC ${PROVISION_SOURCE_DIR})
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/include-provision)
set_source_files_properties(lib/provision/c.d PROPERTIES COMPILE_FLAGS "-HC -HCf=${CMAKE_BINARY_DIR}/include-provision/provision.h")
target_include_directories(provision PUBLIC ${CMAKE_BINARY_DIR}/include-provision)

target_link_libraries(provision PUBLIC plist hybris stdc++)

set(RETRIEVE_HEADERS_SOURCE_DIR "retrieve_headers/")
file(GLOB_RECURSE RETRIEVE_HEADERS_D_SOURCES "${RETRIEVE_HEADERS_SOURCE_DIR}*.d")

add_executable(retrieve_headers ${RETRIEVE_HEADERS_D_SOURCES})
target_include_directories(retrieve_headers PUBLIC ${RETRIEVE_HEADERS_SOURCE_DIR})
target_link_libraries(retrieve_headers provision)

# set(CXX_INTEROP_EXAMPLE_SOURCE_DIR "cxx_interop_example/")
# file(GLOB_RECURSE CXX_INTEROP_EXAMPLE_CXX_SOURCES "${CXX_INTEROP_EXAMPLE_SOURCE_DIR}*.cpp")

# add_executable(cxx_interop_example ${CXX_INTEROP_EXAMPLE_CXX_SOURCES})
# target_include_directories(cxx_interop_example PUBLIC ${CXX_INTEROP_EXAMPLE_SOURCE_DIR})
# target_link_libraries(cxx_interop_example provision)

if(build_sideloadipa)
    set(SIDELOAD_IPA_SOURCE_DIR "sideload_ipa/")
    file(GLOB_RECURSE SIDELOAD_IPA_D_SOURCES "${SIDELOAD_IPA_SOURCE_DIR}*.d")

    add_executable(sideload_ipa ${SIDELOAD_IPA_D_SOURCES})
    target_include_directories(sideload_ipa PUBLIC ${SIDELOAD_IPA_SOURCE_DIR})

    find_package(PkgConfig REQUIRED)
    pkg_check_modules(imobiledevice REQUIRED IMPORTED_TARGET libimobiledevice-1.0)

    target_link_libraries(sideload_ipa provision gtk-d PkgConfig::imobiledevice)
endif()
