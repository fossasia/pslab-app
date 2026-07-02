import UIKit
import Flutter
import AVFoundation
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate {

    private var pendingPermissionResult: FlutterResult?
    private var locationManager: CLLocationManager?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
                GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
                let permissionChannel = FlutterMethodChannel(
                            name: "io.pslab/permissions",
                            binaryMessenger: engineBridge.applicationRegistrar.messenger()
                        )

                        permissionChannel.setMethodCallHandler { [weak self] call, result in
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
                        }
               }

    private func handleCheckStatus(permission: String, result: @escaping FlutterResult) {
        if permission == "microphone" {
            checkMicrophoneStatus(result: result)
        } else if permission == "location" {
            checkLocationStatus(result: result)
        } else {
            result(FlutterError(code: "UNKNOWN", message: "Unknown permission", details: nil))
        }
    }

    private func checkMicrophoneStatus(result: @escaping FlutterResult) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: result("granted")
        case .denied, .restricted: result("permanentlyDenied")
        case .notDetermined: result("denied")
        @unknown default: result("denied")
        }
    }

    private func checkLocationStatus(result: @escaping FlutterResult) {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager?.authorizationStatus ?? CLLocationManager.authorizationStatus()
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .authorizedAlways, .authorizedWhenInUse: result("granted")
        case .denied, .restricted: result("permanentlyDenied")
        case .notDetermined: result("denied")
        @unknown default: result("denied")
        }
    }

    private func handleRequest(permission: String, result: @escaping FlutterResult) {
        if permission == "microphone" {
            requestMicrophone(result: result)
        } else if permission == "location" {
            requestLocation(result: result)
        } else {
            result(FlutterError(code: "UNKNOWN", message: "Unknown permission", details: nil))
        }
    }

    private func requestMicrophone(result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                result(granted ? "granted" : "permanentlyDenied")
            }
        }
    }

    private func requestLocation(result: @escaping FlutterResult) {
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

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard let result = pendingPermissionResult else { return }

        if status != .notDetermined {
            let isGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
            result(isGranted ? "granted" : "permanentlyDenied")
            pendingPermissionResult = nil
        }
    }
}
