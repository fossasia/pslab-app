package io.pslab.sensors;

import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.widget.Spinner;
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
import com.github.mikephil.charting.interfaces.datasets.ILineDataSet;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import io.pslab.DataFormatter;
import io.pslab.R;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.MPU925x;

public class SensorMPU925X extends AbstractSensorActivity {
    private static final String TAG = SensorMPU925X.class.getSimpleName();

    private static final String KEY_ENTRIES_AX = TAG + "_entries_ax";
    private static final String KEY_ENTRIES_AY = TAG + "_entries_ay";
    private static final String KEY_ENTRIES_AZ = TAG + "_entries_az";
    private static final String KEY_ENTRIES_GX = TAG + "_entries_gx";
    private static final String KEY_ENTRIES_GY = TAG + "_entries_gy";
    private static final String KEY_ENTRIES_GZ = TAG + "_entries_gz";
    private static final String KEY_VALUE_AX = TAG + "_value_ax";
    private static final String KEY_VALUE_AY = TAG + "_value_ay";
    private static final String KEY_VALUE_AZ = TAG + "_value_az";
    private static final String KEY_VALUE_GX = TAG + "_value_gx";
    private static final String KEY_VALUE_GY = TAG + "_value_gy";
    private static final String KEY_VALUE_GZ = TAG + "_value_gz";
    private static final String KEY_VALUE_TEMP = TAG + "_value_temp";
    private static final String KEY_POS_1 = TAG + "_pos_1";
    private static final String KEY_POS_2 = TAG + "_pos_2";
    private static final String KEY_POS_3 = TAG + "_pos_3";
    private static final String KEY_POS_4 = TAG + "_pos_4";

    private SensorDataFetch sensorDataFetch;
    private MPU925x sensorMPU925X;

    private ArrayList<Entry> entriesAx;
    private ArrayList<Entry> entriesAy;
    private ArrayList<Entry> entriesAz;
    private ArrayList<Entry> entriesGx;
    private ArrayList<Entry> entriesGy;
    private ArrayList<Entry> entriesGz;

    private LineChart mChartAcceleration;
    private LineChart mChartGyroscope;
    private TextView tvSensorMPU925Xax;
    private TextView tvSensorMPU925Xay;
    private TextView tvSensorMPU925Xaz;
    private TextView tvSensorMPU925Xgx;
    private TextView tvSensorMPU925Xgy;
    private TextView tvSensorMPU925Xgz;
    private TextView tvSensorMPU925Xtemp;
    private Spinner spinnerSensorMPU925X1;
    private Spinner spinnerSensorMPU925X2;
    private Spinner spinnerSensorMPU925X3;
    private Spinner spinnerSensorMPU925X4;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        I2C i2c = getScienceLab().i2c;
        try {
            sensorMPU925X = new MPU925x(i2c);
        } catch (IOException | NullPointerException e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorMPU925Xax = findViewById(R.id.tv_sensor_mpu925x_ax);
        tvSensorMPU925Xay = findViewById(R.id.tv_sensor_mpu925x_ay);
        tvSensorMPU925Xaz = findViewById(R.id.tv_sensor_mpu925x_az);
        tvSensorMPU925Xgx = findViewById(R.id.tv_sensor_mpu925x_gx);
        tvSensorMPU925Xgy = findViewById(R.id.tv_sensor_mpu925x_gy);
        tvSensorMPU925Xgz = findViewById(R.id.tv_sensor_mpu925x_gz);
        tvSensorMPU925Xtemp = findViewById(R.id.tv_sensor_mpu925x_temp);

        spinnerSensorMPU925X1 = findViewById(R.id.spinner_sensor_mpu925x_1);
        spinnerSensorMPU925X2 = findViewById(R.id.spinner_sensor_mpu925x_2);
        spinnerSensorMPU925X3 = findViewById(R.id.spinner_sensor_mpu925x_3);
        spinnerSensorMPU925X4 = findViewById(R.id.spinner_sensor_mpu925x_4);

        mChartAcceleration = findViewById(R.id.chart_sensor_mpu925x_accelerometer);
        mChartGyroscope = findViewById(R.id.chart_sensor_mpu925x_gyroscope);

        XAxis xAccelerometer = mChartAcceleration.getXAxis();
        YAxis yAccelerometer = mChartAcceleration.getAxisLeft();
        YAxis yAccelerometer2 = mChartAcceleration.getAxisRight();

        XAxis xGyroscope = mChartGyroscope.getXAxis();
        YAxis yGyroscope = mChartGyroscope.getAxisLeft();
        YAxis yGyroscope2 = mChartGyroscope.getAxisRight();

        mChartAcceleration.setTouchEnabled(true);
        mChartAcceleration.setHighlightPerDragEnabled(true);
        mChartAcceleration.setDragEnabled(true);
        mChartAcceleration.setScaleEnabled(true);
        mChartAcceleration.setDrawGridBackground(false);
        mChartAcceleration.setPinchZoom(true);
        mChartAcceleration.setScaleYEnabled(false);
        mChartAcceleration.setBackgroundColor(Color.BLACK);
        mChartAcceleration.getDescription().setEnabled(false);

        LineData data = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChartAcceleration.setData(data);

        Legend l = mChartAcceleration.getLegend();
        l.setForm(Legend.LegendForm.LINE);
        l.setTextColor(Color.WHITE);

        xAccelerometer.setTextColor(Color.WHITE);
        xAccelerometer.setDrawGridLines(true);
        xAccelerometer.setAvoidFirstLastClipping(true);

        yAccelerometer.setTextColor(Color.WHITE);
        yAccelerometer.setAxisMaximum(25f);
        yAccelerometer.setAxisMinimum(-25f);
        yAccelerometer.setDrawGridLines(true);
        yAccelerometer.setLabelCount(10);

        yAccelerometer2.setDrawGridLines(false);

        mChartGyroscope.setTouchEnabled(true);
        mChartGyroscope.setHighlightPerDragEnabled(true);
        mChartGyroscope.setDragEnabled(true);
        mChartGyroscope.setScaleEnabled(true);
        mChartGyroscope.setDrawGridBackground(false);
        mChartGyroscope.setPinchZoom(true);
        mChartGyroscope.setScaleYEnabled(false);
        mChartGyroscope.setBackgroundColor(Color.BLACK);
        mChartGyroscope.getDescription().setEnabled(false);

        LineData data2 = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChartGyroscope.setData(data2);

        Legend l2 = mChartGyroscope.getLegend();
        l2.setForm(Legend.LegendForm.LINE);
        l2.setTextColor(Color.WHITE);

        xGyroscope.setTextColor(Color.WHITE);
        xGyroscope.setDrawGridLines(true);
        xGyroscope.setAvoidFirstLastClipping(true);

        yGyroscope.setTextColor(Color.WHITE);
        yGyroscope.setAxisMaximum(200f);
        yGyroscope.setAxisMinimum(-200f);
        yGyroscope.setDrawGridLines(true);
        yGyroscope.setLabelCount(10);

        yGyroscope2.setDrawGridLines(false);

        try {
            if (sensorMPU925X != null) {
                sensorMPU925X.setAccelRange(Integer.parseInt(spinnerSensorMPU925X2.getSelectedItem().toString()));
            }
        } catch (IOException e) {
            Log.e(TAG, "Error setting range.", e);
        }

        try {
            if (sensorMPU925X != null) {
                sensorMPU925X.setGyroRange(Integer.parseInt(spinnerSensorMPU925X1.getSelectedItem().toString()));
            }
        } catch (IOException e) {
            Log.e(TAG, "Error setting range.", e);
        }

        if (savedInstanceState == null) {
            entriesAx = new ArrayList<>();
            entriesAy = new ArrayList<>();
            entriesAz = new ArrayList<>();
            entriesGx = new ArrayList<>();
            entriesGy = new ArrayList<>();
            entriesGz = new ArrayList<>();
        } else {
            spinnerSensorMPU925X1.setSelection(savedInstanceState.getInt(KEY_POS_1));
            spinnerSensorMPU925X2.setSelection(savedInstanceState.getInt(KEY_POS_2));
            spinnerSensorMPU925X3.setSelection(savedInstanceState.getInt(KEY_POS_3));
            spinnerSensorMPU925X4.setSelection(savedInstanceState.getInt(KEY_POS_4));

            tvSensorMPU925Xax.setText(savedInstanceState.getString(KEY_VALUE_AX));
            tvSensorMPU925Xay.setText(savedInstanceState.getString(KEY_VALUE_AY));
            tvSensorMPU925Xaz.setText(savedInstanceState.getString(KEY_VALUE_AZ));
            tvSensorMPU925Xgx.setText(savedInstanceState.getString(KEY_VALUE_GX));
            tvSensorMPU925Xgy.setText(savedInstanceState.getString(KEY_VALUE_GY));
            tvSensorMPU925Xgz.setText(savedInstanceState.getString(KEY_VALUE_GZ));
            tvSensorMPU925Xtemp.setText(savedInstanceState.getString(KEY_VALUE_TEMP));

            entriesAx = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_AX);
            entriesAy = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_AY);
            entriesAz = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_AZ);
            entriesGx = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_GX);
            entriesGy = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_GY);
            entriesGz = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_GZ);

            sensorDataFetch.updateUi();
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putInt(KEY_POS_1, spinnerSensorMPU925X1.getSelectedItemPosition());
        outState.putInt(KEY_POS_2, spinnerSensorMPU925X2.getSelectedItemPosition());
        outState.putInt(KEY_POS_3, spinnerSensorMPU925X3.getSelectedItemPosition());
        outState.putInt(KEY_POS_4, spinnerSensorMPU925X4.getSelectedItemPosition());

        outState.putString(KEY_VALUE_AX, tvSensorMPU925Xax.getText().toString());
        outState.putString(KEY_VALUE_AY, tvSensorMPU925Xay.getText().toString());
        outState.putString(KEY_VALUE_AZ, tvSensorMPU925Xaz.getText().toString());
        outState.putString(KEY_VALUE_GX, tvSensorMPU925Xgx.getText().toString());
        outState.putString(KEY_VALUE_GY, tvSensorMPU925Xgy.getText().toString());
        outState.putString(KEY_VALUE_GZ, tvSensorMPU925Xgz.getText().toString());
        outState.putString(KEY_VALUE_TEMP, tvSensorMPU925Xtemp.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES_AX, entriesAx);
        outState.putParcelableArrayList(KEY_ENTRIES_AY, entriesAy);
        outState.putParcelableArrayList(KEY_ENTRIES_AZ, entriesAz);
        outState.putParcelableArrayList(KEY_ENTRIES_GX, entriesGx);
        outState.putParcelableArrayList(KEY_ENTRIES_GY, entriesGy);
        outState.putParcelableArrayList(KEY_ENTRIES_GZ, entriesGz);
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private double[] dataGyro, dataAccel;
        private double dataTemp;
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public void getSensorData() {

            try {
                dataGyro = sensorMPU925X.getGyroscope();
                dataAccel = sensorMPU925X.getAcceleration();
                dataTemp = sensorMPU925X.getTemperature();
            } catch (IOException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }

            timeElapsed = getTimeElapsed();

            entriesAx.add(new Entry(timeElapsed, (float) dataAccel[0]));
            entriesAy.add(new Entry(timeElapsed, (float) dataAccel[1]));
            entriesAz.add(new Entry(timeElapsed, (float) dataAccel[2]));

            entriesGx.add(new Entry(timeElapsed, (float) dataGyro[0]));
            entriesGy.add(new Entry(timeElapsed, (float) dataGyro[1]));
            entriesGz.add(new Entry(timeElapsed, (float) dataGyro[2]));
        }

        public void updateUi() {

            if (isSensorDataAcquired()) {
                tvSensorMPU925Xax.setText(DataFormatter.formatDouble(dataAccel[0], DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorMPU925Xay.setText(DataFormatter.formatDouble(dataAccel[1], DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorMPU925Xaz.setText(DataFormatter.formatDouble(dataAccel[2], DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorMPU925Xgx.setText(DataFormatter.formatDouble(dataGyro[0], DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorMPU925Xgy.setText(DataFormatter.formatDouble(dataGyro[1], DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorMPU925Xgz.setText(DataFormatter.formatDouble(dataGyro[2], DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorMPU925Xtemp.setText(DataFormatter.formatDouble(dataTemp, DataFormatter.HIGH_PRECISION_FORMAT));
            }

            LineDataSet dataSet1 = new LineDataSet(entriesAx, getString(R.string.ax));
            LineDataSet dataSet2 = new LineDataSet(entriesAy, getString(R.string.ay));
            LineDataSet dataSet3 = new LineDataSet(entriesAz, getString(R.string.az));

            LineDataSet dataSet4 = new LineDataSet(entriesGx, getString(R.string.gx));
            LineDataSet dataSet5 = new LineDataSet(entriesGy, getString(R.string.gy));
            LineDataSet dataSet6 = new LineDataSet(entriesGz, getString(R.string.gz));


            dataSet1.setColor(Color.BLUE);
            dataSet2.setColor(Color.GREEN);
            dataSet3.setColor(Color.RED);

            dataSet4.setColor(Color.BLUE);
            dataSet5.setColor(Color.GREEN);
            dataSet6.setColor(Color.RED);

            List<ILineDataSet> dataSets = new ArrayList<>();
            dataSets.add(dataSet1);
            dataSets.add(dataSet2);
            dataSets.add(dataSet3);

            List<ILineDataSet> dataSets2 = new ArrayList<>();
            dataSets2.add(dataSet4);
            dataSets2.add(dataSet5);
            dataSets2.add(dataSet6);

            LineData data = new LineData(dataSets);
            mChartAcceleration.setData(data);
            mChartAcceleration.notifyDataSetChanged();
            mChartAcceleration.setVisibleXRangeMaximum(10);
            mChartAcceleration.moveViewToX(timeElapsed);

            LineData data2 = new LineData(dataSets2);
            mChartGyroscope.setData(data2);
            mChartGyroscope.notifyDataSetChanged();
            mChartGyroscope.setVisibleXRangeMaximum(10);
            mChartGyroscope.moveViewToX(timeElapsed);
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    @Override
    protected int getLayoutResId() {
        return R.layout.sensor_mpu925x;
    }

    @Override
    protected int getTitleResId() {
        return R.string.mpu925x;
    }
}
