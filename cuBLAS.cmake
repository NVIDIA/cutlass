
message(STATUS "Configuring cublas ...")

if(DEFINED CUTLASS_ENABLE_CUBLAS AND NOT CUTLASS_ENABLE_CUBLAS)
  
  # Don't add cuBLAS if it's defined and false, assume it's not found.

  set(CUBLAS_FOUND OFF)
  message(STATUS "cuBLAS Disabled.")

elseif(NOT TARGET cublas)
  
  find_path(
    _CUBLAS_INCLUDE_DIR cublas.h
    PATHS
    ${CUDA_TOOLKIT_ROOT_DIR}/include
    $ENV{CUBLAS_PATH}/include
    $ENV{CUDA_PATH}/include
    ${CUBLAS_PATH}/include
    /usr/include)

  find_library(
    _CUBLAS_LIBRARY cublas
    HINTS
    ${CUDA_TOOLKIT_ROOT_DIR}/lib64
    ${CUDA_TOOLKIT_ROOT_DIR}/lib/x64
    $ENV{CUBLAS_PATH}/lib64
    $ENV{CUBLAS_PATH}/lib/x64
    $ENV{CUDA_PATH}/lib64
    $ENV{CUDA_PATH}/lib/x64
    ${CUBLAS_PATH}/lib64
    ${CUBLAS_PATH}/lib/x64
    /usr/lib/x86_64-linux-gnu)

  if(_CUBLAS_INCLUDE_DIR AND _CUBLAS_LIBRARY)

    message(STATUS "cuBLAS: ${_CUBLAS_LIBRARY}")
    message(STATUS "cuBLAS: ${_CUBLAS_INCLUDE_DIR}")
    
    set(CUBLAS_FOUND ON CACHE INTERNAL "cublas Library Found")
    set(CUBLAS_LIBRARY ${_CUBLAS_LIBRARY})
    set(CUBLAS_INCLUDE_DIR ${_CUBLAS_INCLUDE_DIR})

  else()

    message(STATUS "cublas not found.")
    set(CUBLAS_FOUND OFF CACHE INTERNAL "cublas Library Found")

  endif()

endif()

set(CUTLASS_ENABLE_CUBLAS ${CUBLAS_FOUND} CACHE BOOL "Enable CUTLASS to build with cuBLAS library.")

if(CUTLASS_ENABLE_CUBLAS AND NOT CUBLAS_FOUND)
  message(FATAL_ERROR "CUTLASS_ENABLE_CUBLAS enabled but cuBLAS library could not be found.")
endif()

if(CUTLASS_ENABLE_CUBLAS AND NOT TARGET cublas)

  if(WIN32)
    add_library(cublas STATIC IMPORTED)
  else()
    add_library(cublas SHARED IMPORTED)
  endif()

  set_property(
    TARGET cublas
    PROPERTY IMPORTED_LOCATION
    ${CUBLAS_LIBRARY})
    
  target_include_directories(
    cublas
    INTERFACE
    $<INSTALL_INTERFACE:include>
    $<BUILD_INTERFACE:${CUBLAS_INCLUDE_DIR}>)

  find_library(
    _CUBLASLT_LIBRARY cublasLt
    HINTS
    ${CUDA_TOOLKIT_ROOT_DIR}/lib64
    ${CUDA_TOOLKIT_ROOT_DIR}/lib/x64
    $ENV{CUBLAS_PATH}/lib64
    $ENV{CUBLAS_PATH}/lib/x64
    $ENV{CUDA_PATH}/lib64
    $ENV{CUDA_PATH}/lib/x64
    ${CUBLAS_PATH}/lib64
    ${CUBLAS_PATH}/lib/x64
    /usr/lib/x86_64-linux-gnu)

  if(_CUBLASLT_LIBRARY)

    if(WIN32)
      add_library(cublasLt STATIC IMPORTED)
    else()
      add_library(cublasLt SHARED IMPORTED)
    endif()
    
    set_property(
      TARGET cublasLt
      PROPERTY IMPORTED_LOCATION
      ${_CUBLASLT_LIBRARY})
    
    target_link_libraries(
      cublas
      INTERFACE
      cublasLt)

  endif()

endif()

message(STATUS "Configuring cuBLAS ... done.")
