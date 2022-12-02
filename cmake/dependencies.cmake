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

if(build_sideloadipa OR build_anisetteserver)
    include(UseDub)

    if(build_sideloadipa)
        DubProject_Add(gtk-d ~3.10.0)
        DubProject_Add(gmp-d ~0.2.11)
        # DubProject_Add(mofile ~0.2.1)

        DubProject_Add(pbkdf2 ~0.1.3)
        DubProject_Add(crypto ~0.2.17)
    endif()

    if(build_anisetteserver)
        DubProject_Add(handy-httpd ~3.3.0)
    endif()
endif()