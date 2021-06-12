project('libprovision-glue', 'cpp')

cpp = meson.get_compiler('cpp')

add_project_arguments(['-nostdinc++', '-nodefaultlibs'], language : 'cpp')

# TODO: trouver une meilleure façon de faire c'te merde
libcpp_incl = include_directories('/usr/include/c++/v1')

cmake = import('cmake')

hybris = cmake.subproject('libhybris')
libhybris_dep = hybris.dependency('hybris')
libhybris_tgt = hybris.target('hybris')

jnivm = cmake.subproject('libjnivm')
libjnivm_dep = jnivm.dependency('jnivm')
libjnivm_tgt = jnivm.target('jnivm')

libprovision = static_library('provision-glue',
  'glue.cpp',
  dependencies: [libjnivm_dep, libhybris_dep],
  link_with: [libjnivm_tgt, libhybris_tgt],
  include_directories: libcpp_incl
#  install : true,
)
# -l:libc++.a -l:libc++abi.a -lm -lc -lcm_jnivm
libprovision_dep = declare_dependency(link_with: [libprovision, libhybris_tgt, libjnivm_tgt], link_args: ['-l:libc++.a', '-l:libc++abi.a', '-lm', 'subprojects/libjnivm/libcm_jnivm.a', 'subprojects/libhybris/libcm_hybris.a'])
