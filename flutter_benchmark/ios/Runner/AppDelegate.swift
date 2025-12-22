import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    /// Store the app launch time - captured in didFinishLaunchingWithOptions
    private var appLaunchTime: CFAbsoluteTime = 0

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Capture launch time immediately
        appLaunchTime = CFAbsoluteTimeGetCurrent()

        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true

        // Set up battery method channel
        let controller = window?.rootViewController as! FlutterViewController
        let batteryChannel = FlutterMethodChannel(
            name: "flutter_benchmark/battery",
            binaryMessenger: controller.binaryMessenger
        )

        batteryChannel.setMethodCallHandler {
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "getBatteryLevel" {
                self?.receiveBatteryLevel(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        // Set up startup time method channel
        let startupChannel = FlutterMethodChannel(
            name: "flutter_benchmark/startup",
            binaryMessenger: controller.binaryMessenger
        )

        startupChannel.setMethodCallHandler {
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "getElapsedStartupTime" {
                guard let self = self else {
                    result(0)
                    return
                }
                // Return elapsed time from app launch to now in microseconds
                let now = CFAbsoluteTimeGetCurrent()
                let elapsed = now - self.appLaunchTime
                let elapsedMicroseconds = Int(elapsed * 1_000_000)
                result(elapsedMicroseconds)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func receiveBatteryLevel(result: FlutterResult) {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        let batteryLevel = device.batteryLevel
        if batteryLevel < 0 {
            result(
                FlutterError(
                    code: "UNAVAILABLE",
                    message: "Battery level not available (simulator or disabled)",
                    details: nil
                ))
        } else {
            result(Int(batteryLevel * 100))
        }
    }
}
