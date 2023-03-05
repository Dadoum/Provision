 # ==============================================================================
# Fetching external libraries

if(build_anisetteserver)
    include(UseDub)
    DubProject_Add(handy-httpd ~5.2.1)
endif()