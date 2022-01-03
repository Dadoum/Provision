 # ==============================================================================
# Fetching external libraries

include(FetchContent)

FetchContent_Declare(
        libjnivm
        GIT_REPOSITORY https://github.com/ChristopherHX/libjnivm
        GIT_TAG main
)
FetchContent_MakeAvailable(libjnivm)

FetchContent_Declare(
        libhybris
        GIT_REPOSITORY https://github.com/Dadoum/libhybris
        GIT_TAG master
)
FetchContent_MakeAvailable(libhybris)

 include(UseDub)
 FetchContent_Declare(
         plist_proj
         GIT_REPOSITORY https://github.com/hatf0/plist
         PATCH_COMMAND ${DUB_DIRECTORY}/CMakeTmp/DubToCMake -s plist
 )
 FetchContent_MakeAvailable(plist_proj)
