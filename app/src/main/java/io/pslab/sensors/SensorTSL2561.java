package io.pslab.sensors;

import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.widget.EditText;
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
import io.pslab.communication.sensors.TSL2561;

public class SensorTSL2561 extends AbstractSensorActivity {
    private static final String TAG = SensorTSL2561.class.getSimpleName();

    private static final String KEY_ENTRIES_FULL = TAG + "_entries_full";
    private static final String KEY_ENTRIES_INFRARED = TAG + "_entries_infrared";
    private static final String KEY_ENTRIES_VISIBLE = TAG + "_entries_visible";
    private static final String KEY_VALUE_FULL = TAG + "_value_full";
    private static final String KEY_VALUE_INFRARED = TAG + "_value_infrared";
    private static final String KEY_VALUE_VISIBLE = TAG + "_value_visible";
    private static final String KEY_VALUE_TIMING = TAG + "_value_timing";
    private static final String KEY_POS_GAIN = TAG + "_pos_gain";

    private SensorTSL2561.SensorDataFetch sensorDataFetch;
    private TSL2561 sensorTSL2561;

    private ArrayList<Entry> entriesFull;
    private ArrayList<Entry> entriesInfrared;
    private ArrayList<Entry> entriesVisible;

    private LineChart mChart;
    private TextView tvSensorTSL2561FullSpectrum;
    private TextView tvSensorTSL2561Infrared;
    private TextView tvSensorTSL2561Visible;
    private EditText etSensorTSL2561Timing;
    private Spinner spinnerSensorTSL2561Gain;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        I2C i2c = getScienceLab().i2c;
        try {
            sensorTSL2561 = new TSL2561(i2c, getScienceLab());
        } catch (IOException | InterruptedException e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorTSL2561FullSpectrum = findViewById(R.id.tv_sensor_tsl2561_full);
        tvSensorTSL2561Infrared = findViewById(R.id.tv_sensor_tsl2561_infrared);
        tvSensorTSL2561Visible = findViewById(R.id.tv_sensor_tsl2561_visible);
        spinnerSensorTSL2561Gain = findViewById(R.id.spinner_sensor_tsl2561_gain);
        etSensorTSL2561Timing = findViewById(R.id.et_sensor_tsl2561_timing);
        mChart = findViewById(R.id.chart_tsl2561);

        initChart(mChart);

        try {
            if (sensorTSL2561 != null & getScienceLab().isConnected()) {
                sensorTSL2561.setGain(spinnerSensorTSL2561Gain.getSelectedItem().toString());
            }
        } catch (IOException e) {
            Log.e(TAG, "Error setting gain.", e);
        }

        if (savedInstanceState == null) {
            entriesFull = new ArrayList<>();
            entriesInfrared = new ArrayList<>();
            entriesVisible = new ArrayList<>();
        } else {
            spinnerSensorTSL2561Gain.setSelection(savedInstanceState.getInt(KEY_POS_GAIN));

            etSensorTSL2561Timing.setText(savedInstanceState.getString(KEY_VALUE_TIMING));

            tvSensorTSL2561FullSpectrum.setText(savedInstanceState.getString(KEY_VALUE_FULL));
            tvSensorTSL2561Infrared.setText(savedInstanceState.getString(KEY_VALUE_INFRARED));
            tvSensorTSL2561Visible.setText(savedInstanceState.getString(KEY_VALUE_VISIBLE));

            entriesFull = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_FULL);
            entriesInfrared = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_INFRARED);
            entriesVisible = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_VISIBLE);

            sensorDataFetch.updateUi();
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putInt(KEY_POS_GAIN, spinnerSensorTSL2561Gain.getSelectedItemPosition());

        outState.putString(KEY_VALUE_TIMING, etSensorTSL2561Timing.getText().toString());

        outState.putString(KEY_VALUE_FULL, tvSensorTSL2561FullSpectrum.getText().toString());
        outState.putString(KEY_VALUE_INFRARED, tvSensorTSL2561Infrared.getText().toString());
        outState.putString(KEY_VALUE_VISIBLE, tvSensorTSL2561Visible.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES_FULL, entriesFull);
        outState.putParcelableArrayList(KEY_ENTRIES_INFRARED, entriesInfrared);
        outState.putParcelableArrayList(KEY_ENTRIES_VISIBLE, entriesVisible);
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private int[] dataTSL2561;
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public void getSensorData() {
            try {
                if (sensorTSL2561 != null) {
                    dataTSL2561 = sensorTSL2561.getRaw();
                }
            } catch (IOException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }
            timeElapsed = getTimeElapsed();
            entriesFull.add(new Entry(timeElapsed, dataTSL2561[0]));
            entriesInfrared.add(new Entry(timeElapsed, dataTSL2561[1]));
            entriesVisible.add(new Entry(timeElapsed, dataTSL2561[2]));
        }

        public void updateUi() {

            if (isSensorDataAcquired()) {
                tvSensorTSL2561FullSpectrum.setText(String.valueOf(dataTSL2561[0]));
                tvSensorTSL2561Infrared.setText(String.valueOf(dataTSL2561[1]));
                tvSensorTSL2561Visible.setText(String.valueOf(dataTSL2561[2]));
            }

            LineDataSet datasetFull = new LineDataSet(entriesFull, getString(R.string.full));
            LineDataSet dataSetInfrared = new LineDataSet(entriesInfrared, getString(R.string.infrared));
            LineDataSet dataSetVisible = new LineDataSet(entriesVisible, getString(R.string.visible));

            datasetFull.setColor(Color.BLUE);
            dataSetInfrared.setColor(Color.GREEN);
            dataSetVisible.setColor(Color.RED);

            updateChart(mChart, timeElapsed, datasetFull, dataSetInfrared, dataSetVisible);
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    @Override
    protected int getLayoutResId() {
        return R.layout.sensor_tsl2561;
    }

    @Override
    protected int getTitleResId() {
        return R.string.tsl2561;
    }
}
