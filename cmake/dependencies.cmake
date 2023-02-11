 # ==============================================================================
# Fetching external libraries

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
        DubProject_Add(handy-httpd ~5.1.0)
    endif()
endif()