#!/bin/bash
# Server-optimized launch script for 4x RTX 5070 + Xeon E5-2686 v4

# Set CPU governor to performance mode
echo "Setting CPU to performance mode for Xeon E5-2686 v4..."
sudo cpufreq-set -g performance 2>/dev/null || echo "CPU governor setting skipped"

# Set CPU affinity to avoid NUMA issues
export OMP_NUM_THREADS=8
export CUDA_VISIBLE_DEVICES=0,1,2,3

# Memory optimizations for 193GB RAM
export CUDA_CACHE_DISABLE=0
export CUDA_FORCE_PTX_JIT=1

# GPU power and clocks optimization
echo "Optimizing GPU power states..."
nvidia-smi -pm 1 2>/dev/null || echo "Persistence mode setting skipped"
nvidia-smi -ac 2800,1785 2>/dev/null || echo "Memory/GPU clock setting skipped"

# Set process priority
echo "Launching with server optimizations..."
echo "4x RTX 5070 @ 121.5 TFLOPS each = 486 TFLOPS total"
echo "Memory bandwidth: 552GB/s per GPU = 2208GB/s total"

cd src/release
nice -n -19 LD_LIBRARY_PATH=. numactl --cpunodebind=0 --membind=0 ./cuda_ed25519_vanity