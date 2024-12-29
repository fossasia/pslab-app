package io.pslab.sensors;

import android.graphics.Color;
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
import io.pslab.communication.sensors.BMP180;

public class SensorBMP180 extends AbstractSensorActivity {
    private static final String TAG = SensorBMP180.class.getSimpleName();

    private static final String KEY_ENTRIES_TEMPERATURE = TAG + "_entries_temperature";
    private static final String KEY_ENTRIES_ALTITUDE = TAG + "_entries_altitude";
    private static final String KEY_ENTRIES_PRESSURE = TAG + "_entries_pressure";
    private static final String KEY_VALUE_TEMPERATURE = TAG + "_value_temperature";
    private static final String KEY_VALUE_ALTITUDE = TAG + "_value_altitude";
    private static final String KEY_VALUE_PRESSURE = TAG + "_value_pressure";

    private SensorDataFetch sensorDataFetch;
    private BMP180 sensorBMP180;

    private ArrayList<Entry> entriesTemperature;
    private ArrayList<Entry> entriesAltitude;
    private ArrayList<Entry> entriesPressure;

    private LineChart mChartTemperature;
    private LineChart mChartAltitude;
    private LineChart mChartPressure;
    private TextView tvSensorBMP180Temp;
    private TextView tvSensorBMP180Altitude;
    private TextView tvSensorBMP180Pressure;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        I2C i2c = getScienceLab().i2c;
        try {
            sensorBMP180 = new BMP180(i2c, getScienceLab());
        } catch (IOException | InterruptedException e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorBMP180Temp = findViewById(R.id.tv_sensor_bmp180_temp);
        tvSensorBMP180Altitude = findViewById(R.id.tv_sensor_bmp180_altitude);
        tvSensorBMP180Pressure = findViewById(R.id.tv_sensor_bmp180_pressure);

        mChartTemperature = findViewById(R.id.chart_temp_bmp180);
        mChartAltitude = findViewById(R.id.chart_alt_bmp180);
        mChartPressure = findViewById(R.id.chart_pre_bmp180);

        initChart(mChartTemperature);
        initChart(mChartAltitude);
        initChart(mChartPressure);

        if (savedInstanceState == null) {
            entriesTemperature = new ArrayList<>();
            entriesAltitude = new ArrayList<>();
            entriesPressure = new ArrayList<>();
        } else {
            tvSensorBMP180Temp.setText(savedInstanceState.getString(KEY_VALUE_TEMPERATURE));
            tvSensorBMP180Altitude.setText(savedInstanceState.getString(KEY_VALUE_ALTITUDE));
            tvSensorBMP180Pressure.setText(savedInstanceState.getString(KEY_VALUE_PRESSURE));

            entriesTemperature = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_TEMPERATURE);
            entriesAltitude = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_ALTITUDE);
            entriesPressure = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_PRESSURE);

            sensorDataFetch.updateUi();
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putString(KEY_VALUE_TEMPERATURE, tvSensorBMP180Temp.getText().toString());
        outState.putString(KEY_VALUE_ALTITUDE, tvSensorBMP180Altitude.getText().toString());
        outState.putString(KEY_VALUE_PRESSURE, tvSensorBMP180Pressure.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES_TEMPERATURE, entriesTemperature);
        outState.putParcelableArrayList(KEY_ENTRIES_ALTITUDE, entriesAltitude);
        outState.putParcelableArrayList(KEY_ENTRIES_PRESSURE, entriesPressure);
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private double[] dataBMP180 = new double[3];
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public void getSensorData() {
            try {
                if (sensorBMP180 != null && getScienceLab().isConnected()) {
                    dataBMP180 = sensorBMP180.getRaw();
                }
            } catch (IOException | InterruptedException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }

            timeElapsed = getTimeElapsed();
            entriesTemperature.add(new Entry(timeElapsed, (float) dataBMP180[0]));
            entriesAltitude.add(new Entry(timeElapsed, (float) dataBMP180[1]));
            entriesPressure.add(new Entry(timeElapsed, (float) dataBMP180[2]));
        }

        public void updateUi() {

            if (isSensorDataAcquired()) {
                tvSensorBMP180Temp.setText(DataFormatter.formatDouble(dataBMP180[0], DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorBMP180Altitude.setText(DataFormatter.formatDouble(dataBMP180[1], DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorBMP180Pressure.setText(DataFormatter.formatDouble(dataBMP180[2], DataFormatter.HIGH_PRECISION_FORMAT));
            }

            LineDataSet dataSetTemperature = new LineDataSet(entriesTemperature, getString(R.string.temperature));
            LineDataSet dataSetAltitude = new LineDataSet(entriesAltitude, getString(R.string.altitude));
            LineDataSet dataSetPressure = new LineDataSet(entriesPressure, getString(R.string.pressure));

            dataSetTemperature.setColor(Color.BLUE);
            dataSetAltitude.setColor(Color.GREEN);
            dataSetPressure.setColor(Color.RED);

            updateChart(mChartTemperature, timeElapsed, dataSetTemperature);
            updateChart(mChartAltitude, timeElapsed, dataSetAltitude);
            updateChart(mChartPressure, timeElapsed, dataSetPressure);
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    @Override
    protected int getLayoutResId() {
        return R.layout.sensor_bmp180;
    }

    @Override
    protected int getTitleResId() {
        return R.string.bmp180;
    }
}
