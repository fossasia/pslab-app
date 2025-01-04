package io.pslab.sensors;

import android.os.Bundle;
import android.util.Log;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineDataSet;

import java.io.IOException;
import java.util.ArrayList;

import io.pslab.R;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.ADS1115;

public class SensorADS1115 extends AbstractSensorActivity {
    private static final String TAG = SensorADS1115.class.getSimpleName();

    private static final String KEY_ENTRIES = TAG + "_entries";
    private static final String KEY_VALUE = TAG + "_value";

    private SensorDataFetch sensorDataFetch;
    private ADS1115 sensorADS1115;

    private ArrayList<Entry> entries;

    private LineChart mChart;
    private TextView tvSensorADS1115;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        I2C i2c = getScienceLab().i2c;
        try {
            sensorADS1115 = new ADS1115(i2c);
        } catch (IOException | InterruptedException e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorADS1115 = findViewById(R.id.tv_sensor_ads1115);
        mChart = findViewById(R.id.chart_sensor_ads);

        Spinner spinnerSensorADS1115Gain = findViewById(R.id.spinner_sensor_ads1115_gain);
        Spinner spinnerSensorADS1115Channel = findViewById(R.id.spinner_sensor_ads1115_channel);
        Spinner spinnerSensorADS1115Rate = findViewById(R.id.spinner_sensor_ads1115_rate);

        if (sensorADS1115 != null) {
            sensorADS1115.setGain(spinnerSensorADS1115Gain.getSelectedItem().toString());
        }
        if (sensorADS1115 != null) {
            sensorADS1115.setChannel(spinnerSensorADS1115Channel.getSelectedItem().toString());
        }
        if (sensorADS1115 != null) {
            sensorADS1115.setDataRate(Integer.parseInt(spinnerSensorADS1115Rate.getSelectedItem().toString()));
        }

        initChart(mChart);

        if (savedInstanceState == null) {
            entries = new ArrayList<>();
        } else {
            tvSensorADS1115.setText(savedInstanceState.getString(KEY_VALUE));

            entries = savedInstanceState.getParcelableArrayList(KEY_ENTRIES);

            sensorDataFetch.updateUi();
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putString(KEY_VALUE, tvSensorADS1115.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES, entries);
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private int dataADS1115;
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public boolean getSensorData() {
            boolean success = false;

            try {
                if (sensorADS1115 != null) {
                    dataADS1115 = sensorADS1115.getRaw();
                    success = true;
                }
            } catch (IOException | InterruptedException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }

            timeElapsed = getTimeElapsed();
            entries.add(new Entry(timeElapsed, dataADS1115));

            return success;
        }

        @Override
        public void updateUi() {
            tvSensorADS1115.setText(String.valueOf(dataADS1115));

            LineDataSet dataSet = new LineDataSet(entries, getString(R.string.bx));

            updateChart(mChart, timeElapsed, dataSet);
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    protected int getLayoutResId() {
        return R.layout.sensor_ads1115;
    }

    @Override
    protected int getTitleResId() {
        return R.string.ads1115;
    }
}
