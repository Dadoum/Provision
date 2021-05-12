//
// Created by dadoum on 30/04/2021.
//

#ifndef PROVISION_LIBRARYHELPER_HPP
#define PROVISION_LIBRARYHELPER_HPP

#include <string>

class LibraryHelper {
  public:
	static void init();
	static void *loadLibrary(std::string path);
	static void hook(std::string symbol, void *replacement);
};

#endif // PROVISION_LIBRARYHELPER_HPP
