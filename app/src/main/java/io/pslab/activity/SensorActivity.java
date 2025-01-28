package io.pslab.activity;

import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ListView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.widget.Toolbar;

import com.google.android.material.snackbar.Snackbar;

import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import io.pslab.R;
import io.pslab.activity.guide.GuideActivity;
import io.pslab.communication.ScienceLab;
import io.pslab.communication.peripherals.I2C;
import io.pslab.others.CustomSnackBar;
import io.pslab.others.ScienceLabCommon;
import io.pslab.sensors.SensorADS1115;
import io.pslab.sensors.SensorAPDS9960;
import io.pslab.sensors.SensorBMP180;
import io.pslab.sensors.SensorCCS811;
import io.pslab.sensors.SensorHMC5883L;
import io.pslab.sensors.SensorMLX90614;
import io.pslab.sensors.SensorMPU6050;
import io.pslab.sensors.SensorMPU925X;
import io.pslab.sensors.SensorSHT21;
import io.pslab.sensors.SensorTSL2561;
import io.pslab.sensors.SensorVL53L0X;

/**
 * Created by asitava on 18/6/17.
 */

public class SensorActivity extends GuideActivity {
    private static final String TAG = SensorActivity.class.getSimpleName();

    private static final String KEY_ENTRIES_ADDRESSES = TAG + "_entries_addrs";
    private static final String KEY_ENTRIES_NAMES = TAG + "_entries_names";
    private static final String KEY_VALUE_SCAN = TAG + "_value_tvscan";

    private I2C i2c;
    private ScienceLab scienceLab;
    private final Map<Integer, List<String>> sensorAddr = new LinkedHashMap<>();
    private final List<String> dataAddress = new ArrayList<>();
    private final List<String> dataName = new ArrayList<>();
    private ArrayAdapter<String> adapter;
    private ListView lvSensor;
    private TextView tvSensorScan;
    private Button buttonSensorAutoScan;

    public SensorActivity() {
        super(R.layout.sensor_main);
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        scienceLab = ScienceLabCommon.scienceLab;

        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        final ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setTitle(R.string.sensors);
            actionBar.setDisplayHomeAsUpEnabled(true);
        }

        i2c = scienceLab.i2c;

        // Populate sensor addresses with multiple sensors mapped to the same address
        sensorAddr.put(0x48, List.of("ADS1115"));
        sensorAddr.put(0x77, List.of("BMP180"));
        sensorAddr.put(0x5A, List.of("MLX90614", "CCS811"));
        sensorAddr.put(0x1E, List.of("HMC5883L"));
        sensorAddr.put(0x68, List.of("MPU6050"));
        sensorAddr.put(0x40, List.of("SHT21"));
        sensorAddr.put(0x39, List.of("TSL2561", "APDS9960"));
        sensorAddr.put(0x69, List.of("MPU925x"));
        sensorAddr.put(0x29, List.of("VL53L0X"));

        adapter = new ArrayAdapter<>(getApplication(), R.layout.sensor_list_item, R.id.tv_sensor_list_item, dataName);

        buttonSensorAutoScan = findViewById(R.id.button_sensor_autoscan);
        tvSensorScan = findViewById(R.id.tv_sensor_scan);
        tvSensorScan.setText(getResources().getString(R.string.use_autoscan));
        lvSensor = findViewById(R.id.lv_sensor);
        lvSensor.setAdapter(adapter);

        if (savedInstanceState != null) {
            String savedScanResults = savedInstanceState.getString(KEY_VALUE_SCAN);
            List<String> savedNames = savedInstanceState.getStringArrayList(KEY_ENTRIES_NAMES);
            List<String> savedAddresses = savedInstanceState.getStringArrayList(KEY_ENTRIES_ADDRESSES);
            if (savedScanResults != null) tvSensorScan.setText(savedScanResults);
            if (savedNames != null) dataName.addAll(savedNames);
            if (savedAddresses != null) dataAddress.addAll(savedAddresses);
        }

        buttonSensorAutoScan.setOnClickListener(v -> {
            buttonSensorAutoScan.setClickable(false);
            tvSensorScan.setText(getResources().getString(R.string.scanning));
            new PopulateSensors().execute();
        });

        lvSensor.setOnItemClickListener((parent, view, position, id) -> {
            String itemValue = (String) lvSensor.getItemAtPosition(position);
            Intent intent;
            switch (itemValue) {
                case "ADS1115":
                    intent = new Intent(getApplication(), SensorADS1115.class);
                    startActivity(intent);
                    break;
                case "BMP180":
                    intent = new Intent(getApplication(), SensorBMP180.class);
                    startActivity(intent);
                    break;
                case "MLX90614":
                    intent = new Intent(getApplication(), SensorMLX90614.class);
                    startActivity(intent);
                    break;
                case "HMC5883L":
                    intent = new Intent(getApplication(), SensorHMC5883L.class);
                    startActivity(intent);
                    break;
                case "MPU6050":
                    intent = new Intent(getApplication(), SensorMPU6050.class);
                    startActivity(intent);
                    break;
                case "SHT21":
                    intent = new Intent(getApplication(), SensorSHT21.class);
                    startActivity(intent);
                    break;
                case "TSL2561":
                    intent = new Intent(getApplication(), SensorTSL2561.class);
                    startActivity(intent);
                    break;
                case "MPU925x":
                    intent = new Intent(getApplication(), SensorMPU925X.class);
                    startActivity(intent);
                    break;
                case "VL53L0X":
                    intent = new Intent(getApplication(), SensorVL53L0X.class);
                    startActivity(intent);
                    break;
                case "CCS811":
                    intent = new Intent(getApplication(), SensorCCS811.class);
                    startActivity(intent);
                    break;
                case "APDS9960":
                    intent = new Intent(getApplication(), SensorAPDS9960.class);
                    startActivity(intent);
                    break;
                default:
                    CustomSnackBar.showSnackBar(findViewById(android.R.id.content),
                            "Sensor Not Supported", null, null, Snackbar.LENGTH_SHORT);
            }
        });
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString(KEY_VALUE_SCAN, tvSensorScan.getText().toString());
        outState.putStringArrayList(KEY_ENTRIES_NAMES, new ArrayList<>(dataName));
        outState.putStringArrayList(KEY_ENTRIES_ADDRESSES, new ArrayList<>(dataAddress));
    }

    private class PopulateSensors extends AsyncTask<Void, Void, Void> {
        private List<Integer> detectedSensors;

        @Override
        protected Void doInBackground(Void... voids) {
            detectedSensors = new ArrayList<>();
            dataAddress.clear();
            dataName.clear();

            if (scienceLab.isConnected()) {
                try {
                    // Perform I2C scan to detect connected sensors
                    detectedSensors = i2c.scan(null);
                } catch (IOException | NullPointerException e) {
                    e.printStackTrace();
                }
            }

            return null;
        }

        @Override
        protected void onPostExecute(Void aVoid) {
            super.onPostExecute(aVoid);

            StringBuilder scanResults = new StringBuilder();

            // Populate the list with detected sensors
            if (detectedSensors != null && scienceLab.isConnected()) {
                for (Integer address : detectedSensors) {
                    if (address != null && sensorAddr.containsKey(address)) {
                        dataAddress.add(String.valueOf(address));
                        dataName.addAll(sensorAddr.get(address));
                    }
                }

                // Build scan results for detected sensors
                for (final String address : dataAddress) {
                    scanResults.append(address).append(": ").append(sensorAddr.get(Integer.parseInt(address))).append("\n");
                }
                tvSensorScan.setText(scanResults);
            }

            // Ensure the full list of sensors is displayed, even if not connected
            for (List<String> sensors : sensorAddr.values()) {
                if (!dataName.containsAll(sensors)) {
                    dataName.addAll(sensors);
                }
            }

            // Update scan message if no sensors were detected
            if (detectedSensors == null || detectedSensors.isEmpty()) {
                tvSensorScan.setText(getString(R.string.not_connected));
            }
            dataName.sort(String::compareTo);
            adapter.notifyDataSetChanged();
            buttonSensorAutoScan.setClickable(true);
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.sensor_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                finish();
                break;
            case R.id.show_guide:
                toggleGuide();
                break;
            default:
                break;
        }
        return true;
    }
}
