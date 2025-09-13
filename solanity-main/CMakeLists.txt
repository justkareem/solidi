cmake_minimum_required(VERSION 3.18)
project(solanity LANGUAGES C CXX CUDA)

# Modern C++ and CUDA standards
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# Find CUDA with modern architecture support
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include(FindCUDA)

# Build options
option(BUILD_DEBUG "Build debug version" OFF)
option(BUILD_TESTS "Build tests" ON)

# Set build type
if(BUILD_DEBUG)
    set(CMAKE_BUILD_TYPE Debug)
else()
    set(CMAKE_BUILD_TYPE Release)
endif()

# Include directories
include_directories(src/cuda-headers)
include_directories(src/cuda-sha256)

# CUDA sources
file(GLOB_RECURSE CUDA_SOURCES
    src/cuda-crypt/*.cu
    src/cuda-ecc-ed25519/*.cu
    src/cuda-poh-verify/*.cu
)

# Create shared library
add_library(cuda-crypt SHARED ${CUDA_SOURCES})
target_link_libraries(cuda-crypt CUDA::cudart CUDA::curand)

# Set CUDA architectures
set_target_properties(cuda-crypt PROPERTIES
    CUDA_ARCHITECTURES "${CMAKE_CUDA_ARCHITECTURES}"
    CUDA_SEPARABLE_COMPILATION ON
)

# Main executable
add_executable(cuda_ed25519_vanity src/cuda-ecc-ed25519/vanity.cu)
target_link_libraries(cuda_ed25519_vanity cuda-crypt)

# Tests
if(BUILD_TESTS)
    add_executable(cuda_chacha_test src/cuda-crypt/test.cu)
    target_link_libraries(cuda_chacha_test cuda-crypt)
    
    add_executable(cuda_ed25519_verify src/cuda-ecc-ed25519/main.cu)
    target_link_libraries(cuda_ed25519_verify cuda-crypt)
endif()

# Install rules
install(TARGETS cuda-crypt cuda_ed25519_vanity
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)