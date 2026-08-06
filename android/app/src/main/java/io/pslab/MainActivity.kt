package io.pslab

import android.Manifest
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Main activity for PSLab Android application, managing Flutter engine setup,
 * USB communication, ambient temperature sensor monitoring, and OS permissions.
 */
class MainActivity : FlutterActivity(), SensorEventListener {

    /**
     * Constants for channel identifiers, permissions, log tags, and status strings.
     */
    companion object {
        private const val TEMPERATURE_CHANNEL = "io.pslab/temperature"
        private const val TEMPERATURE_STREAM = "io.pslab/temperature_stream"
        private const val PERMISSION_CHANNEL = "io.pslab/permissions"
        private const val USB_CHANNEL = "usb_serial"
        private const val USB_EVENT_STREAM = "io.pslab/usb_events"
        private const val ACTION_USB_PERMISSION = "com.pslab.USB_PERMISSION"
        private const val TAG = "MainActivity"
        private const val PERMISSION_REQ_CODE = 1001

        internal const val STATUS_GRANTED = "granted"
        internal const val STATUS_DENIED = "denied"
        internal const val STATUS_PERMANENTLY_DENIED = "permanentlyDenied"
    }

    internal var sensorManager: SensorManager? = null
    internal var temperatureSensor: Sensor? = null
    internal var temperatureEventSink: EventChannel.EventSink? = null
    internal var pendingPermissionResult: MethodChannel.Result? = null
    internal var usbEventSink: EventChannel.EventSink? = null
    internal var usbHardwareReceiver: BroadcastReceiver? = null
    internal var isListening = false
    internal var currentTemperature = 0.0f

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        sensorManager?.let {
            temperatureSensor = it.getDefaultSensor(Sensor.TYPE_AMBIENT_TEMPERATURE)
        }

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, TEMPERATURE_CHANNEL).setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }

        EventChannel(messenger, TEMPERATURE_STREAM).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                temperatureEventSink = events
                startTemperatureUpdates()
            }

            override fun onCancel(arguments: Any?) {
                temperatureEventSink = null
                stopTemperatureUpdates()
            }
        })

        MethodChannel(messenger, PERMISSION_CHANNEL).setMethodCallHandler { call, result ->
            handlePermissionMethodCall(call, result)
        }

        MethodChannel(messenger, USB_CHANNEL).setMethodCallHandler { call, result ->
            handleUsbMethodCall(call, result)
        }

        EventChannel(messenger, USB_EVENT_STREAM).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                usbEventSink = events
                registerUsbHardwareReceiver()
            }

            override fun onCancel(arguments: Any?) {
                usbEventSink = null
                unregisterUsbHardwareReceiver()
            }
        })
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQ_CODE && pendingPermissionResult != null) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                pendingPermissionResult?.success(STATUS_GRANTED)
            } else {
                if (permissions.isNotEmpty()) {
                    val shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(this, permissions[0])
                    pendingPermissionResult?.success(if (shouldShowRationale) STATUS_DENIED else STATUS_PERMANENTLY_DENIED)
                } else {
                    pendingPermissionResult?.success(STATUS_DENIED)
                }
            }
            pendingPermissionResult = null
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event != null && event.sensor.type == Sensor.TYPE_AMBIENT_TEMPERATURE) {
            val temperature = event.values[0]
            if (isValidTemperature(temperature)) {
                currentTemperature = temperature
                Log.d(TAG, "Temperature updated: $currentTemperature C")
                if (temperatureEventSink != null) {
                    Log.d(TAG, "Sending temperature to Flutter: $currentTemperature")
                    temperatureEventSink?.success(currentTemperature.toDouble())
                }
            } else {
                Log.w(TAG, "Invalid temperature reading: $temperature - ignoring")
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        Log.d(TAG, "Sensor accuracy changed: $accuracy")
    }

    override fun onDestroy() {
        super.onDestroy()
        stopTemperatureUpdates()
        unregisterUsbHardwareReceiver()
    }

    override fun onPause() {
        super.onPause()
        if (isListening && sensorManager != null) {
            sensorManager?.unregisterListener(this)
        }
    }

    override fun onResume() {
        super.onResume()
        if (isListening && temperatureSensor != null && sensorManager != null) {
            sensorManager?.registerListener(this, temperatureSensor, SensorManager.SENSOR_DELAY_NORMAL)
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isTemperatureSensorAvailable" -> result.success(temperatureSensor != null)
            "getCurrentTemperature" -> result.success(currentTemperature.toDouble())
            "startTemperatureUpdates" -> {
                if (startTemperatureUpdates()) {
                    result.success(true)
                } else {
                    result.error("SENSOR_ERROR", "Failed to start temperature updates", null)
                }
            }
            "stopTemperatureUpdates" -> {
                stopTemperatureUpdates()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun handlePermissionMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val permissionArg = call.argument<String>("permission")
        val manifestPermission = getManifestPermission(permissionArg)

        if (manifestPermission == null) {
            result.error("INVALID", "Unknown permission requested", null)
            return
        }

        when (call.method) {
            "checkStatus" -> result.success(getPermissionStatusString(manifestPermission))
            "request" -> {
                if (STATUS_GRANTED == getPermissionStatusString(manifestPermission)) {
                    result.success(STATUS_GRANTED)
                } else {
                    pendingPermissionResult = result
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(manifestPermission),
                        PERMISSION_REQ_CODE
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun handleUsbMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if ("getAndroidFd" == call.method) {
            val vid = call.argument<Number>("vid")
            val pid = call.argument<Number>("pid")

            if (vid == null || pid == null) {
                result.error("INVALID_ARGS", "Missing VID or PID arguments", null)
                return
            }

            getUsbFileDescriptor(vid.toInt(), pid.toInt(), result)
        } else {
            result.notImplemented()
        }
    }
}

private fun MainActivity.registerUsbHardwareReceiver() {
    if (usbHardwareReceiver == null) {
        usbHardwareReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val action = intent?.action
                if (usbEventSink != null &&
                    (UsbManager.ACTION_USB_DEVICE_ATTACHED == action ||
                            UsbManager.ACTION_USB_DEVICE_DETACHED == action)
                ) {
                    usbEventSink?.success(action)
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(usbHardwareReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(usbHardwareReceiver, filter)
        }
    }
}

private fun MainActivity.unregisterUsbHardwareReceiver() {
    usbHardwareReceiver?.let {
        unregisterReceiver(it)
        usbHardwareReceiver = null
    }
}

private fun MainActivity.getUsbFileDescriptor(vid: Int, pid: Int, result: MethodChannel.Result) {
    val usbManager = getSystemService(Context.USB_SERVICE) as? UsbManager
    if (usbManager == null) {
        result.error("USB_SERVICE_UNAVAILABLE", "Android USB service could not be obtained", null)
        return
    }

    val foundDevices = StringBuilder()
    var deviceCount = 0
    var pslabDevice: UsbDevice? = null

    for (device in usbManager.deviceList.values) {
        deviceCount++
        foundDevices.append("[VID: ").append(device.vendorId).append(", PID: ").append(device.productId).append("] ")
        if (device.vendorId == vid && device.productId == pid) {
            pslabDevice = device
            break
        }
    }

    if (pslabDevice == null) {
        if (deviceCount == 0) {
            result.error(
                "NOT_FOUND",
                "USB list is EMPTY (0 devices). The OS is blocking the port. Please check your phone's OTG settings! (It auto-turns off after 10 mins)",
                null
            )
        } else {
            result.error(
                "NOT_FOUND",
                "Found devices: $foundDevices but none matched VID:$vid PID:$pid",
                null
            )
        }
        return
    }

    if (usbManager.hasPermission(pslabDevice)) {
        openAndReturnFd(usbManager, pslabDevice, result)
    } else {
        requestUsbPermission(usbManager, pslabDevice, result)
    }
}

private fun openAndReturnFd(usbManager: UsbManager, device: UsbDevice, result: MethodChannel.Result) {
    val connection = usbManager.openDevice(device)
    if (connection != null) {
        val fd = connection.fileDescriptor
        result.success(fd)
    } else {
        result.error("OPEN_FAIL", "Failed to claim and open hardware USB connection handle", null)
    }
}

private fun MainActivity.requestUsbPermission(usbManager: UsbManager, device: UsbDevice, result: MethodChannel.Result) {
    var flags = 0
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        flags = PendingIntent.FLAG_MUTABLE
    }

    val intent = Intent("com.pslab.USB_PERMISSION").apply {
        `package` = packageName
    }
    val permissionIntent = PendingIntent.getBroadcast(this, 0, intent, flags)

    val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            context?.unregisterReceiver(this)
            if (intent?.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false) == true) {
                openAndReturnFd(usbManager, device, result)
            } else {
                result.error("DENIED", "User denied runtime OS permission to access device hardware", null)
            }
        }
    }

    val filter = IntentFilter("com.pslab.USB_PERMISSION")
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
    } else {
        registerReceiver(usbReceiver, filter)
    }

    usbManager.requestPermission(device, permissionIntent)
}

private fun getManifestPermission(dartName: String?): String? {
    return when (dartName) {
        "microphone" -> Manifest.permission.RECORD_AUDIO
        "location" -> Manifest.permission.ACCESS_FINE_LOCATION
        else -> null
    }
}

private fun Context.getPermissionStatusString(permission: String): String {
    if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
        return MainActivity.STATUS_GRANTED
    }
    val activity = this as? MainActivity
    val shouldShowRationale = activity?.let { ActivityCompat.shouldShowRequestPermissionRationale(it, permission) } ?: false
    return if (!shouldShowRationale) MainActivity.STATUS_PERMANENTLY_DENIED else MainActivity.STATUS_DENIED
}

private fun MainActivity.startTemperatureUpdates(): Boolean {
    if (temperatureSensor == null || sensorManager == null) {
        Log.e("MainActivity", "Temperature sensor not available")
        return false
    }

    if (!isListening) {
        val registered = sensorManager?.registerListener(
            this,
            temperatureSensor,
            SensorManager.SENSOR_DELAY_NORMAL
        ) ?: false

        if (registered) {
            isListening = true
            Log.d("MainActivity", "Temperature sensor listener registered")
            if (currentTemperature != 0.0f && temperatureEventSink != null) {
                Log.d("MainActivity", "Sending initial temperature to Flutter: $currentTemperature")
                temperatureEventSink?.success(currentTemperature.toDouble())
            }
            return true
        } else {
            Log.e("MainActivity", "Failed to register temperature sensor listener")
            return false
        }
    }
    return true
}

private fun MainActivity.stopTemperatureUpdates() {
    if (isListening && sensorManager != null) {
        sensorManager?.unregisterListener(this, temperatureSensor)
        isListening = false
        Log.d("MainActivity", "Temperature sensor listener unregistered")
    }
}

private fun isValidTemperature(temperature: Float): Boolean {
    if (temperature.isNaN() || temperature.isInfinite()) return false
    return temperature >= -273.15f && temperature <= 200f && Math.abs(temperature) <= 1e10f
}