NVCC:=nvcc
# RTX 5070 specific configuration - Ada Lovelace architecture
GPU_PTX_ARCH:=compute_89
# Target RTX 5070 specifically (Ada Lovelace sm_89)
GPU_ARCHS?=sm_89
GPU_CFLAGS:=--gpu-code=$(GPU_ARCHS),$(GPU_PTX_ARCH) --gpu-architecture=$(GPU_PTX_ARCH)
CFLAGS_release:=--ptxas-options=-v $(GPU_CFLAGS) -O3 -Xcompiler "-Wall -Werror -fPIC -Wno-strict-aliasing" --expt-relaxed-constexpr
CFLAGS_debug:=$(CFLAGS_release) -g
CFLAGS:=$(CFLAGS_$V)
