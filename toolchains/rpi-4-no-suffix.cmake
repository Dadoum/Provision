#File raspberrytoolchain.cmake for ROS and system packages to cross compile.
SET(CMAKE_SYSTEM_NAME Linux)

SET(_CMAKE_TOOLCHAIN_PREFIX "aarch64-linux-gnu-")

SET(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
SET(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
SET(CMAKE_D_COMPILER aarch64-linux-gnu-gdc)

# Below call is necessary to avoid non-RT problem.
SET(CMAKE_LIBRARY_ARCHITECTURE aarch64-linux-gnu)

SET(RASPBERRY_ROOT_PATH /usr/aarch64-linux-gnu/sys-root)
SET(CMAKE_SYSROOT ${RASPBERRY_ROOT_PATH})

SET(CMAKE_FIND_ROOT_PATH ${RASPBERRY_ROOT_PATH})

#Have to set this one to BOTH, to allow CMake to find rospack
#This set of variables controls whether the CMAKE_FIND_ROOT_PATH and CMAKE_SYSROOT are used for find_xxx() operations.
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
# SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

#If you have installed cross compiler to somewhere else, please specify that path.
SET(COMPILER_ROOT ${RASPBERRY_ROOT_PATH}) 

SET(CMAKE_PREFIX_PATH ${RASPBERRY_ROOT_PATH})

SET(CMAKE_D_FLAGS "${CMAKE_D_FLAGS} -defaultlib=:libgphobos.a -fall-instantiations" CACHE INTERNAL "" FORCE)
# SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --sysroot=${RASPBERRY_ROOT_PATH}" CACHE INTERNAL "" FORCE)
# SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --sysroot=${RASPBERRY_ROOT_PATH}" CACHE INTERNAL "" FORCE)
# SET(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} --sysroot=${RASPBERRY_ROOT_PATH}" CACHE INTERNAL "" FORCE)
# SET(CMAKE_CXX_LINK_FLAGS "${CMAKE_CXX_LINK_FLAGS} --sysroot=${RASPBERRY_ROOT_PATH}" CACHE INTERNAL "" FORCE)

SET(LD_LIBRARY_PATH ${RASPBERRY_ROOT_PATH}/lib)
