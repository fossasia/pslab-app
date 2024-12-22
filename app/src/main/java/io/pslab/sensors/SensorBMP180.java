package io.pslab.sensors;

import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.components.Legend;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
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

        XAxis xTemperature = mChartTemperature.getXAxis();
        YAxis yTemperature = mChartTemperature.getAxisLeft();
        YAxis yTemperature2 = mChartTemperature.getAxisRight();

        XAxis xAltitude = mChartAltitude.getXAxis();
        YAxis yAltitude = mChartAltitude.getAxisLeft();
        YAxis yAltitude2 = mChartAltitude.getAxisRight();

        XAxis xPressure = mChartPressure.getXAxis();
        YAxis yPressure = mChartPressure.getAxisLeft();
        YAxis yPressure2 = mChartPressure.getAxisRight();

        mChartTemperature.setTouchEnabled(true);
        mChartTemperature.setHighlightPerDragEnabled(true);
        mChartTemperature.setDragEnabled(true);
        mChartTemperature.setScaleEnabled(true);
        mChartTemperature.setDrawGridBackground(false);
        mChartTemperature.setPinchZoom(true);
        mChartTemperature.setScaleYEnabled(false);
        mChartTemperature.setBackgroundColor(Color.BLACK);
        mChartTemperature.getDescription().setEnabled(false);

        LineData data = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChartTemperature.setData(data);

        Legend l = mChartTemperature.getLegend();
        l.setForm(Legend.LegendForm.LINE);
        l.setTextColor(Color.WHITE);

        xTemperature.setTextColor(Color.WHITE);
        xTemperature.setDrawGridLines(true);
        xTemperature.setAvoidFirstLastClipping(true);

        yTemperature.setTextColor(Color.WHITE);
        yTemperature.setAxisMaximum(70f);
        yTemperature.setAxisMinimum(0f);
        yTemperature.setDrawGridLines(true);
        yTemperature.setLabelCount(10);

        yTemperature2.setDrawGridLines(false);

        mChartAltitude.setTouchEnabled(true);
        mChartAltitude.setHighlightPerDragEnabled(true);
        mChartAltitude.setDragEnabled(true);
        mChartAltitude.setScaleEnabled(true);
        mChartAltitude.setDrawGridBackground(false);
        mChartAltitude.setPinchZoom(true);
        mChartAltitude.setScaleYEnabled(false);
        mChartAltitude.setBackgroundColor(Color.BLACK);
        mChartAltitude.getDescription().setEnabled(false);

        LineData data2 = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChartAltitude.setData(data2);

        Legend l2 = mChartAltitude.getLegend();
        l2.setForm(Legend.LegendForm.LINE);
        l2.setTextColor(Color.WHITE);

        xAltitude.setTextColor(Color.WHITE);
        xAltitude.setDrawGridLines(true);
        xAltitude.setAvoidFirstLastClipping(true);

        yAltitude.setTextColor(Color.WHITE);
        yAltitude.setAxisMaximum(3000f);
        yAltitude.setAxisMinimum(0f);
        yAltitude.setDrawGridLines(true);
        yAltitude.setLabelCount(10);

        yAltitude2.setDrawGridLines(false);

        mChartPressure.setTouchEnabled(true);
        mChartPressure.setHighlightPerDragEnabled(true);
        mChartPressure.setDragEnabled(true);
        mChartPressure.setScaleEnabled(true);
        mChartPressure.setDrawGridBackground(false);
        mChartPressure.setPinchZoom(true);
        mChartPressure.setScaleYEnabled(false);
        mChartPressure.setBackgroundColor(Color.BLACK);
        mChartPressure.getDescription().setEnabled(false);

        LineData data3 = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChartTemperature.setData(data3);

        Legend l3 = mChartTemperature.getLegend();
        l3.setForm(Legend.LegendForm.LINE);
        l3.setTextColor(Color.WHITE);

        xPressure.setTextColor(Color.WHITE);
        xPressure.setDrawGridLines(true);
        xPressure.setAvoidFirstLastClipping(true);

        yPressure.setTextColor(Color.WHITE);
        yPressure.setAxisMaximum(1000000f);
        yPressure.setAxisMinimum(0f);
        yPressure.setDrawGridLines(true);
        yPressure.setLabelCount(10);

        yPressure2.setDrawGridLines(false);

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

            LineDataSet dataSet1 = new LineDataSet(entriesTemperature, getString(R.string.temperature));
            LineDataSet dataSet2 = new LineDataSet(entriesAltitude, getString(R.string.altitude));
            LineDataSet dataSet3 = new LineDataSet(entriesPressure, getString(R.string.pressure));

            dataSet1.setColor(Color.BLUE);
            dataSet2.setColor(Color.GREEN);
            dataSet3.setColor(Color.RED);

            LineData data = new LineData(dataSet1);
            mChartTemperature.setData(data);
            mChartTemperature.notifyDataSetChanged();
            mChartTemperature.setVisibleXRangeMaximum(10);
            mChartTemperature.moveViewToX(timeElapsed);

            LineData data2 = new LineData(dataSet2);
            mChartAltitude.setData(data2);
            mChartAltitude.notifyDataSetChanged();
            mChartAltitude.setVisibleXRangeMaximum(10);
            mChartAltitude.moveViewToX(timeElapsed);

            LineData data3 = new LineData(dataSet3);
            mChartPressure.setData(data3);
            mChartPressure.notifyDataSetChanged();
            mChartPressure.setVisibleXRangeMaximum(10);
            mChartPressure.moveViewToX(timeElapsed);
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
