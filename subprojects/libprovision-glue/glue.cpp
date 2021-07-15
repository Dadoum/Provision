#include <memory>
#include <string>
#include <vector>
#include <jnivm.h>
#include <map>
#include <iostream>

struct OpaqueType;

extern "C" {
	std::vector<std::string>* string_vector_create() {
		return new std::vector<std::string>();
	}
	
	void string_vector_push_back(std::vector<std::string>* vector, const char* c) {
		vector->push_back(c);
	}
	
	void string_vector_delete(std::vector<std::string>* vector) {
		delete vector;
	}
	
	std::shared_ptr<OpaqueType>* shared_ptr_create(OpaqueType* const obj, void(*d)(const OpaqueType*)) {
		return new std::shared_ptr<OpaqueType>(obj, d);
	}
	
	OpaqueType* shared_ptr_get(std::shared_ptr<OpaqueType>* const ptr) {
		return ptr->get();
	}
	
	void shared_ptr_delete(std::shared_ptr<OpaqueType>* const ptr) {
		delete ptr;
	}
	
    jnivm::VM* vm_init() {
        return new jnivm::VM();
    }
    
    JavaVM* vm_get_java_vm(jnivm::VM* vm) {
        return vm->GetJavaVM();
    }
    
    void vm_destroy(jnivm::VM* vm) {
        delete vm;
    }
    
    std::multimap<std::string, std::string>* str_str_multimap_create() {
		return new std::multimap<std::string, std::string>();
	}
	
	void str_str_multimap_insert(std::multimap<std::string, std::string>* multimap, std::string key, std::string value) {
		multimap->insert(std::pair<std::string, std::string>(key, value));
	}
	
	void str_str_multimap_to_string(std::multimap<std::string, std::string>* multimap) {
		std::multimap<std::string, std::string>::iterator it;
		std::cout << "{" << std::endl;
    	for (it = multimap->begin(); it != multimap->end(); ++it)
    	{
        	std::cout << "\t\"" << it->first << "\": \"" << it->second << "\"," << std::endl;
    	}
		std::cout << "}" << std::endl;
	}
	
    void str_str_multimap_delete(std::multimap<std::string, std::string>* multimap) {
		delete multimap;
	}
}
