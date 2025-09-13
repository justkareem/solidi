NVCC:=nvcc
# Updated for modern GPUs - use compute_60 for broader compatibility
GPU_PTX_ARCH:=compute_60
# Modern GPU support: Pascal (sm_60,61), Turing (sm_75), Ampere (sm_80,86), Ada Lovelace (sm_89), Hopper (sm_90)
GPU_ARCHS?=sm_60,sm_61,sm_70,sm_75,sm_80,sm_86,sm_89,sm_90
GPU_CFLAGS:=--gpu-code=$(GPU_ARCHS),$(GPU_PTX_ARCH) --gpu-architecture=$(GPU_PTX_ARCH)
CFLAGS_release:=--ptxas-options=-v $(GPU_CFLAGS) -O3 -Xcompiler "-Wall -Werror -fPIC -Wno-strict-aliasing"
CFLAGS_debug:=$(CFLAGS_release) -g
CFLAGS:=$(CFLAGS_$V)
