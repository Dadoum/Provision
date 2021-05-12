#include "LibraryHelper.hpp"

#include <hybris/common/dlfcn.h>

#include <cstring>
#include <filesystem>
#include <iostream>
#include <string>
#include <vector>

#include <stdlib.h>
#include <unistd.h>

void *ld_android;
void *libdl;
void *libc;
void *cpp_shared;
void *log;
void *m;
void *z;
void *android;
void *xml2;
void *stdcpp;
void *curl;
void *coreAdi;
void *coreLskd;
void *coreFp;
void *blocks;
void *dispatch;
void *icudata;
void *icuuc;
void *icui18n;
void *daapkit;
void *coreFoundation;
void *mediaPlatform;
void *storeServicesCore;
void *mediaLibraryCore;
void *openSLES;
void *androidAppMusic;

// https://stackoverflow.com/questions/10723403/char-array-to-hex-string-c
char const hex[16] = {'0', '1', '2', '3', '4', '5', '6', '7',
					  '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

const char *logs[] = {"INCONNU",   "DÉFAUT",	  "VERBEUX",
					  "DÉBOGGAGE", "INFORMATION", "AVERTISSEMENT",
					  "ERREUR",	   "FATAL",		  "SILENCIEUX"};



std::string byte_2_str(char *bytes, int size) {
	std::string str;
	for (int i = 0; i < size; ++i) {
		const char ch = bytes[i];
		str.append(&hex[(ch & 0xF0) >> 4], 1);
		str.append(&hex[ch & 0xF], 1);
	}
	return str;
}

bool hookedAlwaysTrue(int stub) { return true; }

void __android_log_write(int prio, const char *tag, const char *text) {
	printf(">>> Journal d'Android >>> [%s] [%s]: %s\n", logs[prio], tag, text);
	fflush(stdout);
}

int resolveErrorCode(int i) {
	int i2;
	int i3;
	int ab = abs(i);
	int i4 = (ab >> 24) & 255;
	int i5 = (ab >> 16) & 255;
	int i6 = (ab >> 8) & 255;
	int i7 = ab & 255;
	if (i4 != 0) {
		i2 = i4 | 0;
		i3 = 8;
	} else {
		i2 = 0;
		i3 = 0;
	}
	if (i5 != 0) {
		i2 |= i5 << i3;
		i3 += 8;
	}
	if (i6 != 0) {
		i2 |= i6 << i3;
		i3 += 8;
	}
	return i7 != 0 ? i2 | (i7 << i3) : i2;
}

int Sph98paBcz(char *id, int i) {
	auto orig =
		(int (*)(char *, int))hybris_dlsym(storeServicesCore, "Sph98paBcz");
	int ret = orig(id, i);
	if (ret != 0) {
		printf("Sph98paBcz a échoué, code %d. \n", resolveErrorCode(ret));
		fflush(stdout);
	}
	return ret;
}

int bsawCXd() {
	auto orig = (int (*)())hybris_dlsym(storeServicesCore, "bsawCXd");
	int ret = orig();
	if (ret != 0) {
		printf("bsawCXd a échoué, code %d. \n", resolveErrorCode(ret));
		fflush(stdout);
	}
	return ret;
}

inline void checkLibrary(void* handle) {
	if (!handle) {
		printf("Certaines bibliothèques n'ont pas pu être chargées, annulation "
			   "de l'opération.\n");
		fflush(stdout);
		exit(-1);
	}
}

void initLibs() {
	LibraryHelper::hook("__android_log_write", (void*) __android_log_write);
	LibraryHelper::hook("_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityE", (void*) hookedAlwaysTrue);
	printf("Initialisation des bibliothèques...\n");
	fflush(stdout);
	ld_android = LibraryHelper::loadLibrary("lib32/ld-android.so");
	checkLibrary(ld_android);
	libdl = LibraryHelper::loadLibrary("lib32/libdl.so");
	checkLibrary(libdl);
	libc = LibraryHelper::loadLibrary("lib32/libc.so");
	checkLibrary(libc);
	cpp_shared = LibraryHelper::loadLibrary("lib32/libc++_shared.so");
	checkLibrary(cpp_shared);
	log = LibraryHelper::loadLibrary("lib32/liblog.so");
	checkLibrary(log);
	m = LibraryHelper::loadLibrary("lib32/libm.so");
	checkLibrary(m);
	z = LibraryHelper::loadLibrary("lib32/libz.so");
	checkLibrary(z);
	android = LibraryHelper::loadLibrary("lib32/libandroid.so");
	checkLibrary(android);
	xml2 = LibraryHelper::loadLibrary("lib32/libxml2.so");
	checkLibrary(xml2);
	stdcpp = LibraryHelper::loadLibrary("lib32/libstdc++.so");
	checkLibrary(stdcpp);
	curl = LibraryHelper::loadLibrary("lib32/libcurl.so");
	checkLibrary(curl);
	coreAdi = LibraryHelper::loadLibrary("lib32/libCoreADI.so");
	checkLibrary(coreAdi);
	coreLskd = LibraryHelper::loadLibrary("lib32/libCoreLSKD.so");
	checkLibrary(coreLskd);
	coreFp = LibraryHelper::loadLibrary("lib32/libCoreFP.so");
	checkLibrary(coreFp);
	blocks = LibraryHelper::loadLibrary("lib32/libBlocksRuntime.so");
	checkLibrary(blocks);
	dispatch = LibraryHelper::loadLibrary("lib32/libdispatch.so");
	checkLibrary(dispatch);
	icudata = LibraryHelper::loadLibrary("lib32/libicudata_sv_apple.so");
	checkLibrary(icudata);
	icuuc = LibraryHelper::loadLibrary("lib32/libicuuc_sv_apple.so");
	checkLibrary(icuuc);
	icui18n = LibraryHelper::loadLibrary("lib32/libicui18n_sv_apple.so");
	checkLibrary(icui18n);
	daapkit = LibraryHelper::loadLibrary("lib32/libdaapkit.so");
	checkLibrary(daapkit);
	coreFoundation = LibraryHelper::loadLibrary("lib32/libCoreFoundation.so");
	checkLibrary(coreFoundation);
	mediaPlatform = LibraryHelper::loadLibrary("lib32/libmediaplatform.so");
	checkLibrary(mediaPlatform);
	storeServicesCore =
		LibraryHelper::loadLibrary("lib32/libstoreservicescore.so");
	checkLibrary(storeServicesCore);
	mediaLibraryCore =
		LibraryHelper::loadLibrary("lib32/libmedialibrarycore.so");
	checkLibrary(mediaLibraryCore);
	openSLES = LibraryHelper::loadLibrary("lib32/libOpenSLES.so");
	checkLibrary(openSLES);
	androidAppMusic = LibraryHelper::loadLibrary("lib32/libandroidappmusic.so");
	checkLibrary(androidAppMusic);

	printf("Les bibliothèques ont été chargé avec succès !\n");
	fflush(stdout);
}

void cleanup() {
	printf("Nettoyage des bibliothèques...\n");
	fflush(stdout);
	hybris_dlclose(ld_android);
	hybris_dlclose(libdl);
	hybris_dlclose(libc);
	hybris_dlclose(cpp_shared);
	hybris_dlclose(log);
	hybris_dlclose(m);
	hybris_dlclose(z);
	hybris_dlclose(android);
	hybris_dlclose(xml2);
	hybris_dlclose(stdcpp);
	hybris_dlclose(curl);
	hybris_dlclose(coreAdi);
	hybris_dlclose(coreLskd);
	hybris_dlclose(coreFp);
	hybris_dlclose(blocks);
	hybris_dlclose(dispatch);
	hybris_dlclose(icudata);
	hybris_dlclose(icuuc);
	hybris_dlclose(icui18n);
	hybris_dlclose(daapkit);
	hybris_dlclose(coreFoundation);
	hybris_dlclose(mediaPlatform);
	hybris_dlclose(storeServicesCore);
	hybris_dlclose(mediaLibraryCore);
	hybris_dlclose(openSLES);
	hybris_dlclose(androidAppMusic);
	printf("Nettoyage terminé !\n");
	fflush(stdout);
}

int main() {
	initLibs();

	printf("Début de la procédure d'approvisionnement...\n");
	fflush(stdout);

	printf(
		"> Création du contexte des requêtes (objet natif: RequestContext)\n");
	fflush(stdout);
	auto RequestContext__ctor =
		(void (*)(void *self, std::string databasePath))hybris_dlsym(
			storeServicesCore,
			"_ZN17storeservicescore14RequestContextC1ERKNSt6__ndk112basic_"
			"stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

	std::string home;
	home += getenv("HOME");
	std::string str = home;
	str += "/.config/hxsign/";
	std::filesystem::path file = std::filesystem::absolute(str);
	if (std::filesystem::exists(file) ||
		std::filesystem::create_directory(file)) {
		// str += "dbPath.absolutePath";
	} else {
		str = ":memory:";
	}

	void *context[0xff];
	(*RequestContext__ctor)(context, str);

	printf(" > Génération d'un identifiant unique...\n");
	fflush(stdout);

	auto machineIdFile = fopen("/etc/machine-id", "r");

	char androidIdChr[16];
	fread(androidIdChr, 16, 1, machineIdFile);
	fclose(machineIdFile);
	std::string androidId = androidIdChr;
	char requestContextConfig[0xfff];

	printf(" > Création de sa configuration (objet natif: "
		   "RequestContextConfig)\n");
	fflush(stdout);

	printf("  > Initialisation de champs triviaux\n");
	fflush(stdout);
	{
		auto setBaseDirectoryPath =
			(void (*)(void *self, std::string baseDirectoryPath))hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig20setBaseDirectory"
				"PathERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_"
				"9allocatorIcEEEE");
		setBaseDirectoryPath(requestContextConfig, str);
	}
	{
		auto setClientIdentifier =
			(void (*)(void *self, std::string clientIdentifier))hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig19setClientIdentif"
				"ierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_"
				"9allocatorIcEEEE");
		setClientIdentifier(requestContextConfig, "Music"); // Xcode
	}
	{
		auto setVersionIdentifier =
			(void (*)(void *self, std::string versionIdentifier))hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig20setVersionIdenti"
				"fierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_"
				"9allocatorIcEEEE");
		setVersionIdentifier(requestContextConfig, "4.3"); // 11.2
	}
	{
		auto setPlatformIdentifier =
			(void (*)(void *self, std::string platformIdentifier))hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig21setPlatformIdent"
				"ifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_"
				"9allocatorIcEEEE");
		setPlatformIdentifier(requestContextConfig, "Android"); // Linux
	}
	{
		auto setProductVersion =
			(void (*)(void *self, std::string productVersion))hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig17setProductVersio"
				"nERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_"
				"9allocatorIcEEEE");
		setProductVersion(requestContextConfig, "10.0.0"); // 5.11.2
	}
	{
		auto setDeviceModel =
			(void (*)(void *self, std::string deviceModel))hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig14setDeviceModelER"
				"KNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_"
				"9allocatorIcEEEE");
		setDeviceModel(requestContextConfig,
					   "Google Pixel 3a"); // HP ProBook 430 G5
	}
	{
		auto setBuildVersion =
			(void (*)(void *self, std::string buildVersion))hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig15setBuildVersionE"
				"RKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_"
				"9allocatorIcEEEE");
		setBuildVersion(requestContextConfig, "5803371"); // Android 10	// 0
	}
	{
		auto setLocaleIdentifier =
			(void (*)(void *self, std::string localeIdentifier))hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig19setLocaleIdentif"
				"ierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_"
				"9allocatorIcEEEE");
		setLocaleIdentifier(requestContextConfig, "fr_FR"); // fr_FR
	}
	{
		auto setLanguageIdentifier =
			(void (*)(void *self, std::string languageIdentifier))hybris_dlsym(
				storeServicesCore,
				"_ZN17storeservicescore20RequestContextConfig21setLanguageIdent"
				"ifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_"
				"9allocatorIcEEEE");
		setLanguageIdentifier(requestContextConfig, "fr-FR"); // fr-FR
	}
	printf("  > Création de la représentation du proxy (objet natif: "
		   "HTTPProxy)\n");
	fflush(stdout);
	{
		char httpProxy[20];
		{
			unsigned short u = 80;
			auto HTTPProxy_ctor =
				(void (*)(void *self, int use_proxy, std::string ip,
						  unsigned short *port))
					hybris_dlsym(mediaPlatform,
								 "_ZN13mediaplatform9HTTPProxyC1ENS0_"
								 "4TypeERKNSt6__ndk112basic_stringIcNS2_11char_"
								 "traitsIcEENS2_9allocatorIcEEEERKt");
			(*HTTPProxy_ctor)(&httpProxy, 0, "", &u);
		}
		{
			auto setHTTPProxy =
				(void (*)(void *self, void *httpProxy))hybris_dlsym(
					storeServicesCore,
					"_ZN17storeservicescore20RequestContextConfig12setHTTPProxy"
					"ERKN13mediaplatform9HTTPProxyE");
			setHTTPProxy(requestContextConfig, httpProxy);
		}
	}

	printf("  > Initialisation de champs triviaux\n");
	fflush(stdout);
	{
		auto setResetHttpCache =
			(void (*)(void *self, bool resetHttpCache))hybris_dlsym(
				storeServicesCore, "_ZN17storeservicescore20RequestContextConfi"
								   "g17setResetHttpCacheEb");
		setResetHttpCache(
			requestContextConfig,
			false); // Valeur par défaut, mais en vrai un true se tente, c'est
					// géré par les préférences de l'appli.
	}

	{
		auto setRequestContextObserver =
			(void (*)(void *self, std::shared_ptr<void*> requestContextObserver))
				hybris_dlsym(storeServicesCore,
							 "_ZN17storeservicescore20RequestContextConfig25set"
							 "RequestContextObserverERKNSt6__ndk110shared_"
							 "ptrINS_22RequestContextObserverEEE");
		void* requestContextObserver;


		setRequestContextObserver(
			requestContextConfig,
			std::make_shared<void*>(requestContextObserver)); // À revérifier, pas sûr de mon coup.
	}

	printf("  > Création de l'identifiant de l'appareil (objet natif: "
		   "DeviceGUID)\n");
	fflush(stdout);
	{
		const std::string savedGuid = "";
		{
			auto FootHill__config =
				(int (*)(std::string const &savedGuid))hybris_dlsym(
					androidAppMusic,
					"_ZN14FootHillConfig6configERKNSt6__ndk112basic_"
					"stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE");
			(*FootHill__config)(savedGuid);
			fflush(stdout);
		}

		{
			auto DeviceGUID__ctor =
				(std::shared_ptr<void>(*)(void))hybris_dlsym(
					storeServicesCore,
					"_ZN17storeservicescore10DeviceGUID8instanceEv");
			std::string guidstr = "";
			auto guid = (*DeviceGUID__ctor)();

			if (guid != NULL) {
				auto DeviceGUID__configure =
					(void *(*)(std::string const &, void *,
							   unsigned int const &, bool const &))
						hybris_dlsym(
							storeServicesCore,
							"_ZN17storeservicescore10DeviceGUID9configureERKNSt"
							"6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_"
							"9allocatorIcEEEES9_RKjRKb");
				printf("   > Configuration du GUID... ");
				// DeviceGUID -> ??? -> FairPlay::config(string str) ->
				// FUN_000d6000(&&str) -> ADISetAndroidID
				// "Sph98paBcz"(str->cstr(), str->length) ->
				fflush(stdout);
				void *strplus;
				strplus = 0x0;
				auto storeErrorCode = (*DeviceGUID__configure)(
					androidId, (void *)&savedGuid, 29, true);
				if (storeErrorCode == 0) {
					auto DeviceGUID__guid =
						(std::shared_ptr<void>(*)(void *self))hybris_dlsym(
							storeServicesCore,
							"_ZN17storeservicescore10DeviceGUID4guidEv");
					auto dataptr = (*DeviceGUID__guid)(guid.get());
					printf(" %x \n", dataptr.get());
					fflush(stdout);
					if (dataptr != NULL) {
						printf("finalisation... ");
						auto Data__bytes = (char *(*)(void *self))hybris_dlsym(
							mediaPlatform, "_ZNK13mediaplatform4Data5bytesEv");
						auto Data__length = (long (*)(void *self))hybris_dlsym(
							mediaPlatform, "_ZNK13mediaplatform4Data6lengthEv");
						auto bytes = Data__bytes(dataptr.get());
						auto len = Data__length(dataptr.get());
						std::string guid = byte_2_str(bytes, len);
						printf("l'identifiant est %s ! ", guid.c_str());
						fflush(stdout);
					}
				} else {
					auto StoreErrorCondition_errorCode =
						(int (*)(void *const &))hybris_dlsym(
							storeServicesCore, "_ZNK17storeservicescore19StoreE"
											   "rrorCondition9errorCodeEv");
					auto StoreErrorCondition_errorDescription =
						(const std::string &(*)(void *))hybris_dlsym(
							storeServicesCore, "_ZNK17storeservicescore19StoreE"
											   "rrorCondition4whatEv");
					auto stringDesc =
						StoreErrorCondition_errorDescription(storeErrorCode);
					printf("échec. Erreur %d: %s \n",
						   StoreErrorCondition_errorCode(storeErrorCode),
						   stringDesc.c_str());
				}
			}
		}
	}

	printf("  > Création du lot de stockage (objet natif: ContentBundle)\n");
	fflush(stdout);
	// auto setPresentationInterface 		= (void(*)(void* self,
	// std::shared_ptr<void>	presentationInterface 	))
	// hybris_dlsym(storeServicesCore,
	// "_ZN17storeservicescore20RequestContextConfig24setPresentationInterfaceERKNSt6__ndk110shared_ptrINS_21PresentationInterfaceEEE"
	// );

	{
		void *filePath[3][0x40];
		void *contentBundle[0x40];

		{

			auto filePath_ctor =
				(void (*)(void *self, std::string databasePath))hybris_dlsym(
					mediaPlatform,
					"_ZN13mediaplatform8FilePathC1ERKNSt6__ndk112basic_"
					"stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

			filePath_ctor(&filePath[0], home + "/.config/hxsign");
			filePath_ctor(&filePath[1], home + "/.config/hxsign/cache");
			filePath_ctor(&filePath[2], home + "/.config/hxsign");

			{
				auto contentBundle_ctor = (void (*)(void *self, void *, void *,
													void *,
													std::vector<std::string> *))
					hybris_dlsym(mediaPlatform,
								 "_ZN13mediaplatform13ContentBundleC1ERKNS_"
								 "8FilePathES3_S3_"
								 "RKNSt6__ndk16vectorINS4_12basic_stringIcNS4_"
								 "11char_"
								 "traitsIcEENS4_9allocatorIcEEEENS9_ISB_EEEE");
				std::vector<std::string> langs = {"fr"};
				(*contentBundle_ctor)(contentBundle, &filePath[0], &filePath[1],
									  &filePath[2], &langs);
			}
		}

		{
			auto setContentBundle =
				(void (*)(void *self, std::shared_ptr<void *> contentBundle))
					hybris_dlsym(storeServicesCore,
								 "_ZN17storeservicescore20RequestContextConfig1"
								 "6setContentBundle"
								 "ERKNSt6__ndk110shared_"
								 "ptrIN13mediaplatform13ContentBundleEEE");
			setContentBundle(requestContextConfig,
							 std::make_shared<void *>(contentBundle));
		}
	}

	printf("  > Finalisation de la configuration... \n");
	fflush(stdout);
	{
		auto setFairPlayDirectoryPath = (void (*)(
			void *self, std::string const &fairPlayDirectoryPath))
			hybris_dlsym(storeServicesCore,
						 "_ZN17storeservicescore20RequestContextConfig24setFair"
						 "PlayDirectoryPathERKNSt6__ndk112basic_stringIcNS1_"
						 "11char_traitsIcEENS1_9allocatorIcEEEE");
		setFairPlayDirectoryPath(requestContextConfig,
								 home + "/.config/hxsign/fairPlay");
	}

	{
		auto RequestContext__init = (void (*)(
			void *self, std::shared_ptr<void *> config))
			hybris_dlsym(storeServicesCore,
						 "_ZN17storeservicescore14RequestContext4initERKNSt6__"
						 "ndk110shared_ptrINS_20RequestContextConfigEEE");

		RequestContext__init(context, std::make_shared<void *>(requestContextConfig));
	}

	cleanup();
	return 0;
}
