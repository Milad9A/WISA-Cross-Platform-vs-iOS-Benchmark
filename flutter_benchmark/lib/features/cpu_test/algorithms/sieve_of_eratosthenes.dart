/// Sieve of Eratosthenes algorithm implementation
///
/// This is a classic algorithm for finding all prime numbers up to a given limit.
/// Used as a CPU-bound benchmark to stress the main UI thread.
class SieveOfEratosthenes {
  /// Calculates all prime numbers up to [limit]
  /// Returns the count of primes found
  ///
  /// For limit = 1,000,000, the expected result is 78,498 primes
  static int countPrimes(int limit) {
    // Create a boolean array "isPrime[0..limit]" and initialize
    // all entries as true. isPrime[i] will be false if i is not prime
    final isPrime = List<bool>.filled(limit + 1, true);

    isPrime[0] = false;
    isPrime[1] = false;

    // Start with the smallest prime number, 2
    for (int p = 2; p * p <= limit; p++) {
      // If isPrime[p] is not changed, then it is a prime
      if (isPrime[p]) {
        // Update all multiples of p as not prime
        for (int i = p * p; i <= limit; i += p) {
          isPrime[i] = false;
        }
      }
    }

    // Count all prime numbers
    int count = 0;
    for (int i = 2; i <= limit; i++) {
      if (isPrime[i]) {
        count++;
      }
    }

    return count;
  }
}
