module provision.android.rapidandroidprototyper;

import provision.glue;
import provision.androidclass;

template RapidAndroidPrototyper(Library library) {
	@AndroidClassInfo(library, 392) class withReturnType(T): AndroidClass {
		static T run(string entryPoint, Args...)(Args a) {
			mixin implementMethod!(T function(Args), "__priv", entryPoint, ["static"]);
			__priv(a);
		}

		private static void __priv(string entryPoint, Args...)(CustomRuntimeClass!library l, Args a) {
			static void __priv_priv(CustomRuntimeClass!library, Args) {
				mixin implementNativeMethod!(entryPoint);
				execute();
			}
			__priv_priv(l, a);
		}

		static CustomRuntimeClass!library runCtor(string entryPoint, Args...)(Args a) {
			auto ret = new CustomRuntimeClass!library(PrivateConstructorOperation.ALLOCATE);
			__priv!(entryPoint, Args)(ret, a);
			return ret;
		}
	}
	alias run = withReturnType!void.run;
	alias runCtor = withReturnType!void.runCtor;
}

template CustomRuntimeClass(Library library) {
	@AndroidClassInfo(library, 0) class CustomRuntimeClass: AndroidClass {
    	mixin implementDefaultConstructor;

		void run(string librarySymbol, Args...)(Args a) {
			mixin implementNativeMethod!(librarySymbol);
			execute();
		}

		T run(T, string librarySymbol, Args...)(Args a) {
			mixin implementNativeMethod!(librarySymbol);
			execute();
		}
	}
}
