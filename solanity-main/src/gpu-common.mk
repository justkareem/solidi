NVCC:=nvcc
# RTX 5070 + CUDA 12.8 + Xeon E5-2686 v4 optimized configuration
GPU_PTX_ARCH:=compute_89
# Target RTX 5070 specifically (Ada Lovelace sm_89)
GPU_ARCHS?=sm_89
GPU_CFLAGS:=--gpu-code=$(GPU_ARCHS),$(GPU_PTX_ARCH) --gpu-architecture=$(GPU_PTX_ARCH)
# CUDA 12.8 + high bandwidth optimizations
CFLAGS_release:=--ptxas-options=-v,--opt-level=3 $(GPU_CFLAGS) -O3 --use_fast_math --ftz=true --prec-div=false --prec-sqrt=false --fmad=true --maxrregcount=255 -Xcompiler "-Wall -Werror -fPIC -Wno-strict-aliasing -O3 -march=broadwell -mtune=broadwell -mavx2 -mfma"
CFLAGS_debug:=$(CFLAGS_release) -g
CFLAGS:=$(CFLAGS_$V)
