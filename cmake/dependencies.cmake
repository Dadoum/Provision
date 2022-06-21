 # ==============================================================================
# Fetching external libraries

include(FetchContent)

if (UNIX AND NOT APPLE)
    FetchContent_Declare(
            libhybris
            GIT_REPOSITORY https://github.com/Dadoum/libhybris
            GIT_TAG master
    )
    FetchContent_MakeAvailable(libhybris)
    target_compile_definitions(hybris PUBLIC BROKEN_MODE)
endif()

include(UseDub)
DubProject_Add(gtk-d ~3.10.0)

FetchContent_Declare(
        plist_proj
        GIT_REPOSITORY https://github.com/hatf0/plist
        PATCH_COMMAND ${DUB_DIRECTORY}/CMakeTmp/DubToCMake -s plist
)
FetchContent_MakeAvailable(plist_proj)
