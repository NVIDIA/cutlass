
message(STATUS "Configuring cublas ...")

if((DEFINED CUTLASS_ENABLE_CUBLAS AND NOT CUTLASS_ENABLE_CUBLAS) OR
   (DEFINED CUBLAS_ENABLED AND NOT CUBLAS_ENABLED))
  
  # Don't add cuBLAS if it's defined and false, assume it's not found.

  set(CUBLAS_FOUND OFF)
  message(STATUS "cuBLAS Disabled.")

elseif(NOT TARGET cublas)
 
  find_path(
    _CUBLAS_INCLUDE_DIR
    NAMES cublas.h
    HINTS
      ${CUBLAS_INCLUDE_PATH}
      ENV CUBLAS_INCLUDE_PATH
      ${CUBLAS_PATH}
      ENV CUBLAS_PATH
      ${CUDA_TOOLKIT_ROOT_DIR}
    PATH_SUFFIXES
      include
    )

  find_library(
    _CUBLAS_LIBRARY
    NAMES cublas
    HINTS
      ${CUBLAS_LIBRARY_PATH}
      ENV CUBLAS_LIBRARY_PATH
      ${_CUBLAS_INCLUDE_DIR}/..
      ${CUBLAS_PATH}
      ENV CUBLAS_PATH
      ${CUDA_TOOLKIT_ROOT_DIR}
    PATH_SUFFIXES
      lib64
      lib/x64
      lib
    )

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
    add_library(cublas STATIC IMPORTED GLOBAL)
  else()
    add_library(cublas SHARED IMPORTED GLOBAL)
  endif()

  add_library(nvidia::cublas ALIAS cublas)

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
    _CUBLASLT_LIBRARY
    NAMES cublasLt
    HINTS
      ${CUBLAS_LIBRARY_PATH}
      ENV CUBLAS_LIBRARY_PATH
      ${_CUBLAS_INCLUDE_DIR}/..
      ${CUBLAS_PATH}
      ENV CUBLAS_PATH
      ${CUDA_TOOLKIT_ROOT_DIR}
    PATH_SUFFIXES
      lib64
      lib/x64
      lib
    )

  if(_CUBLASLT_LIBRARY AND NOT TARGET cublasLt)

    if(WIN32)
      add_library(cublasLt STATIC IMPORTED GLOBAL)
    else()
      add_library(cublasLt SHARED IMPORTED GLOBAL)
    endif()
    
    set_property(
      TARGET cublasLt
      PROPERTY IMPORTED_LOCATION
      ${_CUBLASLT_LIBRARY})
  
    add_library(nvidia::cublasLt ALIAS cublasLt)

    target_link_libraries(cublas INTERFACE cublasLt)

  endif()

endif()

message(STATUS "Configuring cuBLAS ... done.")
