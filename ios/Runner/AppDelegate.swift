import UIKit
import Flutter
import AVFoundation
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {

    private var pendingPermissionResult: FlutterResult?
    private var locationManager: CLLocationManager?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let permissionChannel = FlutterMethodChannel(
            name: "io.pslab/permissions",
            binaryMessenger: controller.binaryMessenger
        )

        permissionChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let args = call.arguments as? [String: Any],
                  let permission = args["permission"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing permission argument", details: nil))
                return
            }

            if call.method == "checkStatus" {
                self?.handleCheckStatus(permission: permission, result: result)
            } else if call.method == "request" {
                self?.handleRequest(permission: permission, result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func handleCheckStatus(permission: String, result: @escaping FlutterResult) {
        if permission == "microphone" {
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                result("granted")
            case .denied, .restricted:
                result("permanentlyDenied")
            case .notDetermined:
                result("denied")
            @unknown default:
                result("denied")
            }
        } else if permission == "location" {
            let status: CLAuthorizationStatus
            if #available(iOS 14.0, *) {
                status = locationManager?.authorizationStatus ?? CLLocationManager.authorizationStatus()
            } else {
                status = CLLocationManager.authorizationStatus()
            }

            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                result("granted")
            case .denied, .restricted:
                result("permanentlyDenied")
            case .notDetermined:
                result("denied")
            @unknown default:
                result("denied")
            }
        } else {
            result(FlutterError(code: "UNKNOWN_PERMISSION", message: "Unknown permission type", details: nil))
        }
    }

    private func handleRequest(permission: String, result: @escaping FlutterResult) {
        if permission == "microphone" {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    result(granted ? "granted" : "permanentlyDenied")
                }
            }
        } else if permission == "location" {
            let status: CLAuthorizationStatus
            if #available(iOS 14.0, *) {
                status = self.locationManager?.authorizationStatus ?? CLLocationManager.authorizationStatus()
            } else {
                status = CLLocationManager.authorizationStatus()
            }

            if status == .authorizedWhenInUse || status == .authorizedAlways {
                result("granted")
                return
            } else if status == .denied || status == .restricted {
                result("permanentlyDenied")
                return
            }

            self.pendingPermissionResult = result
            if self.locationManager == nil {
                self.locationManager = CLLocationManager()
                self.locationManager?.delegate = self
            }
            self.locationManager?.requestWhenInUseAuthorization()
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard let result = pendingPermissionResult else { return }

        if status != .notDetermined {
            let isGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
            result(isGranted ? "granted" : "permanentlyDenied")
            pendingPermissionResult = nil
        }
    }
}