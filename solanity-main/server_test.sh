#!/bin/bash
# Server Testing Script for Solanity Vanity Address Generator
# Automatically detects GPU capabilities and builds accordingly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  Solanity Server Testing Script${NC}"
    echo -e "${BLUE}======================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check system requirements
check_system() {
    print_status "Checking system requirements..."
    
    # Check for CUDA
    if ! command -v nvcc &> /dev/null; then
        print_error "NVCC not found in PATH. Please install CUDA toolkit."
        exit 1
    fi
    
    CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/')
    print_status "Found CUDA version: $CUDA_VERSION"
    
    # Check for nvidia-smi
    if ! command -v nvidia-smi &> /dev/null; then
        print_warning "nvidia-smi not found. Cannot detect GPU details."
        return 0
    fi
    
    # Display GPU information
    print_status "Detected GPUs:"
    nvidia-smi --query-gpu=index,name,compute_cap,memory.total --format=csv,noheader,nounits | while IFS=',' read -r index name compute_cap memory; do
        echo "  GPU $index: $name (CC: $compute_cap, Memory: ${memory}MB)"
    done
}

# Auto-detect optimal GPU architectures
detect_gpu_architectures() {
    print_status "Detecting optimal GPU architectures..."
    
    if ! command -v nvidia-smi &> /dev/null; then
        print_warning "Cannot detect GPUs, using safe defaults"
        export GPU_ARCHS="sm_60,sm_70,sm_75,sm_80"
        export GPU_PTX_ARCH="compute_60"
        return 0
    fi
    
    # Get compute capabilities of installed GPUs
    COMPUTE_CAPS=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader,nounits | sort -u)
    
    GPU_ARCH_LIST=""
    PTX_ARCH="compute_60"  # Safe default
    
    for cap in $COMPUTE_CAPS; do
        # Convert compute capability to SM architecture
        case $cap in
            6.0) GPU_ARCH_LIST="$GPU_ARCH_LIST,sm_60" ;;
            6.1) GPU_ARCH_LIST="$GPU_ARCH_LIST,sm_61" ;;
            7.0) GPU_ARCH_LIST="$GPU_ARCH_LIST,sm_70"; PTX_ARCH="compute_70" ;;
            7.5) GPU_ARCH_LIST="$GPU_ARCH_LIST,sm_75"; PTX_ARCH="compute_70" ;;
            8.0) GPU_ARCH_LIST="$GPU_ARCH_LIST,sm_80"; PTX_ARCH="compute_80" ;;
            8.6) GPU_ARCH_LIST="$GPU_ARCH_LIST,sm_86"; PTX_ARCH="compute_80" ;;
            8.9) GPU_ARCH_LIST="$GPU_ARCH_LIST,sm_89"; PTX_ARCH="compute_80" ;;
            9.0) GPU_ARCH_LIST="$GPU_ARCH_LIST,sm_90"; PTX_ARCH="compute_90" ;;
            *) print_warning "Unknown compute capability: $cap" ;;
        esac
    done
    
    # Remove leading comma
    GPU_ARCH_LIST=$(echo $GPU_ARCH_LIST | sed 's/^,//')
    
    if [ -z "$GPU_ARCH_LIST" ]; then
        print_warning "No supported GPUs detected, using defaults"
        GPU_ARCH_LIST="sm_60,sm_70,sm_75,sm_80"
    fi
    
    export GPU_ARCHS="$GPU_ARCH_LIST"
    export GPU_PTX_ARCH="$PTX_ARCH"
    
    print_status "Selected GPU architectures: $GPU_ARCHS"
    print_status "Selected PTX architecture: $GPU_PTX_ARCH"
}

# Update build configuration
update_build_config() {
    print_status "Updating build configuration..."
    
    # Create a temporary gpu-common.mk with detected architectures
    cat > src/gpu-common.mk << EOF
NVCC:=nvcc
# Auto-detected GPU architectures for this system
GPU_PTX_ARCH:=$GPU_PTX_ARCH
GPU_ARCHS?=$GPU_ARCHS
GPU_CFLAGS:=--gpu-code=\$(GPU_ARCHS),\$(GPU_PTX_ARCH) --gpu-architecture=\$(GPU_PTX_ARCH)
CFLAGS_release:=--ptxas-options=-v \$(GPU_CFLAGS) -O3 -Xcompiler "-Wall -Werror -fPIC -Wno-strict-aliasing"
CFLAGS_debug:=\$(CFLAGS_release) -g
CFLAGS:=\$(CFLAGS_\$V)
EOF
    
    print_status "Build configuration updated"
}

# Clean and build
build_project() {
    print_status "Building project..."
    
    # Clean previous builds
    make clean > /dev/null 2>&1 || true
    
    # Set CUDA path
    export PATH=/usr/local/cuda/bin:$PATH
    
    # Build with parallel jobs
    if make -j$(nproc) 2>&1; then
        print_status "Build completed successfully!"
    else
        print_error "Build failed!"
        return 1
    fi
}

# Run basic tests
run_tests() {
    print_status "Running basic tests..."
    
    if [ ! -f "src/release/cuda_ed25519_vanity" ]; then
        print_error "Main executable not found!"
        return 1
    fi
    
    # Test GPU initialization
    print_status "Testing GPU initialization..."
    cd src/release
    
    # Run for a very short time (1 second) to test functionality
    timeout 5s env LD_LIBRARY_PATH=. ./cuda_ed25519_vanity || {
        if [ $? -eq 124 ]; then
            print_status "GPU initialization test passed (timed out as expected)"
        else
            print_error "GPU initialization test failed"
            cd ../..
            return 1
        fi
    }
    
    cd ../..
    print_status "Basic tests completed successfully!"
}

# Performance benchmark
run_benchmark() {
    print_status "Running performance benchmark..."
    
    cd src/release
    
    print_status "Starting 30-second benchmark..."
    timeout 30s env LD_LIBRARY_PATH=. ./cuda_ed25519_vanity | tee benchmark.log || true
    
    # Extract performance data
    if [ -f benchmark.log ]; then
        LAST_PERFORMANCE=$(grep "cps" benchmark.log | tail -1 | grep -o '[0-9.]*cps' || echo "N/A")
        TOTAL_ATTEMPTS=$(grep "Total Attempts" benchmark.log | tail -1 | grep -o 'Total Attempts [0-9]*' | grep -o '[0-9]*' || echo "N/A")
        
        print_status "Performance Results:"
        print_status "  Last reported speed: $LAST_PERFORMANCE"
        print_status "  Total attempts: $TOTAL_ATTEMPTS"
        
        rm -f benchmark.log
    fi
    
    cd ../..
}

# Create test configuration
create_test_config() {
    print_status "Creating test configuration..."
    
    # Backup original config
    cp src/config.h src/config.h.backup
    
    # Create test config with easy-to-find patterns
    cat > src/config.h << 'EOF'
#ifndef VANITY_CONFIG
#define VANITY_CONFIG

// Test configuration - short run for server testing
static int const MAX_ITERATIONS = 10;
static int const STOP_AFTER_KEYS_FOUND = 1;

// Optimized for modern GPUs - more threads can handle larger batches
__device__ const int ATTEMPTS_PER_EXECUTION = 100000;

// Support more patterns for better search flexibility
__device__ const int MAX_PATTERNS = 50;

// Test patterns - easier to find for testing
__device__ static char const *prefixes[] = {
    "1",    // Very common - should find quickly
    "A",    // Common start
    "B",
};

#endif
EOF
    
    print_status "Test configuration created"
}

# Restore original configuration
restore_config() {
    if [ -f src/config.h.backup ]; then
        mv src/config.h.backup src/config.h
        print_status "Original configuration restored"
    fi
}

# Main execution
main() {
    print_header
    
    # Parse command line arguments
    SKIP_BENCHMARK=false
    QUICK_TEST=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                QUICK_TEST=true
                shift
                ;;
            --no-benchmark)
                SKIP_BENCHMARK=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --quick        Run quick test with easy patterns"
                echo "  --no-benchmark Skip performance benchmark"
                echo "  --help         Show this help"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # System checks
    check_system
    
    # GPU detection
    detect_gpu_architectures
    
    # Update build configuration
    update_build_config
    
    # Quick test setup
    if [ "$QUICK_TEST" = true ]; then
        create_test_config
    fi
    
    # Build
    if ! build_project; then
        restore_config
        exit 1
    fi
    
    # Test
    if ! run_tests; then
        restore_config
        exit 1
    fi
    
    # Benchmark
    if [ "$SKIP_BENCHMARK" = false ]; then
        run_benchmark
    fi
    
    # Cleanup
    restore_config
    
    print_status "Server testing completed successfully!"
    print_status ""
    print_status "To run the vanity generator:"
    print_status "  cd src/release"
    print_status "  LD_LIBRARY_PATH=. ./cuda_ed25519_vanity"
}

# Trap to ensure cleanup
trap restore_config EXIT

main "$@"