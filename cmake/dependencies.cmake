 # ==============================================================================
# Fetching external libraries

include(UseDub)

DubProject_Add(requests ~2.0.9)
DubProject_Add(slf4d ~2.1.1)

if(build_anisetteserver)
    DubProject_Add(handy-httpd ~5.2.1)
endif()