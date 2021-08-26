project('Provision', ['c', 'd'],
    version : '1.0',
    default_options: ['warning_level=3'])

build_args = ['-lsystemd']

cc = meson.get_compiler('c')
d = meson.get_compiler('d')

if get_option('buildtype').startswith('debug')
	if d.get_id() == 'llvm'
		add_global_arguments(['--d-debug', '-link-defaultlib-shared=false', '-preview=shortenedMethods'], language: 'd')
	elif d.get_id() == 'gcc'
		add_global_arguments(['-debug', '-link-defaultlib-shared=false'], language: 'd')
	else
		add_global_arguments(['-debug', '-defaultlib=:libphobos2.a,:libdruntime.a'], language: 'd')
	endif
else
	if d.get_id() == 'llvm'
		add_global_arguments(['--release', '--d-debug=0', '-link-defaultlib-shared=false', '-preview=shortenedMethods'], language: 'd')
	elif d.get_id() == 'gcc'
		add_global_arguments(['-release', '-debug=0', '-link-defaultlib-shared=false'], language: 'd')
	else
		add_global_arguments(['-release', '-debug=0', '-defaultlib=:libphobos2.a,:libdruntime.a'], language: 'd')
	endif
endif

provision_sources = []
provision_deps = []

subdir('src')
src = include_directories('src')

add_global_arguments(build_args, language: 'd')
add_global_arguments(build_args + ['-DWANT_TRACE'], language: 'c')
add_global_arguments(build_args + ['-nostdinc++', '-I/usr/include/c++/v1', '-nodefaultlibs', '-lc++', '-lc++abi', '-lm', '-lc', '-lgcc_s', '-lgcc', '-DWANT_TRACE'], language: 'cpp')

libprovision = subproject('libprovision-glue')
libprovision_dep = libprovision.get_variable('libprovision_dep')

cmake = import('cmake')

hybris = cmake.subproject('libhybris')
libhybris = hybris.dependency('hybris')

jnivm = cmake.subproject('libjnivm')
libjnivm = jnivm.dependency('jnivm')

# import('dlang')
# dxml_dep = dependency('dxml', method: 'dub')
# plist_dep = dependency('plist', version: '~master', method: 'dub')

exe = executable('provision', sources: provision_sources, dependencies: [libhybris, libjnivm, libprovision_dep], include_directories: src,
  install : true, link_args : build_args)
