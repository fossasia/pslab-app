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

import io.pslab.R;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.VL53L0X;

public class SensorVL53L0X extends AbstractSensorActivity {
    private static final String TAG = SensorVL53L0X.class.getSimpleName();

    private static final String KEY_ENTRIES = TAG + "_entries";
    private static final String KEY_VALUE = TAG + "_value";

    private SensorDataFetch sensorDataFetch;
    private VL53L0X sensorVL53L0X;

    private ArrayList<Entry> entries;

    private LineChart mChart;
    private TextView tvSensorVL53L0X;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        I2C i2c = getScienceLab().i2c;
        try {
            sensorVL53L0X = new VL53L0X(i2c, getScienceLab());
        } catch (Exception e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorVL53L0X = findViewById(R.id.tv_sensor_vl53l0x);
        mChart = findViewById(R.id.chart_sensor_ads);
        XAxis x = mChart.getXAxis();
        YAxis y = mChart.getAxisLeft();
        YAxis y2 = mChart.getAxisRight();

        mChart.setTouchEnabled(true);
        mChart.setHighlightPerDragEnabled(true);
        mChart.setDragEnabled(true);
        mChart.setScaleEnabled(true);
        mChart.setDrawGridBackground(false);
        mChart.setPinchZoom(true);
        mChart.setScaleYEnabled(false);
        mChart.setBackgroundColor(Color.BLACK);
        mChart.getDescription().setEnabled(false);

        LineData data = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChart.setData(data);

        Legend l = mChart.getLegend();
        l.setForm(Legend.LegendForm.LINE);
        l.setTextColor(Color.WHITE);

        x.setTextColor(Color.WHITE);
        x.setDrawGridLines(true);
        x.setAvoidFirstLastClipping(true);

        y.setTextColor(Color.WHITE);
        y.setAxisMaximum(10000f);
        y.setAxisMinimum(0);
        y.setDrawGridLines(true);
        y.setLabelCount(10);

        y2.setDrawGridLines(false);

        if (savedInstanceState == null) {
            entries = new ArrayList<>();
        } else {
            tvSensorVL53L0X.setText(savedInstanceState.getString(KEY_VALUE));

            entries = savedInstanceState.getParcelableArrayList(KEY_ENTRIES);

            sensorDataFetch.updateUi();
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putString(KEY_VALUE, tvSensorVL53L0X.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES, entries);
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private int dataVL53L0X;
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public void getSensorData() {
            try {
                if (sensorVL53L0X != null) {
                    dataVL53L0X = sensorVL53L0X.getRaw();
                }
            } catch (IOException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }

            timeElapsed = getTimeElapsed();
            entries.add(new Entry(timeElapsed, (float) dataVL53L0X));
        }

        public void updateUi() {

            if (isSensorDataAcquired()) {
                tvSensorVL53L0X.setText(String.valueOf(dataVL53L0X));
            }

            LineDataSet dataSet = new LineDataSet(entries, getString(R.string.bx));
            dataSet.setDrawCircles(true);
            LineData data = new LineData(dataSet);
            mChart.setData(data);
            mChart.notifyDataSetChanged();
            mChart.setVisibleXRangeMaximum(10);
            mChart.moveViewToX(timeElapsed);
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    @Override
    protected int getLayoutResId() {
        return R.layout.sensor_vl53l0x;
    }

    @Override
    protected int getTitleResId() {
        return R.string.vl53l0x;
    }
}
