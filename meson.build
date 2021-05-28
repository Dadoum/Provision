project('Provision', 'd',
    version : '1.0',
    default_options: ['warning_level=3'])

provision_sources = []
provision_deps = []

subdir('src-glue')
subdir('src')
src = include_directories('src')

add_global_arguments('-extern-std=c++14', language: 'd')

cmake = import('cmake')

hybris = cmake.subproject('libhybris')
libhybris = hybris.dependency('hybris')

jnivm = cmake.subproject('libjnivm')
libjnivm = jnivm.dependency('jnivm')
libfakejni = jnivm.dependency('fake-jni')
libbaron = jnivm.dependency('baron')

libs_dir = custom_target(
    'libs-dir',
    output: '.libs_copy',
    command: [
        'sh',
        '-c',
        'cp -r @0@/lib32 @1@/lib32 && cp -r @0@/apple32 @1@/apple32 && touch .libs_copy'.format(meson.current_source_dir(), meson.current_build_dir()),
    ],
)

exe = executable('provision', sources: provision_sources, dependencies: [libhybris, libjnivm, libfakejni, libbaron], include_directories: src,
  install : true)
