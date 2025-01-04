package io.pslab.sensors;

import android.graphics.Color;
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
import java.util.List;

import io.pslab.DataFormatter;
import io.pslab.R;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.MPU6050;

public class SensorMPU6050 extends AbstractSensorActivity {
    private static final String TAG = SensorMPU6050.class.getSimpleName();

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

    private SensorMPU6050.SensorDataFetch sensorDataFetch;
    private MPU6050 sensorMPU6050;

    private ArrayList<Entry> entriesAx;
    private ArrayList<Entry> entriesAy;
    private ArrayList<Entry> entriesAz;
    private ArrayList<Entry> entriesGx;
    private ArrayList<Entry> entriesGy;
    private ArrayList<Entry> entriesGz;

    private LineChart mChartAcceleration;
    private LineChart mChartGyroscope;
    private TextView tvSensorMPU6050ax;
    private TextView tvSensorMPU6050ay;
    private TextView tvSensorMPU6050az;
    private TextView tvSensorMPU6050gx;
    private TextView tvSensorMPU6050gy;
    private TextView tvSensorMPU6050gz;
    private TextView tvSensorMPU6050temp;
    private Spinner spinnerSensorMPU60501;
    private Spinner spinnerSensorMPU60502;
    private Spinner spinnerSensorMPU60503;
    private Spinner spinnerSensorMPU60504;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        I2C i2c = getScienceLab().i2c;
        try {
            sensorMPU6050 = new MPU6050(i2c, getScienceLab());
        } catch (IOException e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorMPU6050ax = findViewById(R.id.tv_sensor_mpu6050_ax);
        tvSensorMPU6050ay = findViewById(R.id.tv_sensor_mpu6050_ay);
        tvSensorMPU6050az = findViewById(R.id.tv_sensor_mpu6050_az);
        tvSensorMPU6050gx = findViewById(R.id.tv_sensor_mpu6050_gx);
        tvSensorMPU6050gy = findViewById(R.id.tv_sensor_mpu6050_gy);
        tvSensorMPU6050gz = findViewById(R.id.tv_sensor_mpu6050_gz);
        tvSensorMPU6050temp = findViewById(R.id.tv_sensor_mpu6050_temp);

        spinnerSensorMPU60501 = findViewById(R.id.spinner_sensor_mpu6050_1);
        spinnerSensorMPU60502 = findViewById(R.id.spinner_sensor_mpu6050_2);
        spinnerSensorMPU60503 = findViewById(R.id.spinner_sensor_mpu6050_3);
        spinnerSensorMPU60504 = findViewById(R.id.spinner_sensor_mpu6050_4);

        mChartAcceleration = findViewById(R.id.chart_sensor_mpu6050_accelerometer);
        mChartGyroscope = findViewById(R.id.chart_sensor_mpu6050_gyroscope);

        initChart(mChartAcceleration);
        initChart(mChartGyroscope);

        try {
            if (sensorMPU6050 != null && getScienceLab().isConnected()) {
                sensorMPU6050.setAccelerationRange(Integer.parseInt(spinnerSensorMPU60502.getSelectedItem().toString()));
            }
        } catch (IOException e) {
            Log.e(TAG, "Error setting range.", e);
        }

        try {
            if (sensorMPU6050 != null && getScienceLab().isConnected()) {
                sensorMPU6050.setGyroRange(Integer.parseInt(spinnerSensorMPU60501.getSelectedItem().toString()));
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
            spinnerSensorMPU60501.setSelection(savedInstanceState.getInt(KEY_POS_1));
            spinnerSensorMPU60502.setSelection(savedInstanceState.getInt(KEY_POS_2));
            spinnerSensorMPU60503.setSelection(savedInstanceState.getInt(KEY_POS_3));
            spinnerSensorMPU60504.setSelection(savedInstanceState.getInt(KEY_POS_4));

            tvSensorMPU6050ax.setText(savedInstanceState.getString(KEY_VALUE_AX));
            tvSensorMPU6050ay.setText(savedInstanceState.getString(KEY_VALUE_AY));
            tvSensorMPU6050az.setText(savedInstanceState.getString(KEY_VALUE_AZ));
            tvSensorMPU6050gx.setText(savedInstanceState.getString(KEY_VALUE_GX));
            tvSensorMPU6050gy.setText(savedInstanceState.getString(KEY_VALUE_GY));
            tvSensorMPU6050gz.setText(savedInstanceState.getString(KEY_VALUE_GZ));
            tvSensorMPU6050temp.setText(savedInstanceState.getString(KEY_VALUE_TEMP));

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

        outState.putInt(KEY_POS_1, spinnerSensorMPU60501.getSelectedItemPosition());
        outState.putInt(KEY_POS_2, spinnerSensorMPU60502.getSelectedItemPosition());
        outState.putInt(KEY_POS_3, spinnerSensorMPU60503.getSelectedItemPosition());
        outState.putInt(KEY_POS_4, spinnerSensorMPU60504.getSelectedItemPosition());

        outState.putString(KEY_VALUE_AX, tvSensorMPU6050ax.getText().toString());
        outState.putString(KEY_VALUE_AY, tvSensorMPU6050ay.getText().toString());
        outState.putString(KEY_VALUE_AZ, tvSensorMPU6050az.getText().toString());
        outState.putString(KEY_VALUE_GX, tvSensorMPU6050gx.getText().toString());
        outState.putString(KEY_VALUE_GY, tvSensorMPU6050gy.getText().toString());
        outState.putString(KEY_VALUE_GZ, tvSensorMPU6050gz.getText().toString());
        outState.putString(KEY_VALUE_TEMP, tvSensorMPU6050temp.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES_AX, entriesAx);
        outState.putParcelableArrayList(KEY_ENTRIES_AY, entriesAy);
        outState.putParcelableArrayList(KEY_ENTRIES_AZ, entriesAz);
        outState.putParcelableArrayList(KEY_ENTRIES_GX, entriesGx);
        outState.putParcelableArrayList(KEY_ENTRIES_GY, entriesGy);
        outState.putParcelableArrayList(KEY_ENTRIES_GZ, entriesGz);
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private List<Double> dataMPU6050 = new ArrayList<>();
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public boolean getSensorData() {
            boolean success = false;

            try {
                dataMPU6050 = sensorMPU6050.getRaw();
                success = dataMPU6050 != null;
            } catch (IOException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }

            timeElapsed = getTimeElapsed();

            if (success) {
                entriesAx.add(new Entry(timeElapsed, dataMPU6050.get(0).floatValue()));
                entriesAy.add(new Entry(timeElapsed, dataMPU6050.get(1).floatValue()));
                entriesAz.add(new Entry(timeElapsed, dataMPU6050.get(2).floatValue()));

                entriesGx.add(new Entry(timeElapsed, dataMPU6050.get(4).floatValue()));
                entriesGy.add(new Entry(timeElapsed, dataMPU6050.get(5).floatValue()));
                entriesGz.add(new Entry(timeElapsed, dataMPU6050.get(6).floatValue()));
            }

            return success;
        }

        public void updateUi() {

            tvSensorMPU6050ax.setText(DataFormatter.formatDouble(dataMPU6050.get(0), DataFormatter.HIGH_PRECISION_FORMAT));
            tvSensorMPU6050ay.setText(DataFormatter.formatDouble(dataMPU6050.get(1), DataFormatter.HIGH_PRECISION_FORMAT));
            tvSensorMPU6050az.setText(DataFormatter.formatDouble(dataMPU6050.get(2), DataFormatter.HIGH_PRECISION_FORMAT));
            tvSensorMPU6050gx.setText(DataFormatter.formatDouble(dataMPU6050.get(4), DataFormatter.HIGH_PRECISION_FORMAT));
            tvSensorMPU6050gy.setText(DataFormatter.formatDouble(dataMPU6050.get(5), DataFormatter.HIGH_PRECISION_FORMAT));
            tvSensorMPU6050gz.setText(DataFormatter.formatDouble(dataMPU6050.get(6), DataFormatter.HIGH_PRECISION_FORMAT));
            tvSensorMPU6050temp.setText(DataFormatter.formatDouble(dataMPU6050.get(3), DataFormatter.HIGH_PRECISION_FORMAT));

            LineDataSet dataSetAx = new LineDataSet(entriesAx, getString(R.string.ax));
            LineDataSet dataSetAy = new LineDataSet(entriesAy, getString(R.string.ay));
            LineDataSet dataSetAz = new LineDataSet(entriesAz, getString(R.string.az));

            LineDataSet dataSetGx = new LineDataSet(entriesGx, getString(R.string.gx));
            LineDataSet dataSetGy = new LineDataSet(entriesGy, getString(R.string.gy));
            LineDataSet dataSetGz = new LineDataSet(entriesGz, getString(R.string.gz));

            dataSetAx.setColor(Color.BLUE);
            dataSetAy.setColor(Color.GREEN);
            dataSetAz.setColor(Color.RED);

            dataSetGx.setColor(Color.BLUE);
            dataSetGy.setColor(Color.GREEN);
            dataSetGz.setColor(Color.RED);

            updateChart(mChartAcceleration, timeElapsed, dataSetAx, dataSetAy, dataSetAz);
            updateChart(mChartGyroscope, timeElapsed, dataSetGx, dataSetGy, dataSetGz);
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    @Override
    protected int getLayoutResId() {
        return R.layout.sensor_mpu6050;
    }

    @Override
    protected int getTitleResId() {
        return R.string.mpu6050;
    }
}
