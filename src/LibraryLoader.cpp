//
// Created by dadoum on 30/04/2021.
//
#include "LibraryLoader.h"

#include <hybris/common/dlfcn.h>

#include <jni.h>
#include <jnivm.h>

#include <string>

#include <dlfcn.h>
#include <stdio.h>

jnivm::VM vm;

void *LibraryLoader::loadLibrary(std::string path) {
	printf("Chargement de %s... ", path.c_str());
	fflush(stdout);
	void *handle = hybris_dlopen(path.c_str(), RTLD_LAZY);
	if (!handle) {
		printf("échec: %s\n", hybris_dlerror());
		fflush(stdout);
		return NULL;
	}

	auto JNI_OnLoad = (jint(*)(JavaVM * vm, void *reserved))
		hybris_dlsym(handle, "JNI_OnLoad");
	if (JNI_OnLoad) {
		printf("invocation de JNI_OnLoad... ", path.c_str());
		fflush(stdout);
		auto code = JNI_OnLoad(vm.GetJavaVM(), 0);
		printf("code %d retourné... ", code);
		fflush(stdout);
	}

	printf("succès !\n", path.c_str());
	fflush(stdout);
	return handle;
}
