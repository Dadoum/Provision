//
// Created by dadoum on 30/04/2021.
//

#ifndef PROVISION_LIBRARYLOADER_H
#define PROVISION_LIBRARYLOADER_H
#include <string>

class LibraryLoader {
public:
	static void* loadLibrary(std::string path);
};


#endif //PROVISION_LIBRARYLOADER_H
