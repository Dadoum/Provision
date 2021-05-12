//
// Created by dadoum on 30/04/2021.
//
#include "LibraryHelper.hpp"

#include <hybris/common/dlfcn.h>
#include <hybris/common/hooks.h>

#include <jni.h>
#include <jnivm.h>

#include <string>

#include <dlfcn.h>
#include <stdio.h>

jnivm::VM vm;
bool isInitialized = false;

std::unordered_map<std::string, void*> hooked_functions;

void *hook_callback(const char *symbol_name, const char *requester) {
	return hooked_functions[symbol_name];
}

void LibraryHelper::init() {
	if (isInitialized) {
		fprintf(stderr, "ATTENTION ! Cette fonction est appelée automatiquement, et à déjà été exécutée précédemment. Relancer init() peut provoquer des fuites de mémoire !");
		fflush(stdout);
	}

	hybris_set_hook_callback(hook_callback);
}

void *LibraryHelper::loadLibrary(std::string const& path) {
	if (!isInitialized) {
		LibraryHelper::init();
		isInitialized = true;
	}

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

void LibraryHelper::hook(std::string const& symbol, void *replacement) {
	hooked_functions[symbol] = replacement;
}
