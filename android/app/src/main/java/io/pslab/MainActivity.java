package io.pslab;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity implements SensorEventListener {
    private static final String TEMPERATURE_CHANNEL = "io.pslab/temperature";
    private static final String TEMPERATURE_STREAM = "io.pslab/temperature_stream";
    private static final String TAG = "MainActivity";
    private SensorManager sensorManager;
    private Sensor temperatureSensor;
    private EventChannel.EventSink temperatureEventSink;
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