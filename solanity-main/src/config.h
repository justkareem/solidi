#ifndef VANITY_CONFIG
#define VANITY_CONFIG

// Server-grade optimization: 4x RTX 5070 @ 121.5 TFLOPS each + 552GB/s bandwidth
static int const MAX_ITERATIONS = 1000000;
static int const STOP_AFTER_KEYS_FOUND = 100;

// High performance but realistic workload for RTX 5070
__device__ const int ATTEMPTS_PER_EXECUTION = 1000000;

// Support more patterns for better search flexibility
__device__ const int MAX_PATTERNS = 50;

// exact matches at the beginning of the address, letter ? is wildcard

__device__ static char const *prefixes[] = {
	"AAAAA",
	"BBBBB",
};


#endif
