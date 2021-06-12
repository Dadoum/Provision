#include <memory>
#include <string>
#include <vector>
#include <jnivm.h>
#include <linker/linker_soinfo.h>
#include <linker/linker.h>

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
}
