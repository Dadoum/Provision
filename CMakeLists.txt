cmake_minimum_required(VERSION 3.20)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake-d/cmake-d)

project(Provision D)
option(build_javabindings "Java bindings" OFF)
option(build_sideloadipa "Build Sideload IPA" OFF)
option(build_anisetteserver "Build Anisette server" ON)
option(link_libplist_dynamic "Load libplist at runtime" OFF)

include(cmake/dependencies.cmake)

set(PROVISION_SOURCE_DIR "lib/")
file(GLOB_RECURSE PROVISION_D_SOURCES "${PROVISION_SOURCE_DIR}*.d")

find_package(PkgConfig REQUIRED)

add_library(provision STATIC ${PROVISION_D_SOURCES})
target_include_directories(provision PUBLIC ${PROVISION_SOURCE_DIR})

if (link_libplist_dynamic)
    add_library(plist INTERFACE)
    target_compile_versions(provision PUBLIC LibPlist)
    target_compile_versions(plist INTERFACE LibPlistDynamic)
else()
    if(NOT CMAKE_CROSSCOMPILING)
        pkg_check_modules(plist IMPORTED_TARGET libplist-2.0)

        if (NOT plist_FOUND)
            pkg_check_modules(plist IMPORTED_TARGET libplist)
        endif()
    endif()

    if (plist_FOUND)
        message("Using libplist. ")
        add_library(plist ALIAS PkgConfig::plist)
        target_compile_versions(provision PUBLIC LibPlist)
    else()
        if (build_sideloadipa)
            message(FATAL_ERROR "Sideload IPA requires libplist development package. ")
        endif()
        message(WARNING "Using fallback Property list parser. ")

        FetchContent_Declare(
        plist_proj
        GIT_REPOSITORY https://github.com/hatf0/plist
        PATCH_COMMAND ${DUB_DIRECTORY}/CMakeTmp/DubToCMake -s plist
        )
        FetchContent_MakeAvailable(plist_proj)
    endif()
endif()

# Generate C++ header
# file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/include-provision)
# set_source_files_properties(lib/provision/c.d PROPERTIES COMPILE_FLAGS "-HC -HCf=${CMAKE_BINARY_DIR}/include-provision/provision.h")
# target_include_directories(provision PUBLIC ${CMAKE_BINARY_DIR}/include-provision)

target_link_libraries(provision PUBLIC plist hybris stdc++ pthread rt)

set(RETRIEVE_HEADERS_SOURCE_DIR "retrieve_headers/")
file(GLOB_RECURSE RETRIEVE_HEADERS_D_SOURCES "${RETRIEVE_HEADERS_SOURCE_DIR}*.d")

add_executable(retrieve_headers ${RETRIEVE_HEADERS_D_SOURCES})
target_include_directories(retrieve_headers PUBLIC ${RETRIEVE_HEADERS_SOURCE_DIR})
target_link_libraries(retrieve_headers provision)

if (build_javabindings)
    set_property(TARGET hybris PROPERTY POSITION_INDEPENDENT_CODE ON)

    set(JAVA_B_SOURCE_DIR "bindings/java/d/")
    file(GLOB_RECURSE JAVA_B_D_SOURCES "${JAVA_B_SOURCE_DIR}*.d")

    add_library(provision-java SHARED ${JAVA_B_D_SOURCES})
    target_include_directories(provision-java PUBLIC ${JAVA_B_SOURCE_DIR})

    target_link_libraries(provision-java provision)
endif()

if(build_sideloadipa)
    set(SIDELOAD_IPA_SOURCE_DIR "sideload_ipa/")
    file(GLOB_RECURSE SIDELOAD_IPA_D_SOURCES "${SIDELOAD_IPA_SOURCE_DIR}*.d")

    add_executable(sideload_ipa ${SIDELOAD_IPA_D_SOURCES})
    target_include_directories(sideload_ipa PUBLIC ${SIDELOAD_IPA_SOURCE_DIR})

    pkg_check_modules(imobiledevice REQUIRED IMPORTED_TARGET libimobiledevice-1.0)

    target_link_libraries(sideload_ipa provision gtk-d gmp-d PkgConfig::imobiledevice plist pbkdf2 crypto)
endif()

if(build_anisetteserver)
    set(ANISETTE_SERVER_SOURCE_DIR "anisette_server/")
    file(GLOB_RECURSE ANISETTE_SERVER_D_SOURCES "${ANISETTE_SERVER_SOURCE_DIR}*.d")

    add_executable(anisette_server ${ANISETTE_SERVER_D_SOURCES})
    target_include_directories(anisette_server PUBLIC ${ANISETTE_SERVER_SOURCE_DIR})

    target_link_libraries(anisette_server provision handy-httpd)

    set(ADI_SERVER_SOURCE_DIR "adi_server/")
    file(GLOB_RECURSE ADI_SERVER_D_SOURCES "${ADI_SERVER_SOURCE_DIR}*.d")

    # add_executable(adi_server ${ADI_SERVER_D_SOURCES})
    # target_include_directories(adi_server PUBLIC ${ADI_SERVER_D_SOURCES})

    # target_link_libraries(adi_server provision handy-httpd)
endif()
