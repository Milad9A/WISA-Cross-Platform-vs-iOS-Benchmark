//
//  ContentView.swift
//  iOSBenchmark
//
//  Navigation hub for selecting benchmark tests
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var startupMetrics: StartupMetrics
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Card with Startup Time
                    headerCard
                    
                    // Test Selection
                    Text("Select Benchmark Test")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // CPU Test Card
                    NavigationLink(destination: CPUTestView()) {
                        BenchmarkCard(
                            icon: "cpu",
                            title: "CPU Efficiency Test",
                            subtitle: "Sieve of Eratosthenes (1M primes)",
                            description: "Measures single-thread CPU performance by calculating primes on the main UI thread.",
                            color: .orange
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // GPU/Memory/FPS Test Card
                    NavigationLink(destination: GPUTestView()) {
                        BenchmarkCard(
                            icon: "list.bullet.rectangle",
                            title: "GPU/Memory/FPS Test",
                            subtitle: "1000 items • 30s auto-scroll • Battery",
                            description: "Stresses GPU rasterizer with complex list items. Measures FPS, memory, and battery drain.",
                            color: .purple
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer(minLength: 40)
                    
                    // Footer
                    Text("WISA Course - Scientific Framework Comparison")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("iOS Benchmark")
            .onAppear {
                // Record first frame when the view appears
                DispatchQueue.main.async {
                    startupMetrics.recordFirstFrame()
                }
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "speedometer")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Performance Benchmark Suite")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Native iOS (SwiftUI)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Startup Time Display
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.green)
                
                if startupMetrics.isFirstFrameRendered {
                    Text("Startup Time: \(String(format: "%.2f", startupMetrics.timeToInteractive / 1000)) ms")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                } else {
                    Text("Measuring startup...")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Benchmark Card Component

struct BenchmarkCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
        .environmentObject(StartupMetrics.shared)
}
