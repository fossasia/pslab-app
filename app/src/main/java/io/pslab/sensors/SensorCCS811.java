package io.pslab.sensors;

import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineDataSet;

import java.io.IOException;
import java.util.ArrayList;

import io.pslab.DataFormatter;
import io.pslab.R;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.CCS811;

public class SensorCCS811 extends AbstractSensorActivity {
    private static final String TAG = SensorCCS811.class.getSimpleName();

    private static final String KEY_ENTRIES_ECO2 = TAG + "_entries_eco2";
    private static final String KEY_ENTRIES_TVOC = TAG + "_entries_tvoc";
    private static final String KEY_VALUE_ECO2 = TAG + "_value_eco2";
    private static final String KEY_VALUE_TVOC = TAG + "_value_tvoc";

    private SensorDataFetch sensorDataFetch;
    private CCS811 sensorCCS811;

    private ArrayList<Entry> entrieseCO2;
    private ArrayList<Entry> entriesTVOC;

    private LineChart mCharteCO2;
    private LineChart mChartTVOC;
    private TextView tvSensorCCS811eCO2;
    private TextView tvSensorCCS811TVOC;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        I2C i2c = getScienceLab().i2c;
        try {
            sensorCCS811 = new CCS811(i2c, getScienceLab());
        } catch (Exception e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorCCS811eCO2 = findViewById(R.id.tv_sensor_ccs811_eCO2);
        tvSensorCCS811TVOC = findViewById(R.id.tv_sensor_ccs811_TVOC);
        mCharteCO2 = findViewById(R.id.chart_eCO2_ccs811);
        mChartTVOC = findViewById(R.id.chart_TVOC_ccs811);

        initChart(mCharteCO2);
        initChart(mChartTVOC);

        if (savedInstanceState == null) {
            entrieseCO2 = new ArrayList<>();
            entriesTVOC = new ArrayList<>();
        } else {
            tvSensorCCS811eCO2.setText(savedInstanceState.getString(KEY_VALUE_ECO2));
            tvSensorCCS811TVOC.setText(savedInstanceState.getString(KEY_VALUE_TVOC));

            entrieseCO2 = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_ECO2);
            entriesTVOC = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_TVOC);

            sensorDataFetch.updateUi();
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putString(KEY_VALUE_ECO2, tvSensorCCS811eCO2.getText().toString());
        outState.putString(KEY_VALUE_TVOC, tvSensorCCS811TVOC.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES_ECO2, entrieseCO2);
        outState.putParcelableArrayList(KEY_ENTRIES_TVOC, entriesTVOC);
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private int dataCCS811eCO2;
        private int dataCCS811TVOC;
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public boolean getSensorData() {
            boolean success = false;

            try {
                if (sensorCCS811 != null) {
                    int[] dataCS811 = sensorCCS811.getRaw();
                    dataCCS811eCO2 = dataCS811[0];
                    dataCCS811TVOC = dataCS811[1];
                    success = true;
                }
            } catch (IOException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }
            timeElapsed = getTimeElapsed();

            if (success) {
                entrieseCO2.add(new Entry(timeElapsed, dataCCS811eCO2));
                entriesTVOC.add(new Entry(timeElapsed, dataCCS811TVOC));
            }

            return success;
        }

        public void updateUi() {

            tvSensorCCS811eCO2.setText(DataFormatter.formatDouble(dataCCS811eCO2, DataFormatter.HIGH_PRECISION_FORMAT));
            tvSensorCCS811TVOC.setText(DataFormatter.formatDouble(dataCCS811TVOC, DataFormatter.HIGH_PRECISION_FORMAT));

            LineDataSet dataSeteCO2 = new LineDataSet(entrieseCO2, getString(R.string.eCO2));
            LineDataSet dataSetTVOC = new LineDataSet(entriesTVOC, getString(R.string.eTVOC));

            updateChart(mCharteCO2, timeElapsed, dataSeteCO2);
            updateChart(mChartTVOC, timeElapsed, dataSetTVOC);
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    @Override
    protected int getLayoutResId() {
        return R.layout.sensor_ccs811;
    }

    @Override
    protected int getTitleResId() {
        return R.string.ccs811;
    }
}
