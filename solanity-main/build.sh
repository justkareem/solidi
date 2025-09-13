#!/bin/bash
# Modern build script for Solanity vanity address generator
# Supports CUDA 11.8+ with auto-detection of GPU architectures

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for CUDA installation
check_cuda() {
    if ! command -v nvcc &> /dev/null; then
        print_error "NVCC not found in PATH. Please install CUDA toolkit."
        exit 1
    fi
    
    CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/')
    print_status "Found CUDA version: $CUDA_VERSION"
    
    # Check minimum version (11.8)
    if (( $(echo "$CUDA_VERSION < 11.8" | bc -l) )); then
        print_warning "CUDA version $CUDA_VERSION is older than recommended 11.8+"
    fi
}

# Detect GPU architectures
detect_gpu_archs() {
    print_status "Detecting available GPU architectures..."
    
    # Try to detect installed GPUs
    if command -v nvidia-smi &> /dev/null; then
        GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits)
        print_status "Detected GPUs:"
        echo "$GPU_INFO" | sed 's/^/  /'
        
        # Set architectures based on detected GPUs
        export CMAKE_CUDA_ARCHITECTURES="60;61;70;75;80;86;89;90"
    else
        print_warning "nvidia-smi not found, using default architectures"
        export CMAKE_CUDA_ARCHITECTURES="70;75;80;86"
    fi
}

# Build using CMake (preferred) or Make (fallback)
build_project() {
    print_status "Starting build process..."
    
    BUILD_TYPE=${1:-Release}
    
    if [ -f "CMakeLists.txt" ]; then
        print_status "Using CMake build system"
        
        mkdir -p build
        cd build
        
        cmake .. \
            -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
            -DCMAKE_CUDA_ARCHITECTURES="$CMAKE_CUDA_ARCHITECTURES" \
            -DBUILD_TESTS=ON
        
        make -j$(nproc)
        cd ..
        
        print_status "Build complete! Executables in build/"
        
    else
        print_status "Using legacy Makefile build system"
        export PATH=/usr/local/cuda/bin:$PATH
        
        if [ "$BUILD_TYPE" = "Debug" ]; then
            make V=debug -j$(nproc)
        else
            make -j$(nproc)
        fi
        
        print_status "Build complete! Executables in src/release/"
    fi
}

# Run tests if available
run_tests() {
    print_status "Running tests..."
    
    if [ -f "build/cuda_chacha_test" ]; then
        cd build
        ./cuda_chacha_test 64
        ./cuda_ed25519_verify 64 1 1 1 1 0
        cd ..
        print_status "Tests passed!"
    elif [ -f "src/release/cuda_chacha_test" ]; then
        cd src/release
        LD_LIBRARY_PATH=. ./cuda_chacha_test 64
        LD_LIBRARY_PATH=. ./cuda_ed25519_verify 64 1 1 1 1 0
        cd ../..
        print_status "Tests passed!"
    else
        print_warning "Test executables not found, skipping tests"
    fi
}

# Main execution
main() {
    print_status "Solanity Modern Build Script"
    print_status "============================="
    
    check_cuda
    detect_gpu_archs
    
    BUILD_TYPE="Release"
    RUN_TESTS=true
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                BUILD_TYPE="Debug"
                shift
                ;;
            --no-tests)
                RUN_TESTS=false
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --debug      Build debug version"
                echo "  --no-tests   Skip running tests"
                echo "  --help       Show this help"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    build_project $BUILD_TYPE
    
    if [ "$RUN_TESTS" = true ]; then
        run_tests
    fi
    
    print_status "Build completed successfully!"
    print_status "To run the vanity address generator:"
    if [ -f "build/cuda_ed25519_vanity" ]; then
        print_status "  cd build && ./cuda_ed25519_vanity"
    else
        print_status "  LD_LIBRARY_PATH=./src/release ./src/release/cuda_ed25519_vanity"
    fi
}

main "$@"