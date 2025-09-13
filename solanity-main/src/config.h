#ifndef VANITY_CONFIG
#define VANITY_CONFIG

// Optimized for modern GPUs with more compute units
static int const MAX_ITERATIONS = 1000000;
static int const STOP_AFTER_KEYS_FOUND = 100;

// Increased for modern GPUs - more threads can handle larger batches
__device__ const int ATTEMPTS_PER_EXECUTION = 500000;

// Support more patterns for better search flexibility
__device__ const int MAX_PATTERNS = 50;

// exact matches at the beginning of the address, letter ? is wildcard

__device__ static char const *prefixes[] = {
	"AAAAA",
	"BBBBB",
};


#endif
