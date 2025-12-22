//
//  CPUTestView.swift
//  iOSBenchmark
//
//  CPU Efficiency Test - Sieve of Eratosthenes
//  Runs on the MAIN THREAD to test UI blocking behavior
//

import SwiftUI

// MARK: - Test Result Model

struct CPUTestResult: Identifiable {
    let id = UUID()
    let executionTimeUs: Int
    let primeCount: Int
    let timestamp: Date
}

// MARK: - CPU Test View

struct CPUTestView: View {
    @State private var isRunning = false
    @State private var executionTimeUs: Int?
    @State private var primeCount: Int?
    @State private var status = "Ready to run test"
    @State private var testHistory: [CPUTestResult] = []
    
    private let expectedPrimeCount = 78498
    private let limit = 1_000_000
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Info Card
                infoCard
                
                // Run Test Button
                runTestButton
                
                // Status
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(isRunning ? .orange : .secondary)
                    .italic()
                
                // Results
                if let time = executionTimeUs, let count = primeCount {
                    resultsCard(executionTime: time, primeCount: count)
                }
                
                // Test History
                if !testHistory.isEmpty {
                    historySection
                }
                
                // Statistics
                if testHistory.count >= 2 {
                    statisticsCard
                }
            }
            .padding()
        }
        .navigationTitle("CPU Efficiency Test")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !testHistory.isEmpty {
                Button("Clear") {
                    testHistory.removeAll()
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                Text("Test Configuration")
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            InfoRow(label: "Algorithm", value: "Sieve of Eratosthenes")
            InfoRow(label: "Range", value: "2 to 1,000,000")
            InfoRow(label: "Thread", value: "Main UI Thread (blocking)")
            InfoRow(label: "Expected Result", value: "78,498 primes")
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var runTestButton: some View {
        Button(action: runTest) {
            HStack {
                if isRunning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Running...")
                } else {
                    Image(systemName: "play.fill")
                    Text("Run CPU Test")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isRunning ? Color.gray : Color.orange)
            .cornerRadius(12)
        }
        .disabled(isRunning)
    }
    
    private func resultsCard(executionTime: Int, primeCount: Int) -> some View {
        VStack(spacing: 16) {
            Text("Latest Result")
                .font(.headline)
            
            // Primary Metric - Execution Time
            VStack(spacing: 8) {
                Text("Execution Time")
                    .font(.subheadline)
                    .foregroundColor(.green)
                
                Text(String(format: "%.2f ms", Double(executionTime) / 1000))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.green)
                
                Text("\(executionTime) μs")
                    .font(.caption)
                    .foregroundColor(.green.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            // Secondary Metrics
            HStack(spacing: 12) {
                // Prime Count
                VStack(spacing: 4) {
                    Text("Primes Found")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("\(primeCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // Validation
                VStack(spacing: 4) {
                    Text("Validation")
                        .font(.caption)
                        .foregroundColor(primeCount == expectedPrimeCount ? .green : .red)
                    Image(systemName: primeCount == expectedPrimeCount ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(primeCount == expectedPrimeCount ? .green : .red)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background((primeCount == expectedPrimeCount ? Color.green : Color.red).opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test History")
                .font(.headline)
            
            ForEach(Array(testHistory.enumerated()), id: \.element.id) { index, result in
                HStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        )
                    
                    VStack(alignment: .leading) {
                        Text(String(format: "%.2f ms", Double(result.executionTimeUs) / 1000))
                            .fontWeight(.semibold)
                        Text("\(result.primeCount) primes • \(formatTime(result.timestamp))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: result.primeCount == expectedPrimeCount ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.primeCount == expectedPrimeCount ? .green : .red)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
    
    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            let times = testHistory.map { $0.executionTimeUs }
            let avg = Double(times.reduce(0, +)) / Double(times.count)
            let minTime = times.min() ?? 0
            let maxTime = times.max() ?? 0
            let stdDev = calculateStdDev(times)
            
            HStack {
                StatRow(label: "Average", value: String(format: "%.2f ms", avg / 1000))
                StatRow(label: "Min", value: String(format: "%.2f ms", Double(minTime) / 1000))
            }
            HStack {
                StatRow(label: "Max", value: String(format: "%.2f ms", Double(maxTime) / 1000))
                StatRow(label: "Std Dev", value: String(format: "%.2f ms", stdDev / 1000))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Sieve of Eratosthenes Algorithm
    
    /// Sieve of Eratosthenes implementation
    /// Calculates all prime numbers up to the given limit
    /// Returns the count of primes found
    private func sieveOfEratosthenes(_ limit: Int) -> Int {
        // Create a boolean array and initialize all entries as true
        var isPrime = [Bool](repeating: true, count: limit + 1)
        isPrime[0] = false
        isPrime[1] = false
        
        // Start with the smallest prime number, 2
        var p = 2
        while p * p <= limit {
            // If isPrime[p] is not changed, then it is a prime
            if isPrime[p] {
                // Update all multiples of p as not prime
                var i = p * p
                while i <= limit {
                    isPrime[i] = false
                    i += p
                }
            }
            p += 1
        }
        
        // Count all prime numbers
        var count = 0
        for i in 2...limit {
            if isPrime[i] {
                count += 1
            }
        }
        
        return count
    }
    
    // MARK: - Test Execution
    
    private func runTest() {
        isRunning = true
        status = "Running Sieve of Eratosthenes..."
        executionTimeUs = nil
        primeCount = nil
        
        // Small delay to allow UI to update before blocking
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Record start time with microsecond precision
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Run the algorithm on the MAIN THREAD (intentionally blocking)
            let count = sieveOfEratosthenes(limit)
            
            // Calculate execution time
            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = Int((endTime - startTime) * 1_000_000) // Convert to microseconds
            
            // Log to console
            print("═══════════════════════════════════════════════")
            print("iOS BENCHMARK - CPU TEST RESULTS")
            print("═══════════════════════════════════════════════")
            print("Algorithm: Sieve of Eratosthenes")
            print("Limit: \(limit)")
            print("Primes found: \(count)")
            print("Execution time: \(executionTime) μs")
            print("Execution time: \(String(format: "%.2f", Double(executionTime) / 1000)) ms")
            print("═══════════════════════════════════════════════")
            
            // Update state
            isRunning = false
            executionTimeUs = executionTime
            primeCount = count
            status = "Test completed"
            
            // Add to history
            let result = CPUTestResult(
                executionTimeUs: executionTime,
                primeCount: count,
                timestamp: Date()
            )
            testHistory.insert(result, at: 0)
            
            // Keep only last 10 results
            if testHistory.count > 10 {
                testHistory = Array(testHistory.prefix(10))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func calculateStdDev(_ values: [Int]) -> Double {
        guard values.count >= 2 else { return 0 }
        let avg = Double(values.reduce(0, +)) / Double(values.count)
        let sumSquares = values.reduce(0.0) { sum, value in
            let diff = Double(value) - avg
            return sum + (diff * diff)
        }
        return sqrt(sumSquares / Double(values.count))
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        CPUTestView()
    }
}
