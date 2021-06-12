project('Provision', ['c', 'd'],
    version : '1.0',
    default_options: ['warning_level=3'])

build_args = []

cc = meson.get_compiler('c')
d = meson.get_compiler('d')
assert(d.get_id() == 'llvm', 'Fonctionne uniquement avec ldc pour le moment; Veuillez définir DC conformément. (vous utilisez \'' + d.get_id() + '\' actuellement)')

if get_option('buildtype').startswith('debug')
	if d.get_id() == 'llvm'
		add_global_arguments(['--d-debug', '-link-defaultlib-shared=false', '-defaultlib=:libphobos2.a,:libdruntime.a'], language: 'd')
	else
		add_global_arguments(['--debug', '-link-defaultlib-shared=false', '-defaultlib=:libphobos2.a,:libdruntime.a'], language: 'd')
	endif
else
	if d.get_id() == 'llvm'
		add_global_arguments(['--release', '--d-debug=0', '-link-defaultlib-shared=false', '-defaultlib=:libphobos2.a,:libdruntime.a'], language: 'd')
	else
		add_global_arguments(['--release', '--debug=0', '-link-defaultlib-shared=false', '-defaultlib=:libphobos2.a,:libdruntime.a'], language: 'd')
	endif
endif

provision_sources = []
provision_deps = []

subdir('src')
src = include_directories('src')

add_global_arguments(build_args + ['-preview=shortenedMethods'], language: 'd')
add_global_arguments(build_args, language: 'c')
add_global_arguments(build_args + ['-nostdinc++', '-I/usr/include/c++/v1', '-nodefaultlibs', '-lc++', '-lc++abi', '-lm', '-lc', '-lgcc_s', '-lgcc'], language: 'cpp')

libprovision = subproject('libprovision-glue')
libprovision_dep = libprovision.get_variable('libprovision_dep')

cmake = import('cmake')

hybris = cmake.subproject('libhybris')
libhybris = hybris.dependency('hybris')

jnivm = cmake.subproject('libjnivm')
libjnivm = jnivm.dependency('jnivm')

# libs_dir = custom_target(
#     'libs-dir',
#     output: '.libs_copy',
#     command: [
#         'sh',
#         '-c',
#         'cp -r @0@/lib32 @1@/lib32 && cp -r @0@/apple32 @1@/apple32 && touch .libs_copy'.format(meson.current_source_dir(), meson.current_build_dir()),
#     ],
# )

exe = executable('provision', sources: provision_sources, dependencies: [libhybris, libjnivm, libprovision_dep], include_directories: src,
  install : true, link_args : build_args)
