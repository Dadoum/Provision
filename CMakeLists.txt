cmake_minimum_required(VERSION 3.20)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake-d/cmake-d)

project(Provision D)
option(build_anisetteserver "Build Anisette server" ON)
option(build_mkcassette "Build mkcassette" OFF)
option(use_native_plist "Want dlang plist" OFF)
option(link_libplist_dynamic "Load libplist at runtime" OFF)

include(cmake/dependencies.cmake)

set(PROVISION_SOURCE_DIR "lib/")
file(GLOB_RECURSE PROVISION_D_SOURCES "${PROVISION_SOURCE_DIR}*.d")

find_package(PkgConfig REQUIRED)

add_library(provision STATIC ${PROVISION_D_SOURCES})
target_include_directories(provision PUBLIC ${PROVISION_SOURCE_DIR})

if (link_libplist_dynamic)
    target_compile_versions(provision PUBLIC LibPlist)

    include(UseDub)
    FetchContent_Declare(
        plist_proj
        GIT_REPOSITORY https://github.com/Dadoum/libplist-d
        GIT_TAG d494cf3fe79a2bb20583173c0c8cf85ef33b719e
        PATCH_COMMAND ${DUB_DIRECTORY}/CMakeTmp/DubToCMake -c dynamic -s plist-d
    )
    FetchContent_MakeAvailable(plist_proj)

    add_library(plist ALIAS plist-d)
else()
    if(NOT CMAKE_CROSSCOMPILING)
        pkg_check_modules(plist IMPORTED_TARGET libplist-2.0)

        if (NOT plist_FOUND)
            pkg_check_modules(plist IMPORTED_TARGET libplist)
        endif()
    endif()

    if (plist_FOUND AND NOT use_native_plist)
        message("Using libplist. ")
        target_compile_versions(provision PUBLIC LibPlist)

        include(UseDub)
        FetchContent_Declare(
            plist_proj
            GIT_REPOSITORY https://github.com/Dadoum/libplist-d
            GIT_TAG d4b3793d9ff5f64325cd1cedb2ced31b51523ec1
            PATCH_COMMAND ${DUB_DIRECTORY}/CMakeTmp/DubToCMake -c static -s plist-d
        )
        FetchContent_MakeAvailable(plist_proj)

        add_library(plist INTERFACE)
        target_link_libraries(plist INTERFACE PkgConfig::plist plist-d)
    else()
        message(WARNING "Using fallback Property list parser. ")

        include(UseDub)
        FetchContent_Declare(
            plist_proj
            GIT_REPOSITORY https://github.com/hatf0/plist
            PATCH_COMMAND ${DUB_DIRECTORY}/CMakeTmp/DubToCMake -s plist
        )
        FetchContent_MakeAvailable(plist_proj)
    endif()
endif()

target_link_libraries(provision PUBLIC plist slf4d requests)

set(RETRIEVE_HEADERS_SOURCE_DIR "retrieve_headers/")
file(GLOB_RECURSE RETRIEVE_HEADERS_D_SOURCES "${RETRIEVE_HEADERS_SOURCE_DIR}*.d")

add_executable(retrieve_headers ${RETRIEVE_HEADERS_D_SOURCES})
target_include_directories(retrieve_headers PUBLIC ${RETRIEVE_HEADERS_SOURCE_DIR})
target_link_libraries(retrieve_headers provision)

if(build_anisetteserver)
    set(ANISETTE_SERVER_SOURCE_DIR "anisette_server/")
    file(GLOB_RECURSE ANISETTE_SERVER_D_SOURCES "${ANISETTE_SERVER_SOURCE_DIR}*.d")

    add_executable(anisette_server ${ANISETTE_SERVER_D_SOURCES})
    target_include_directories(anisette_server PUBLIC ${ANISETTE_SERVER_SOURCE_DIR})

    target_link_libraries(anisette_server provision handy-httpd)
endif()

if(build_mkcassette)
    set(MKCASSETTE_SOURCE_DIR "mkcassette/")
    file(GLOB_RECURSE MKCASSETTE_D_SOURCES "${MKCASSETTE_SOURCE_DIR}*.d")

    add_executable(mkcassette ${MKCASSETTE_D_SOURCES})
    target_include_directories(mkcassette PUBLIC ${MKCASSETTE_SOURCE_DIR})

    target_link_libraries(mkcassette provision)
endif()
