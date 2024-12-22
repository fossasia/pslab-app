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

import java.io.IOException;
import java.util.ArrayList;

import io.pslab.DataFormatter;
import io.pslab.R;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.APDS9960;

public class SensorAPDS9960 extends AbstractSensorActivity {
    private static final String TAG = SensorAPDS9960.class.getSimpleName();

    private static final String KEY_ENTRIES_LUX = TAG + "_entries_lux";
    private static final String KEY_ENTRIES_PROXIMITY = TAG + "_entries_proximity";
    private static final String KEY_VALUE_RED = TAG + "_value_red";
    private static final String KEY_VALUE_GREEN = TAG + "_value_green";
    private static final String KEY_VALUE_BLUE = TAG + "_value_blue";
    private static final String KEY_VALUE_CLEAR = TAG + "_value_clear";
    private static final String KEY_VALUE_PROXIMITY = TAG + "_value_proximity";
    private static final String KEY_VALUE_GESTURE = TAG + "_value_gesture";
    private static final String KEY_POS_MODE = TAG + "_pos_mode";

    private SensorDataFetch sensorDataFetch;
    private APDS9960 sensorAPDS9960;

    private ArrayList<Entry> entriesLux;
    private ArrayList<Entry> entriesProximity;

    private LineChart mChartLux;
    private LineChart mChartProximity;
    private Spinner spinnerMode;
    private TextView tvSensorAPDS9960Red;
    private TextView tvSensorAPDS9960Green;
    private TextView tvSensorAPDS9960Blue;
    private TextView tvSensorAPDS9960Clear;
    private TextView tvSensorAPDS9960Proximity;
    private TextView tvSensorAPDS9960Gesture;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        spinnerMode = findViewById(R.id.spinner_sensor_apds9960);

        I2C i2c = getScienceLab().i2c;
        try {
            sensorAPDS9960 = new APDS9960(i2c, getScienceLab());
        } catch (Exception e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorAPDS9960Red = findViewById(R.id.tv_sensor_apds9960_red);
        tvSensorAPDS9960Green = findViewById(R.id.tv_sensor_apds9960_green);
        tvSensorAPDS9960Blue = findViewById(R.id.tv_sensor_apds9960_blue);
        tvSensorAPDS9960Clear = findViewById(R.id.tv_sensor_apds9960_clear);
        tvSensorAPDS9960Proximity = findViewById(R.id.tv_sensor_apds9960_proximity);
        tvSensorAPDS9960Gesture = findViewById(R.id.tv_sensor_apds9960_gesture);
        mChartLux = findViewById(R.id.chart_sensor_apds9960_lux);
        mChartProximity = findViewById(R.id.chart_sensor_apds9960_proximity);

        XAxis xLux = mChartLux.getXAxis();
        YAxis yLux = mChartLux.getAxisLeft();
        YAxis yLux2 = mChartLux.getAxisRight();

        XAxis xProximity = mChartProximity.getXAxis();
        YAxis yProximity = mChartProximity.getAxisLeft();
        YAxis yProximity2 = mChartProximity.getAxisRight();

        mChartLux.setTouchEnabled(true);
        mChartLux.setHighlightPerDragEnabled(true);
        mChartLux.setDragEnabled(true);
        mChartLux.setScaleEnabled(true);
        mChartLux.setDrawGridBackground(false);
        mChartLux.setPinchZoom(true);
        mChartLux.setScaleYEnabled(false);
        mChartLux.setBackgroundColor(Color.BLACK);
        mChartLux.getDescription().setEnabled(false);

        LineData data = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChartLux.setData(data);

        Legend l = mChartLux.getLegend();
        l.setForm(Legend.LegendForm.LINE);
        l.setTextColor(Color.WHITE);

        xLux.setTextColor(Color.WHITE);
        xLux.setDrawGridLines(true);
        xLux.setAvoidFirstLastClipping(true);

        yLux.setTextColor(Color.WHITE);
        yLux.setAxisMaximum(10000f);
        yLux.setAxisMinimum(0);
        yLux.setDrawGridLines(true);
        yLux.setLabelCount(10);

        yLux2.setDrawGridLines(false);

        mChartProximity.setTouchEnabled(true);
        mChartProximity.setHighlightPerDragEnabled(true);
        mChartProximity.setDragEnabled(true);
        mChartProximity.setScaleEnabled(true);
        mChartProximity.setDrawGridBackground(false);
        mChartProximity.setPinchZoom(true);
        mChartProximity.setScaleYEnabled(false);
        mChartProximity.setBackgroundColor(Color.BLACK);
        mChartProximity.getDescription().setEnabled(false);

        LineData data2 = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChartProximity.setData(data2);

        Legend l2 = mChartProximity.getLegend();
        l2.setForm(Legend.LegendForm.LINE);
        l2.setTextColor(Color.WHITE);

        xProximity.setTextColor(Color.WHITE);
        xProximity.setDrawGridLines(true);
        xProximity.setAvoidFirstLastClipping(true);

        yProximity.setTextColor(Color.WHITE);
        yProximity.setAxisMaximum(256f);
        yProximity.setAxisMinimum(0f);
        yProximity.setDrawGridLines(true);
        yProximity.setLabelCount(10);

        yProximity2.setDrawGridLines(false);

        if (savedInstanceState == null) {
            entriesLux = new ArrayList<>();
            entriesProximity = new ArrayList<>();
        } else {
            spinnerMode.setSelection(savedInstanceState.getInt(KEY_POS_MODE));

            tvSensorAPDS9960Red.setText(savedInstanceState.getString(KEY_VALUE_RED));
            tvSensorAPDS9960Green.setText(savedInstanceState.getString(KEY_VALUE_GREEN));
            tvSensorAPDS9960Blue.setText(savedInstanceState.getString(KEY_VALUE_BLUE));
            tvSensorAPDS9960Clear.setText(savedInstanceState.getString(KEY_VALUE_CLEAR));
            tvSensorAPDS9960Proximity.setText(savedInstanceState.getString(KEY_VALUE_PROXIMITY));
            tvSensorAPDS9960Gesture.setText(savedInstanceState.getString(KEY_VALUE_GESTURE));

            entriesLux = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_LUX);
            entriesProximity = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_PROXIMITY);

            sensorDataFetch.updateUi();
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putInt(KEY_POS_MODE, spinnerMode.getSelectedItemPosition());

        outState.putString(KEY_VALUE_RED, tvSensorAPDS9960Red.getText().toString());
        outState.putString(KEY_VALUE_GREEN, tvSensorAPDS9960Green.getText().toString());
        outState.putString(KEY_VALUE_BLUE, tvSensorAPDS9960Blue.getText().toString());
        outState.putString(KEY_VALUE_CLEAR, tvSensorAPDS9960Clear.getText().toString());
        outState.putString(KEY_VALUE_PROXIMITY, tvSensorAPDS9960Proximity.getText().toString());
        outState.putString(KEY_VALUE_GESTURE, tvSensorAPDS9960Gesture.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES_LUX, entriesLux);
        outState.putParcelableArrayList(KEY_ENTRIES_PROXIMITY, entriesProximity);
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private int[] dataAPDS9960Color;
        private double dataAPDS9960Lux;
        private int dataAPDS9960Proximity;
        private int dataAPDS9960Gesture;
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public void getSensorData() {
            try {
                if (sensorAPDS9960 != null) {
                    if (spinnerMode.getSelectedItemPosition() == 0) {
                        sensorAPDS9960.enableGesture(false);
                        sensorAPDS9960.enableColor(true);
                        sensorAPDS9960.enableProximity(true);
                        dataAPDS9960Color = sensorAPDS9960.getColorData();
                        dataAPDS9960Lux = (-0.32466 * dataAPDS9960Color[0]) + (1.57837 * dataAPDS9960Color[1]) + (-0.73191 * dataAPDS9960Color[2]);
                        dataAPDS9960Proximity = sensorAPDS9960.getProximity();
                    } else {
                        sensorAPDS9960.enableColor(false);
                        sensorAPDS9960.enableGesture(true);
                        sensorAPDS9960.enableProximity(true);
                        dataAPDS9960Gesture = sensorAPDS9960.getGesture();
                    }
                }
            } catch (IOException | InterruptedException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }
            timeElapsed = getTimeElapsed();
            entriesLux.add(new Entry(timeElapsed, (float) dataAPDS9960Lux));
            entriesProximity.add(new Entry(timeElapsed, dataAPDS9960Proximity));
        }

        public void updateUi() {
            if (spinnerMode.getSelectedItemPosition() == 0) {

                if (isSensorDataAcquired()) {
                    tvSensorAPDS9960Red.setText(DataFormatter.formatDouble(dataAPDS9960Color[0], DataFormatter.HIGH_PRECISION_FORMAT));
                    tvSensorAPDS9960Green.setText(DataFormatter.formatDouble(dataAPDS9960Color[1], DataFormatter.HIGH_PRECISION_FORMAT));
                    tvSensorAPDS9960Blue.setText(DataFormatter.formatDouble(dataAPDS9960Color[2], DataFormatter.HIGH_PRECISION_FORMAT));
                    tvSensorAPDS9960Clear.setText(DataFormatter.formatDouble(dataAPDS9960Color[3], DataFormatter.HIGH_PRECISION_FORMAT));
                    tvSensorAPDS9960Proximity.setText(DataFormatter.formatDouble(dataAPDS9960Proximity, DataFormatter.HIGH_PRECISION_FORMAT));
                }

                LineDataSet dataSet1 = new LineDataSet(entriesLux, getString(R.string.light_lux));
                LineDataSet dataSet2 = new LineDataSet(entriesProximity, getString(R.string.proximity));

                dataSet1.setDrawCircles(true);
                dataSet2.setDrawCircles(true);

                LineData data = new LineData(dataSet1);
                mChartLux.setData(data);
                mChartLux.notifyDataSetChanged();
                mChartLux.setVisibleXRangeMaximum(10);
                mChartLux.moveViewToX(timeElapsed);

                LineData data2 = new LineData(dataSet2);
                mChartProximity.setData(data2);
                mChartProximity.notifyDataSetChanged();
                mChartProximity.setVisibleXRangeMaximum(10);
                mChartProximity.moveViewToX(timeElapsed);
            } else if (isSensorDataAcquired()) {
                switch (dataAPDS9960Gesture) {
                    case 1:
                        tvSensorAPDS9960Gesture.setText(R.string.up);
                        break;
                    case 2:
                        tvSensorAPDS9960Gesture.setText(R.string.down);
                        break;
                    case 3:
                        tvSensorAPDS9960Gesture.setText(R.string.left);
                        break;
                    case 4:
                        tvSensorAPDS9960Gesture.setText(R.string.right);
                        break;
                    default:
                        break;
                }
            }
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    @Override
    protected int getLayoutResId() {
        return R.layout.sensor_apds9960;
    }

    @Override
    protected int getTitleResId() {
        return R.string.apds9960;
    }
}
