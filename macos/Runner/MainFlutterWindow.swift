import Cocoa
import FlutterMacOS
import AVFoundation
import CoreLocation

class MainFlutterWindow: NSWindow, CLLocationManagerDelegate {
    private var pendingPermissionResult: FlutterResult?
    private var locationManager: CLLocationManager?

    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        let permissionChannel = FlutterMethodChannel(
            name: "io.pslab/permissions",
            binaryMessenger: flutterViewController.engine.binaryMessenger
        )

        permissionChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
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

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
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
        if #available(macOS 11.0, *) {
            status = locationManager?.authorizationStatus ?? CLLocationManager.authorizationStatus()
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .authorizedAlways, .authorized: result("granted")
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
        if #available(macOS 11.0, *) {
            status = self.locationManager?.authorizationStatus ?? CLLocationManager.authorizationStatus()
        } else {
            status = CLLocationManager.authorizationStatus()
        }


        if status == .authorized || status == .authorizedAlways {
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
        self.locationManager?.requestAlwaysAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard let result = pendingPermissionResult else { return }

        if status != .notDetermined {
            let isGranted = (status == .authorized || status == .authorizedAlways)
            result(isGranted ? "granted" : "permanentlyDenied")
            pendingPermissionResult = nil
        }
    }
}