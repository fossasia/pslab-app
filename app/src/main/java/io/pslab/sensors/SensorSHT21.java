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
import java.util.List;

import io.pslab.DataFormatter;
import io.pslab.R;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.SHT21;

public class SensorSHT21 extends AbstractSensorActivity {
    private static final String TAG = SensorSHT21.class.getSimpleName();

    private static final String KEY_ENTRIES_TEMPERATURE = TAG + "_entries_temperature";
    private static final String KEY_ENTRIES_HUMIDITY = TAG + "_entries_humidity";
    private static final String KEY_VALUE_TEMP = TAG + "_value_temperature";
    private static final String KEY_VALUE_HUMIDITY = TAG + "_value_humidity";

    private SensorDataFetch sensorDataFetch;
    private SHT21 sensorSHT21;

    private ArrayList<Entry> entriesTemperature;
    private ArrayList<Entry> entriesHumidity;

    private LineChart mChartTemperature;
    private LineChart mChartHumidity;
    private TextView tvSensorSHT21Temp;
    private TextView tvSensorSHT21Humidity;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        I2C i2c = getScienceLab().i2c;
        try {
            sensorSHT21 = new SHT21(i2c, getScienceLab());
        } catch (IOException | InterruptedException e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorSHT21Temp = findViewById(R.id.tv_sensor_sht21_temp);
        tvSensorSHT21Humidity = findViewById(R.id.tv_sensor_sht21_humidity);
        mChartTemperature = findViewById(R.id.chart_temperature_sht21);
        mChartHumidity = findViewById(R.id.chart_humidity_sht21);

        XAxis xTemperature = mChartTemperature.getXAxis();
        YAxis yTemperature = mChartTemperature.getAxisLeft();
        YAxis yTemperature2 = mChartTemperature.getAxisRight();

        XAxis xHumidity = mChartHumidity.getXAxis();
        YAxis yHumidity = mChartHumidity.getAxisLeft();
        YAxis yHumidity2 = mChartHumidity.getAxisRight();

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
        yTemperature.setAxisMaximum(125f);
        yTemperature.setAxisMinimum(-40f);
        yTemperature.setDrawGridLines(true);
        yTemperature.setLabelCount(10);

        yTemperature2.setDrawGridLines(false);

        mChartHumidity.setTouchEnabled(true);
        mChartHumidity.setHighlightPerDragEnabled(true);
        mChartHumidity.setDragEnabled(true);
        mChartHumidity.setScaleEnabled(true);
        mChartHumidity.setDrawGridBackground(false);
        mChartHumidity.setPinchZoom(true);
        mChartHumidity.setScaleYEnabled(false);
        mChartHumidity.setBackgroundColor(Color.BLACK);
        mChartHumidity.getDescription().setEnabled(false);

        LineData data2 = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChartHumidity.setData(data2);

        Legend l2 = mChartHumidity.getLegend();
        l2.setForm(Legend.LegendForm.LINE);
        l2.setTextColor(Color.WHITE);

        xHumidity.setTextColor(Color.WHITE);
        xHumidity.setDrawGridLines(true);
        xHumidity.setAvoidFirstLastClipping(true);

        yHumidity.setTextColor(Color.WHITE);
        yHumidity.setAxisMaximum(100f);
        yHumidity.setAxisMinimum(0f);
        yHumidity.setDrawGridLines(true);
        yHumidity.setLabelCount(10);

        yHumidity2.setDrawGridLines(false);

        if (savedInstanceState == null) {
            entriesTemperature = new ArrayList<>();
            entriesHumidity = new ArrayList<>();
        } else {
            tvSensorSHT21Temp.setText(savedInstanceState.getString(KEY_VALUE_TEMP));
            tvSensorSHT21Humidity.setText(savedInstanceState.getString(KEY_VALUE_HUMIDITY));

            entriesTemperature = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_TEMPERATURE);
            entriesHumidity = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_HUMIDITY);

            sensorDataFetch.updateUi();
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putString(KEY_VALUE_TEMP, tvSensorSHT21Temp.getText().toString());
        outState.putString(KEY_VALUE_HUMIDITY, tvSensorSHT21Humidity.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES_TEMPERATURE, entriesTemperature);
        outState.putParcelableArrayList(KEY_ENTRIES_HUMIDITY, entriesHumidity);
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private List<Double> dataSHT21Temp = new ArrayList<>();
        private List<Double> dataSHT21Humidity = new ArrayList<>();
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public void getSensorData() {
            try {
                if (sensorSHT21 != null) {
                    sensorSHT21.selectParameter("temperature");
                    dataSHT21Temp = sensorSHT21.getRaw();
                    sensorSHT21.selectParameter("humidity");
                    dataSHT21Humidity = sensorSHT21.getRaw();
                }
            } catch (IOException | InterruptedException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }
            timeElapsed = getTimeElapsed();
            entriesTemperature.add(new Entry(timeElapsed, dataSHT21Temp.get(0).floatValue()));
            entriesTemperature.add(new Entry(timeElapsed, dataSHT21Humidity.get(0).floatValue()));
        }

        public void updateUi() {

            if (isSensorDataAcquired()) {
                tvSensorSHT21Temp.setText(DataFormatter.formatDouble(dataSHT21Temp.get(0), DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorSHT21Humidity.setText(DataFormatter.formatDouble(dataSHT21Humidity.get(0), DataFormatter.HIGH_PRECISION_FORMAT));
            }

            LineDataSet dataSet1 = new LineDataSet(entriesTemperature, getString(R.string.temperature));
            LineDataSet dataSet2 = new LineDataSet(entriesHumidity, getString(R.string.humidity));

            dataSet1.setDrawCircles(true);
            dataSet2.setDrawCircles(true);

            LineData data = new LineData(dataSet1);
            mChartTemperature.setData(data);
            mChartTemperature.notifyDataSetChanged();
            mChartTemperature.setVisibleXRangeMaximum(10);
            mChartTemperature.moveViewToX(timeElapsed);

            LineData data2 = new LineData(dataSet2);
            mChartHumidity.setData(data2);
            mChartHumidity.notifyDataSetChanged();
            mChartHumidity.setVisibleXRangeMaximum(10);
            mChartHumidity.moveViewToX(timeElapsed);
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    @Override
    protected int getLayoutResId() {
        return R.layout.sensor_sht21;
    }

    @Override
    protected int getTitleResId() {
        return R.string.sht21;
    }
}
