#include <iostream>
#include <filesystem>
#include <string>
#include <unistd.h>
#include <limits.h>
#include <stdlib.h>
#include <hybris/common/dlfcn.h>
#include <hybris/common/hooks.h>
#include <fstream>
#include <vector>
#include "LibraryLoader.h"

void* ld_android;
void* libdl;
void* libc;
void* cpp_shared;
void* log;
void* m;
void* z;
void* android;
void* xml2;
void* stdcpp;
void* curl;
void* coreAdi;
void* coreLskd;
void* coreFp;
void* blocks;
void* dispatch;
void* icudata;
void* icuuc;
void* icui18n;
void* daapkit;
void* coreFoundation;
void* mediaPlatform;
void* storeServicesCore;
void* mediaLibraryCore;
void* openSLES;
void* androidAppMusic;

// https://stackoverflow.com/questions/10723403/char-array-to-hex-string-c
char const hex[16] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A',   'B','C','D','E','F'};

std::string byte_2_str(char* bytes, int size) {
	std::string str;
	for (int i = 0; i < size; ++i) {
		const char ch = bytes[i];
		str.append(&hex[(ch  & 0xF0) >> 4], 1);
		str.append(&hex[ch & 0xF], 1);
	}
	return str;
}

bool hookedAlwaysTrue(int stub) {
	return true;
}

void debuglog (int priority,char *param_2,char *param_3,uint param_4,char *param_5,
							 std::string const& param_6, int param_7) {
	std::string param = param_5;
	printf("%s\n", param_5);
}

void* hooks(const char *symbol_name, const char *requester) {
	std::string symbol = symbol_name;
	std::string rqst = requester;
	if (symbol == "_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityE") {
		return (void*) hookedAlwaysTrue;
	}
	else if (symbol.find("DebugLogInternal") != std::string::npos){
		return (void*) debuglog;
	}
	return NULL;
}

void initLibs() {
	printf("Initialisation des bibliothèques...\n");
	fflush(stdout);
	ld_android			= LibraryLoader::loadLibrary("lib32/ld-android.so"				);
	libdl				= LibraryLoader::loadLibrary("lib32/libdl.so"					);
	libc				= LibraryLoader::loadLibrary("lib32/libc.so"					);
	cpp_shared			= LibraryLoader::loadLibrary("lib32/libc++_shared.so"			);
	log 				= LibraryLoader::loadLibrary("lib32/liblog.so"					);
	m 					= LibraryLoader::loadLibrary("lib32/libm.so"					);
	z 					= LibraryLoader::loadLibrary("lib32/libz.so"					);
	android				= LibraryLoader::loadLibrary("lib32/libandroid.so"				);
	xml2				= LibraryLoader::loadLibrary("lib32/libxml2.so"				);
	stdcpp				= LibraryLoader::loadLibrary("lib32/libstdc++.so"				);
	curl 				= LibraryLoader::loadLibrary("lib32/libcurl.so"				);
	coreAdi 			= LibraryLoader::loadLibrary("lib32/libCoreADI.so"				);
	coreLskd 			= LibraryLoader::loadLibrary("lib32/libCoreLSKD.so"			);
	coreFp	 			= LibraryLoader::loadLibrary("lib32/libCoreFP.so"				);
	blocks	 			= LibraryLoader::loadLibrary("lib32/libBlocksRuntime.so"		);
	dispatch 			= LibraryLoader::loadLibrary("lib32/libdispatch.so"			);
	icudata 			= LibraryLoader::loadLibrary("lib32/libicudata_sv_apple.so"	);
	icuuc 				= LibraryLoader::loadLibrary("lib32/libicuuc_sv_apple.so"		);
	icui18n 			= LibraryLoader::loadLibrary("lib32/libicui18n_sv_apple.so"	);
	daapkit 			= LibraryLoader::loadLibrary("lib32/libdaapkit.so"				);
	coreFoundation		= LibraryLoader::loadLibrary("lib32/libCoreFoundation.so"		);
	hybris_set_hook_callback(hooks);
	mediaPlatform 		= LibraryLoader::loadLibrary("lib32/libmediaplatform.so"		);
	storeServicesCore	= LibraryLoader::loadLibrary("lib32/libstoreservicescore.so"	);
	mediaLibraryCore	= LibraryLoader::loadLibrary("lib32/libmedialibrarycore.so"	);
	openSLES			= LibraryLoader::loadLibrary("lib32/libOpenSLES.so"			);
	androidAppMusic		= LibraryLoader::loadLibrary("lib32/libandroidappmusic.so"		);

	if (!ld_android ||
		!libdl ||
		!libc ||
		!cpp_shared ||
		!log ||
		!m ||
		!z ||
		!android ||
		!xml2 ||
		!stdcpp ||
		!curl ||
		!coreAdi ||
		!coreLskd ||
		!coreFp ||
		!blocks ||
		!dispatch ||
		!icudata ||
		!icuuc ||
		!icui18n ||
		!daapkit ||
		!coreFoundation ||
		!mediaPlatform ||
		!storeServicesCore) {
		printf("Certaines bibliothèques n'ont pas pu être chargées, annulation de l'opération.\n");
		fflush(stdout);
		exit(-1);
	}

	printf("Les bibliothèques ont été chargé avec succès !\n");
	fflush(stdout);
}

void cleanup() {
	printf("Nettoyage des bibliothèques...\n");
	fflush(stdout);
	hybris_dlclose(ld_android		);
	hybris_dlclose(libdl			);
	hybris_dlclose(libc				);
	hybris_dlclose(cpp_shared		);
	hybris_dlclose(log				);
	hybris_dlclose(m				);
	hybris_dlclose(z				);
	hybris_dlclose(android			);
	hybris_dlclose(xml2				);
	hybris_dlclose(stdcpp			);
	hybris_dlclose(curl				);
	hybris_dlclose(coreAdi			);
	hybris_dlclose(coreLskd			);
	hybris_dlclose(coreFp			);
	hybris_dlclose(blocks			);
	hybris_dlclose(dispatch			);
	hybris_dlclose(icudata			);
	hybris_dlclose(icuuc			);
	hybris_dlclose(icui18n			);
	hybris_dlclose(daapkit			);
	hybris_dlclose(coreFoundation	);
	hybris_dlclose(mediaPlatform	);
	hybris_dlclose(storeServicesCore);
	hybris_dlclose(mediaLibraryCore	);
	hybris_dlclose(openSLES			);
	hybris_dlclose(androidAppMusic	);
	printf("Nettoyage terminé !\n");
	fflush(stdout);
}

int main() {
	initLibs();

	printf("Début de la procédure d'approvisionnement...\n");
	fflush(stdout);


	printf("> Création du contexte des requêtes (objet natif: RequestContext)\n");
	fflush(stdout);
	auto RequestContext__ctor = (void(*)(void* self, std::string databasePath)) hybris_dlsym(storeServicesCore, "_ZN17storeservicescore14RequestContextC1ERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

	std::string str;
	str += getenv("HOME");
	str += "/.config/hxsign/";
	std::filesystem::path file = std::filesystem::absolute(str);
	if (std::filesystem::exists(file) || std::filesystem::create_directory(file)) {
		// str += "dbPath.absolutePath";
	}
	else {
		str = ":memory:";
	}

	printf(" > Génération d'un identifiant unique...\n");
	fflush(stdout);

	auto machineIdFile = fopen("/etc/machine-id", "r");

	char androidIdChr[16];
	fread(androidIdChr, 16, 1, machineIdFile);
	fclose(machineIdFile);
	std::string androidId = androidIdChr;
	char requestContextConfig[0xfff];

	printf(" > Création de sa configuration (objet natif: RequestContextConfig)\n");
	fflush(stdout);

	printf("  > Initialisation de champs triviaux\n");
	fflush(stdout);
	{
		auto setBaseDirectoryPath = (void (*)(void *self, std::string baseDirectoryPath)) hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig20setBaseDirectoryPathERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
		setBaseDirectoryPath(requestContextConfig, str);
	}
	{
		auto setClientIdentifier 			= (void(*)(void* self, std::string	clientIdentifier		)) hybris_dlsym(storeServicesCore, "_ZN17storeservicescore20RequestContextConfig19setClientIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE"			);
		setClientIdentifier(requestContextConfig, "Music");                // Xcode
	}
	{
		auto setVersionIdentifier = (void (*)(void *self, std::string versionIdentifier)) hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig20setVersionIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
		setVersionIdentifier(requestContextConfig, "4.3");                // 11.2
	}
	{
		auto setPlatformIdentifier = (void (*)(void *self, std::string platformIdentifier)) hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig21setPlatformIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
		setPlatformIdentifier(requestContextConfig, "Android");            // Linux
	}
	{
		auto setProductVersion = (void (*)(void *self, std::string productVersion)) hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig17setProductVersionERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
		setProductVersion(requestContextConfig, "10.0.0");                // 5.11.2
	}
	{
		auto setDeviceModel = (void (*)(void *self, std::string deviceModel)) hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig14setDeviceModelERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
		setDeviceModel(requestContextConfig, "Google Pixel 3a");        // HP ProBook 430 G5
	}
	{
		auto setBuildVersion = (void (*)(void *self, std::string buildVersion)) hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig15setBuildVersionERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
		setBuildVersion(requestContextConfig, "5803371"); // Android 10	// 0
	}
	{
		auto setLocaleIdentifier = (void (*)(void *self, std::string localeIdentifier)) hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig19setLocaleIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
		setLocaleIdentifier(requestContextConfig, "fr_FR");                // fr_FR
	}
	{
		auto setLanguageIdentifier = (void (*)(void *self, std::string languageIdentifier)) hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig21setLanguageIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
		setLanguageIdentifier(requestContextConfig, "fr-FR");            // fr-FR
	}
	printf("  > Création de la représentation du proxy (objet natif: HTTPProxy)\n");
	fflush(stdout);
	{
		char httpProxy[20];
		{
			unsigned short u = 80;
			auto HTTPProxy_ctor = (void (*)(void *self, int use_proxy, std::string ip,
											unsigned short *port)) hybris_dlsym(mediaPlatform,
																				"_ZN13mediaplatform9HTTPProxyC1ENS0_4TypeERKNSt6__ndk112basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEERKt");
			(*HTTPProxy_ctor)(&httpProxy, 0, "", &u);
		}
		{
			auto setHTTPProxy = (void (*)(void *self, void *httpProxy)) hybris_dlsym(storeServicesCore,
																					 "_ZN17storeservicescore20RequestContextConfig12setHTTPProxyERKN13mediaplatform9HTTPProxyE");
			setHTTPProxy(requestContextConfig, httpProxy);
		}
	}

	printf("  > Initialisation de champs triviaux\n");
	fflush(stdout);
	{
		auto setResetHttpCache = (void (*)(void *self, bool resetHttpCache)) hybris_dlsym(storeServicesCore,
																						  "_ZN17storeservicescore20RequestContextConfig17setResetHttpCacheEb");
		setResetHttpCache(requestContextConfig,
						  false); // Valeur par défaut, mais en vrai un true se tente, c'est géré par les préférences de l'appli.

	}

	{
		auto setRequestContextObserver		= (void(*)(void* self, std::shared_ptr<void>	requestContextObserver	)) hybris_dlsym(storeServicesCore, "_ZN17storeservicescore20RequestContextConfig25setRequestContextObserverERKNSt6__ndk110shared_ptrINS_22RequestContextObserverEEE"					);
		std::shared_ptr<void> requestContextObserver = NULL;
		setRequestContextObserver(requestContextConfig, requestContextObserver); // À revérifier, pas sûr de mon coup.
	}

	printf("  > Création de l'identifiant de l'appareil (objet natif: DeviceGUID)\n");
	fflush(stdout);
	{
		{
			auto FootHill__config = (int (*)(std::string const &savedGuid)) hybris_dlsym(androidAppMusic,
																						 "_ZN14FootHillConfig6configERKNSt6__ndk112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE");
			(*FootHill__config)(androidId);
			fflush(stdout);
		}

		{
			auto DeviceGUID__ctor = (std::shared_ptr<void>(*)(void)) hybris_dlsym(storeServicesCore,
																				  "_ZN17storeservicescore10DeviceGUID8instanceEv");
			std::string guidstr = "";
			auto guid = (*DeviceGUID__ctor)();

			if (guid != NULL) {
				const std::string savedGuid = "";
				auto DeviceGUID__configure = (void* (*)(std::string const &, std::string const &, unsigned int const &,
													  bool const &)) hybris_dlsym(storeServicesCore,
																				  "_ZN17storeservicescore10DeviceGUID9configureERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEES9_RKjRKb");
				printf("   > Configuration du GUID... ");
				fflush(stdout);
				auto storeErrorCode = (*DeviceGUID__configure)(androidId, savedGuid, 29, true);
				if (storeErrorCode == 0) {
					auto DeviceGUID__guid = (std::shared_ptr<void>(*)(void* self)) hybris_dlsym(storeServicesCore, "_ZN17storeservicescore10DeviceGUID4guidEv");
					auto dataptr = (*DeviceGUID__guid)(guid.get());
					printf(" %x \n", dataptr.get());
					fflush(stdout);
					if (dataptr != NULL) {
						printf("finalisation... ");
						auto Data__bytes = (char*(*)(void* self)) hybris_dlsym(mediaPlatform, "_ZNK13mediaplatform4Data5bytesEv");
						auto Data__length = (long(*)(void* self)) hybris_dlsym(mediaPlatform, "_ZNK13mediaplatform4Data6lengthEv");
						auto bytes = Data__bytes(dataptr.get());
						auto len = Data__length(dataptr.get());
						std::string guid = byte_2_str(bytes, len);
						printf("l'identifiant est %s ! ", guid.c_str());
						fflush(stdout);
					}
				}
				else {
					auto StoreErrorCondition_errorCode = (int (*)(void* const &)) hybris_dlsym(storeServicesCore,
																						"_ZNK17storeservicescore19StoreErrorCondition9errorCodeEv");
					auto StoreErrorCondition_errorDescription = (const std::string (*)(void*)) hybris_dlsym(storeServicesCore,
																						"_ZNK17storeservicescore19StoreErrorCondition16errorDescriptionEv");
					printf("échec. Erreur %d: %s \n", StoreErrorCondition_errorCode(storeErrorCode), StoreErrorCondition_errorDescription(storeErrorCode).c_str());
				}
			}
		}
	}

	printf("  > Création du lot de stockage (objet natif: ContentBundle)\n");
	fflush(stdout);
	// auto setPresentationInterface 		= (void(*)(void* self, std::shared_ptr<void>	presentationInterface 	)) hybris_dlsym(storeServicesCore, "_ZN17storeservicescore20RequestContextConfig24setPresentationInterfaceERKNSt6__ndk110shared_ptrINS_21PresentationInterfaceEEE"					);

	{
		void* filePath[3][0x40];
		void* contentBundle[0x40];

		{

			{
				auto filePath_ctor = (void(*)(void* self, std::string databasePath)) hybris_dlsym(mediaPlatform,"_ZN13mediaplatform8FilePathC1ERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

				(*filePath_ctor)(filePath[0], "/home/dadoum/.config/hxsign");
				(filePath_ctor)(filePath[1], "/home/dadoum/.config/hxsign/cache");
				(filePath_ctor)(filePath[2], "/home/dadoum/.config/hxsign");

				{
					auto contentBundle_ctor = (void (*)(void* self, void*, void*, void*, std::vector<std::string>*)) hybris_dlsym(mediaPlatform,"_ZN13mediaplatform13ContentBundleC1ERKNS_8FilePathES3_S3_RKNSt6__ndk16vectorINS4_12basic_stringIcNS4_11char_traitsIcEENS4_9allocatorIcEEEENS9_ISB_EEEE");
					std::vector<std::string> langs = { "en" };
					(*contentBundle_ctor)(contentBundle, &filePath[0], &filePath[1], &filePath[2], &langs);
				}
			}
		}

		{
			auto setContentBundle 				= (void(*)(void* self, std::shared_ptr<void*> contentBundle )) hybris_dlsym(storeServicesCore, "_ZN17storeservicescore20RequestContextConfig16setContentBundleERKNSt6__ndk110shared_ptrIN13mediaplatform13ContentBundleEEE"						);
			setContentBundle(requestContextConfig, std::make_shared<void*>(contentBundle));
		}

	}

	printf("  > Finalisation de la configuration... \n");
	fflush(stdout);
	{
		auto setFairPlayDirectoryPath 		= (void(*)(void* self, std::string const& fairPlayDirectoryPath)) hybris_dlsym(storeServicesCore, "_ZN17storeservicescore20RequestContextConfig24setFairPlayDirectoryPathERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE"	);
		setFairPlayDirectoryPath(requestContextConfig, "/home/dadoum/.config/hxsign/fairPlay");
	}


	void* context;
	(*RequestContext__ctor)(&context, str);

	cleanup();
	return 0;
}
