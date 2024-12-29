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
import java.util.List;

import io.pslab.DataFormatter;
import io.pslab.R;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.HMC5883L;

public class SensorHMC5883L extends AbstractSensorActivity {
    private static final String TAG = SensorHMC5883L.class.getSimpleName();

    private static final String KEY_ENTRIES_BX = TAG + "_entries_bx";
    private static final String KEY_ENTRIES_BY = TAG + "_entries_by";
    private static final String KEY_ENTRIES_BZ = TAG + "_entries_bz";
    private static final String KEY_VALUE_BX = TAG + "_value_bx";
    private static final String KEY_VALUE_BY = TAG + "_value_by";
    private static final String KEY_VALUE_BZ = TAG + "_value_bz";

    private SensorDataFetch sensorDataFetch;
    private HMC5883L sensorHMC5883L;

    private ArrayList<Entry> entriesBx;
    private ArrayList<Entry> entriesBy;
    private ArrayList<Entry> entriesBz;

    private LineChart mChart;
    private TextView tvSensorHMC5883Lbx;
    private TextView tvSensorHMC5883Lby;
    private TextView tvSensorHMC5883Lbz;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        I2C i2c = getScienceLab().i2c;
        try {
            sensorHMC5883L = new HMC5883L(i2c, getScienceLab());
        } catch (IOException e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorHMC5883Lbx = findViewById(R.id.tv_sensor_hmc5883l_bx);
        tvSensorHMC5883Lby = findViewById(R.id.tv_sensor_hmc5883l_by);
        tvSensorHMC5883Lbz = findViewById(R.id.tv_sensor_hmc5883l_bz);
        mChart = findViewById(R.id.chart_hmc5883l);

        initChart(mChart);

        if (savedInstanceState == null) {
            entriesBx = new ArrayList<>();
            entriesBy = new ArrayList<>();
            entriesBz = new ArrayList<>();
        } else {
            tvSensorHMC5883Lbx.setText(savedInstanceState.getString(KEY_VALUE_BX));
            tvSensorHMC5883Lby.setText(savedInstanceState.getString(KEY_VALUE_BY));
            tvSensorHMC5883Lbz.setText(savedInstanceState.getString(KEY_VALUE_BZ));

            entriesBx = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_BX);
            entriesBy = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_BY);
            entriesBz = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_BZ);

            sensorDataFetch.updateUi();
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putString(KEY_VALUE_BX, tvSensorHMC5883Lbx.getText().toString());
        outState.putString(KEY_VALUE_BY, tvSensorHMC5883Lby.getText().toString());
        outState.putString(KEY_VALUE_BZ, tvSensorHMC5883Lbz.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES_BX, entriesBx);
        outState.putParcelableArrayList(KEY_ENTRIES_BY, entriesBy);
        outState.putParcelableArrayList(KEY_ENTRIES_BZ, entriesBz);
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private List<Double> dataHMC5883L = new ArrayList<>();
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public void getSensorData() {
            try {
                if (sensorHMC5883L != null) {
                    dataHMC5883L = sensorHMC5883L.getRaw();
                }
            } catch (IOException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }

            timeElapsed = getTimeElapsed();
            entriesBx.add(new Entry(timeElapsed, dataHMC5883L.get(0).floatValue()));
            entriesBy.add(new Entry(timeElapsed, dataHMC5883L.get(1).floatValue()));
            entriesBz.add(new Entry(timeElapsed, dataHMC5883L.get(2).floatValue()));
        }

        public void updateUi() {

            if (isSensorDataAcquired()) {
                tvSensorHMC5883Lbx.setText(DataFormatter.formatDouble(dataHMC5883L.get(0), DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorHMC5883Lby.setText(DataFormatter.formatDouble(dataHMC5883L.get(1), DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorHMC5883Lbz.setText(DataFormatter.formatDouble(dataHMC5883L.get(2), DataFormatter.HIGH_PRECISION_FORMAT));
            }

            LineDataSet dataSetBx = new LineDataSet(entriesBx, getString(R.string.bx));
            LineDataSet dataSetBy = new LineDataSet(entriesBy, getString(R.string.by));
            LineDataSet dataSetBz = new LineDataSet(entriesBz, getString(R.string.bz));

            dataSetBx.setColor(Color.BLUE);
            dataSetBy.setColor(Color.GREEN);
            dataSetBz.setColor(Color.RED);

            updateChart(mChart, timeElapsed, dataSetBx, dataSetBy, dataSetBz);
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    @Override
    protected int getLayoutResId() {
        return R.layout.sensor_hmc5883l;
    }

    @Override
    protected int getTitleResId() {
        return R.string.hmc5883l;
    }
}
