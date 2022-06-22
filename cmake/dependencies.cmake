 # ==============================================================================
# Fetching external libraries

include(FetchContent)

FetchContent_Declare(
        libhybris
        GIT_REPOSITORY https://github.com/Dadoum/libhybris
        GIT_TAG master
)
FetchContent_MakeAvailable(libhybris)
target_compile_definitions(hybris PUBLIC BROKEN_MODE)

include(UseDub)

FetchContent_Declare(
        plist_proj
        GIT_REPOSITORY https://github.com/hatf0/plist
        PATCH_COMMAND ${DUB_DIRECTORY}/CMakeTmp/DubToCMake -s plist
)
FetchContent_MakeAvailable(plist_proj)

if(build_sideloadipa)
    DubProject_Add(gtk-d ~3.10.0)
    # DubProject_Add(mofile ~0.2.1)
endif()
