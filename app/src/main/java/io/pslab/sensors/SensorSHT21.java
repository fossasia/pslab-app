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

        initChart(mChartTemperature);
        initChart(mChartHumidity);

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

            LineDataSet dataSetTemperature = new LineDataSet(entriesTemperature, getString(R.string.temperature));
            LineDataSet dataSetHumidity = new LineDataSet(entriesHumidity, getString(R.string.humidity));

            updateChart(mChartTemperature, timeElapsed, dataSetTemperature);
            updateChart(mChartHumidity, timeElapsed, dataSetHumidity);
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
