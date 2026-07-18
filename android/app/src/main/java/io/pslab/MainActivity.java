package io.pslab;

import android.Manifest;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity implements SensorEventListener {
    private static final String TEMPERATURE_CHANNEL = "io.pslab/temperature";
    private static final String TEMPERATURE_STREAM = "io.pslab/temperature_stream";
    private static final String PERMISSION_CHANNEL = "io.pslab/permissions";
    private static final String USB_CHANNEL = "usb_serial";
    private static final String USB_EVENT_STREAM = "io.pslab/usb_events";
    private static final String ACTION_USB_PERMISSION = "com.pslab.USB_PERMISSION";
    private static final String TAG = "MainActivity";
    private static final int PERMISSION_REQ_CODE = 1001;

    private SensorManager sensorManager;
    private Sensor temperatureSensor;
    private EventChannel.EventSink temperatureEventSink;
    private MethodChannel.Result pendingPermissionResult;

    private EventChannel.EventSink usbEventSink;
    private BroadcastReceiver usbHardwareReceiver;

    private boolean isListening = false;
    private float currentTemperature = 0.0f;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        sensorManager = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
        if (sensorManager != null) {
            temperatureSensor = sensorManager.getDefaultSensor(Sensor.TYPE_AMBIENT_TEMPERATURE);
        }

        MethodChannel temperatureChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), TEMPERATURE_CHANNEL);
        temperatureChannel.setMethodCallHandler(this::handleMethodCall);

        EventChannel temperatureEventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), TEMPERATURE_STREAM);
        temperatureEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                temperatureEventSink = events;
                startTemperatureUpdates();
            }

            @Override
            public void onCancel(Object arguments) {
                temperatureEventSink = null;
                stopTemperatureUpdates();
            }
        });

        MethodChannel permissionChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), PERMISSION_CHANNEL);
        permissionChannel.setMethodCallHandler(this::handlePermissionMethodCall);

        MethodChannel usbChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), USB_CHANNEL);
        usbChannel.setMethodCallHandler(this::handleUsbMethodCall);

        EventChannel usbEventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), USB_EVENT_STREAM);
        usbEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                usbEventSink = events;
                registerUsbHardwareReceiver();
            }

            @Override
            public void onCancel(Object arguments) {
                usbEventSink = null;
                unregisterUsbHardwareReceiver();
            }
        });
    }

    private void registerUsbHardwareReceiver() {
        if (usbHardwareReceiver == null) {
            usbHardwareReceiver = new BroadcastReceiver() {
                @Override
                public void onReceive(Context context, Intent intent) {
                    String action = intent.getAction();

                    if (UsbManager.ACTION_USB_DEVICE_ATTACHED.equals(action) && usbEventSink != null) {
                        usbEventSink.success("ATTACHED");
                    } else if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(action) && usbEventSink != null) {
                        usbEventSink.success("DETACHED");
                    }
                }
            };
            IntentFilter filter = new IntentFilter();
            filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED);
            filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(usbHardwareReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
            } else {
                registerReceiver(usbHardwareReceiver, filter);
            }
        }
    }

    private void unregisterUsbHardwareReceiver() {
        if (usbHardwareReceiver != null) {
            unregisterReceiver(usbHardwareReceiver);
            usbHardwareReceiver = null;
        }
    }

    private void handleMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "isTemperatureSensorAvailable":
                result.success(temperatureSensor != null);
                break;
            case "getCurrentTemperature":
                result.success((double) currentTemperature);
                break;
            case "startTemperatureUpdates":
                if (startTemperatureUpdates()) {
                    result.success(true);
                } else {
                    result.error("SENSOR_ERROR", "Failed to start temperature updates", null);
                }
                break;
            case "stopTemperatureUpdates":
                stopTemperatureUpdates();
                result.success(true);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void handlePermissionMethodCall(MethodCall call, @NonNull MethodChannel.Result result) {
        String permissionArg = call.argument("permission");
        String manifestPermission = getManifestPermission(permissionArg);

        if (manifestPermission == null) {
            result.error("INVALID", "Unknown permission requested", null);
            return;
        }

        if ("checkStatus".equals(call.method)) {
            result.success(getPermissionStatusString(manifestPermission));
        } else if ("request".equals(call.method)) {
            if ("granted".equals(getPermissionStatusString(manifestPermission))) {
                result.success("granted");
            } else {
                pendingPermissionResult = result;
                ActivityCompat.requestPermissions(this, new String[]{manifestPermission}, PERMISSION_REQ_CODE);
            }
        } else {
            result.notImplemented();
        }
    }

    private void handleUsbMethodCall(MethodCall call, MethodChannel.Result result) {
        if ("getAndroidFd".equals(call.method)) {
            Number vid = call.argument("vid");
            Number pid = call.argument("pid");
            if (vid == null || pid == null) {
                result.error("INVALID_ARGS", "Missing VID or PID arguments", null);
                return;
            }
            getUsbFileDescriptor(vid.intValue(), pid.intValue(), result);
        } else {
            result.notImplemented();
        }
    }

    private void getUsbFileDescriptor(int vid, int pid, MethodChannel.Result result) {
        UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
        if (usbManager == null) {
            result.error("USB_SERVICE_UNAVAILABLE", "Android USB service could not be obtained", null);
            return;
        }

        StringBuilder foundDevices = new StringBuilder();
        int deviceCount = 0;
        UsbDevice pslabDevice = null;

        for (UsbDevice device : usbManager.getDeviceList().values()) {
            deviceCount++;
            foundDevices.append("[VID: ").append(device.getVendorId()).append(", PID: ").append(device.getProductId()).append("] ");
            if (device.getVendorId() == vid && device.getProductId() == pid) {
                pslabDevice = device;
                break;
            }
        }

        if (pslabDevice == null) {
            if (deviceCount == 0) {
                result.error("NOT_FOUND", "USB list is EMPTY (0 devices). The OS is blocking the port. Please check your phone's OTG settings! (It auto-turns off after 10 mins)", null);
            } else {
                result.error("NOT_FOUND", "Found devices: " + foundDevices.toString() + " but none matched VID:" + vid + " PID:" + pid, null);
            }
            return;
        }

        if (usbManager.hasPermission(pslabDevice)) {
            openAndReturnFd(usbManager, pslabDevice, result);
        } else {
            requestUsbPermission(usbManager, pslabDevice, result);
        }
    }

    private void openAndReturnFd(UsbManager usbManager, UsbDevice device, MethodChannel.Result result) {
        UsbDeviceConnection connection = usbManager.openDevice(device);
        if (connection != null) {
            int fd = connection.getFileDescriptor();
            result.success(fd);
        } else {
            result.error("OPEN_FAIL", "Failed to claim and open hardware USB connection handle", null);
        }
    }

    private void requestUsbPermission(UsbManager usbManager, UsbDevice device, MethodChannel.Result result) {
        int flags = 0;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = PendingIntent.FLAG_MUTABLE;
        }

        Intent intent = new Intent(ACTION_USB_PERMISSION);
        intent.setPackage(getPackageName());

        PendingIntent permissionIntent = PendingIntent.getBroadcast(this, 0, intent, flags);

        BroadcastReceiver usbReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                context.unregisterReceiver(this);
                if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                    openAndReturnFd(usbManager, device, result);
                } else {
                    result.error("DENIED", "User denied runtime OS permission to access device hardware", null);
                }
            }
        };

        IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(usbReceiver, filter);
        }

        usbManager.requestPermission(device, permissionIntent);
    }

    private String getManifestPermission(String dartName) {
        if ("microphone".equals(dartName)) {
            return Manifest.permission.RECORD_AUDIO;
        } else if ("location".equals(dartName)) {
            return Manifest.permission.ACCESS_FINE_LOCATION;
        }
        return null;
    }

    private String getPermissionStatusString(String permission) {
        if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
            return "granted";
        }
        boolean shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(this, permission);
        if (!shouldShowRationale) {
            return "permanentlyDenied";
        }
        return "denied";
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode == PERMISSION_REQ_CODE && pendingPermissionResult != null) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                pendingPermissionResult.success("granted");
            } else {
                if (permissions.length > 0) {
                    boolean shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(this, permissions[0]);
                    pendingPermissionResult.success(shouldShowRationale ? "denied" : "permanentlyDenied");
                } else {
                    pendingPermissionResult.success("denied");
                }
            }
            pendingPermissionResult = null;
        }
    }

    private boolean startTemperatureUpdates() {
        if (temperatureSensor == null || sensorManager == null) {
            Log.e(TAG, "Temperature sensor not available");
            return false;
        }

        if (!isListening) {
            boolean registered = sensorManager.registerListener(this, temperatureSensor, SensorManager.SENSOR_DELAY_NORMAL);
            if (registered) {
                isListening = true;
                Log.d(TAG, "Temperature sensor listener registered");

                if (currentTemperature != 0.0f && temperatureEventSink != null) {
                    Log.d(TAG, "Sending initial temperature to Flutter: " + currentTemperature);
                    temperatureEventSink.success((double) currentTemperature);
                }

                return true;
            } else {
                Log.e(TAG, "Failed to register temperature sensor listener");
                return false;
            }
        }
        return true;
    }

    private void stopTemperatureUpdates() {
        if (isListening && sensorManager != null) {
            sensorManager.unregisterListener(this, temperatureSensor);
            isListening = false;
            Log.d(TAG, "Temperature sensor listener unregistered");
        }
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() == Sensor.TYPE_AMBIENT_TEMPERATURE) {
            float temperature = event.values[0];

            if (isValidTemperature(temperature)) {
                currentTemperature = temperature;
                Log.d(TAG, "Temperature updated: " + currentTemperature + "°C");

                if (temperatureEventSink != null) {
                    Log.d(TAG, "Sending temperature to Flutter: " + currentTemperature);
                    temperatureEventSink.success((double) currentTemperature);
                }
            } else {
                Log.w(TAG, "Invalid temperature reading: " + temperature + " - ignoring");
            }
        }
    }

    private boolean isValidTemperature(float temperature) {
        if (Float.isNaN(temperature) || Float.isInfinite(temperature)) return false;
        return temperature >= -273.15f && temperature <= 200f && Math.abs(temperature) <= 1e10f;
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        Log.d(TAG, "Sensor accuracy changed: " + accuracy);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        stopTemperatureUpdates();
        unregisterUsbHardwareReceiver();
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (isListening && sensorManager != null) {
            sensorManager.unregisterListener(this);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (isListening && temperatureSensor != null && sensorManager != null) {
            sensorManager.registerListener(this, temperatureSensor, SensorManager.SENSOR_DELAY_NORMAL);
        }
    }
}