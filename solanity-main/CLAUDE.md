# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a modernized CUDA-based Solana vanity address generator that searches for addresses with specific prefixes using GPU acceleration. Originally forked from ChorusOne/solanity, it has been updated with:
- Modern CUDA architecture support (RTX 40xx, A100, H100)
- Optimized kernels with cooperative groups
- CMake build system alongside legacy Makefiles
- Enhanced performance for current GPU generations

## Build System

The project now supports dual build systems:
- **Modern**: CMake with auto-detection of GPU architectures
- **Legacy**: Makefile system for backward compatibility

## Common Development Commands

### Modern Build (Recommended)
```bash
# Automated build with GPU detection
./build.sh

# Debug build
./build.sh --debug

# Build without running tests
./build.sh --no-tests
```

### CMake Build (Manual)
```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES="80;86;89;90"
make -j$(nproc)
cd ..
```

### Legacy Makefile Build
```bash
# Set CUDA path (required)
export PATH=/usr/local/cuda/bin:$PATH

# Build release version
make -j$(nproc)

# Build debug version  
make V=debug -j$(nproc)

# Clean build artifacts
make clean
```

### Running
```bash
# CMake build
cd build && ./cuda_ed25519_vanity

# Legacy build
LD_LIBRARY_PATH=./src/release ./src/release/cuda_ed25519_vanity

# Or use the convenience script
./run
```

### Testing
```bash
# CMake build
cd build && ./cuda_chacha_test 64

# Legacy build
make test
```

## Architecture

### Core Components
- **CUDA Cryptography**: `src/cuda-crypt/` - AES and ChaCha20 implementations
- **Ed25519 CUDA**: `src/cuda-ecc-ed25519/` - Elliptic curve operations and vanity search logic
- **Optimized Kernels**: `src/cuda-ecc-ed25519/vanity_optimized.cu` - Modern CUDA implementation
- **SGX Implementation**: `src/sgx-ecc-ed25519/` and `src/sgx/` - Intel SGX trusted execution environment support
- **Proof-of-History**: `src/cuda-poh-verify/` - Solana PoH verification

### Key Files
- `src/config.h`: Configuration for search patterns and execution limits (optimized for modern GPUs)
- `src/cuda-ecc-ed25519/vanity.cu`: Original vanity search implementation
- `src/cuda-ecc-ed25519/vanity_optimized.cu`: Modern optimized implementation with cooperative groups
- `src/gpu-common.mk`: CUDA compilation settings with modern GPU architectures
- `CMakeLists.txt`: Modern CMake build configuration
- `cmake/FindCUDA.cmake`: CUDA detection and configuration

### Build Artifacts
- `build/cuda_ed25519_vanity` or `src/release/cuda_ed25519_vanity`: Main executable
- `build/libcuda-crypt.so` or `src/release/libcuda-crypt.so`: Shared library

## Configuration

Edit `src/config.h` to modify:
- Search prefixes in the `prefixes[]` array (now supports up to 50 patterns)
- `MAX_ITERATIONS`: Maximum search iterations (increased to 1M)
- `STOP_AFTER_KEYS_FOUND`: Stop after finding N matches
- `ATTEMPTS_PER_EXECUTION`: GPU thread execution batch size (increased to 500K for modern GPUs)

## CUDA Requirements

### Modern Setup (Recommended)
- CUDA toolkit 11.8+ (supports up to 12.4)
- GPU architectures: Pascal (sm_60,61), Turing (sm_75), Ampere (sm_80,86), Ada Lovelace (sm_89), Hopper (sm_90)
- Compute capability 6.0+ required
- Supports RTX 30xx/40xx, Tesla V100, A100, H100

### Legacy Support
- CUDA toolkit 10.0+ (minimum)
- GPU architectures: sm_37, sm_50, sm_61, sm_70
- Compute capability 3.7+ required

## Performance Optimizations

The modern version includes:
- Cooperative groups for improved warp efficiency
- Vectorized memory operations (uint4)
- Reduced branching in critical paths
- Optimized Base58 encoding
- Improved random number generation
- Better memory access patterns

## Security Notes

This is a vanity address generator for demonstration and educational purposes. The disclaimer states generated keys should not be used for real transactions without proper security auditing. The modern version uses OS entropy for better randomness initialization.