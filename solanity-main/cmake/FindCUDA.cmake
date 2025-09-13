# Modern CUDA detection for vanity address generator
# Supports CUDA 11.8+ with modern GPU architectures

find_package(CUDAToolkit REQUIRED)

if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    # Auto-detect GPU architectures based on available hardware
    set(CMAKE_CUDA_ARCHITECTURES "60;61;70;75;80;86;89;90")
endif()

# Set CUDA standard
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# Modern CUDA compiler flags
set(CUDA_NVCC_FLAGS
    ${CUDA_NVCC_FLAGS}
    --expt-relaxed-constexpr
    --use_fast_math
    -O3
)

# Enable separate compilation for device linking
set(CMAKE_CUDA_SEPARABLE_COMPILATION ON)

# Architecture-specific optimizations
if(CMAKE_CUDA_ARCHITECTURES MATCHES "80|86|89|90")
    list(APPEND CUDA_NVCC_FLAGS --extended-lambda)
endif()