package io.pslab.sensors;

import android.annotation.SuppressLint;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;

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
import io.pslab.communication.sensors.MLX90614;


public class SensorMLX90614 extends AbstractSensorActivity {
    private static final String TAG = SensorMLX90614.class.getSimpleName();

    private static final String KEY_ENTRIES_OBJ_TEMP = TAG + "_entries_object_temperature";
    private static final String KEY_ENTRIES_AMB_TEMP = TAG + "_entries_ambient_temperature";
    private static final String KEY_VALUE_OBJ_TEMP = TAG + "_value_object_temperature";
    private static final String KEY_VALUE_AMB_TEMP = TAG + "_value_ambient_temperature";

    private static final String PREF_NAME = "SensorMLX90614";
    private static final String KEY = "SensorMLX90614Key";

    private SensorDataFetch sensorDataFetch;
    private MLX90614 sensorMLX90614;

    private ArrayList<Entry> entriesObjectTemperature;
    private ArrayList<Entry> entriesAmbientTemperature;

    private LineChart mChartObjectTemperature;
    private LineChart mChartAmbientTemperature;
    private TextView tvSensorMLX90614ObjectTemp;
    private TextView tvSensorMLX90614AmbientTemp;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        howToConnectDialog(getString(R.string.ir_thermometer), getString(R.string.ir_thermometer_intro), R.drawable.mlx90614_schematic, getString(R.string.ir_thermometer_desc));

        I2C i2c = getScienceLab().i2c;
        try {
            sensorMLX90614 = new MLX90614(i2c);
        } catch (IOException e) {
            Log.e(TAG, "Sensor initialization failed.", e);
        }

        sensorDataFetch = new SensorDataFetch();

        tvSensorMLX90614ObjectTemp = findViewById(R.id.tv_sensor_mlx90614_object_temp);
        tvSensorMLX90614AmbientTemp = findViewById(R.id.tv_sensor_mlx90614_ambient_temp);

        mChartObjectTemperature = findViewById(R.id.chart_obj_temp_mlx);
        mChartAmbientTemperature = findViewById(R.id.chart_amb_temp_mlx);

        XAxis xObjectTemperature = mChartObjectTemperature.getXAxis();
        YAxis yObjectTemperature = mChartObjectTemperature.getAxisLeft();
        YAxis yObjectTemperature2 = mChartObjectTemperature.getAxisRight();

        XAxis xAmbientTemperature = mChartAmbientTemperature.getXAxis();
        YAxis yAmbientTemperature = mChartAmbientTemperature.getAxisLeft();
        YAxis yAmbientTemperature2 = mChartAmbientTemperature.getAxisRight();

        mChartObjectTemperature.setTouchEnabled(true);
        mChartObjectTemperature.setHighlightPerDragEnabled(true);
        mChartObjectTemperature.setDragEnabled(true);
        mChartObjectTemperature.setScaleEnabled(true);
        mChartObjectTemperature.setDrawGridBackground(false);
        mChartObjectTemperature.setPinchZoom(true);
        mChartObjectTemperature.setScaleYEnabled(false);
        mChartObjectTemperature.setBackgroundColor(Color.BLACK);
        mChartObjectTemperature.getDescription().setEnabled(false);

        LineData data = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChartObjectTemperature.setData(data);

        Legend l = mChartObjectTemperature.getLegend();
        l.setForm(Legend.LegendForm.LINE);
        l.setTextColor(Color.WHITE);

        xObjectTemperature.setTextColor(Color.WHITE);
        xObjectTemperature.setDrawGridLines(true);
        xObjectTemperature.setAvoidFirstLastClipping(true);

        yObjectTemperature.setTextColor(Color.WHITE);
        yObjectTemperature.setAxisMaximum(125f);
        yObjectTemperature.setAxisMinimum(-40f);
        yObjectTemperature.setDrawGridLines(true);
        yObjectTemperature.setLabelCount(10);

        yObjectTemperature2.setDrawGridLines(false);

        mChartAmbientTemperature.setTouchEnabled(true);
        mChartAmbientTemperature.setHighlightPerDragEnabled(true);
        mChartAmbientTemperature.setDragEnabled(true);
        mChartAmbientTemperature.setScaleEnabled(true);
        mChartAmbientTemperature.setDrawGridBackground(false);
        mChartAmbientTemperature.setPinchZoom(true);
        mChartAmbientTemperature.setScaleYEnabled(false);
        mChartAmbientTemperature.setBackgroundColor(Color.BLACK);
        mChartAmbientTemperature.getDescription().setEnabled(false);

        LineData data2 = new LineData();
        data.setValueTextColor(Color.WHITE);
        mChartAmbientTemperature.setData(data2);

        Legend l2 = mChartAmbientTemperature.getLegend();
        l2.setForm(Legend.LegendForm.LINE);
        l2.setTextColor(Color.WHITE);

        xAmbientTemperature.setTextColor(Color.WHITE);
        xAmbientTemperature.setDrawGridLines(true);
        xAmbientTemperature.setAvoidFirstLastClipping(true);

        yAmbientTemperature.setTextColor(Color.WHITE);
        yAmbientTemperature.setAxisMaximum(380f);
        yAmbientTemperature.setAxisMinimum(-70f);
        yAmbientTemperature.setDrawGridLines(true);
        yAmbientTemperature.setLabelCount(10);

        yAmbientTemperature2.setDrawGridLines(false);

        if (savedInstanceState == null) {
            entriesObjectTemperature = new ArrayList<>();
            entriesAmbientTemperature = new ArrayList<>();
        } else {
            tvSensorMLX90614ObjectTemp.setText(savedInstanceState.getString(KEY_VALUE_OBJ_TEMP));
            tvSensorMLX90614AmbientTemp.setText(savedInstanceState.getString(KEY_VALUE_AMB_TEMP));

            entriesObjectTemperature = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_OBJ_TEMP);
            entriesAmbientTemperature = savedInstanceState.getParcelableArrayList(KEY_ENTRIES_AMB_TEMP);

            sensorDataFetch.updateUi();
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putString(KEY_VALUE_OBJ_TEMP, tvSensorMLX90614ObjectTemp.getText().toString());
        outState.putString(KEY_VALUE_AMB_TEMP, tvSensorMLX90614AmbientTemp.getText().toString());

        outState.putParcelableArrayList(KEY_ENTRIES_OBJ_TEMP, entriesObjectTemperature);
        outState.putParcelableArrayList(KEY_ENTRIES_AMB_TEMP, entriesAmbientTemperature);
    }

    @SuppressLint("ResourceType")
    public void howToConnectDialog(String title, String intro, int imageID, String desc) {
        try {
            final AlertDialog.Builder builder = new AlertDialog.Builder(this);
            LayoutInflater inflater = getLayoutInflater();
            View dialogView = inflater.inflate(R.layout.custom_dialog_box, null);
            builder.setView(dialogView);
            builder.setTitle(title);

            final TextView dialogText = dialogView.findViewById(R.id.custom_dialog_text);
            final TextView dialogDesc = dialogView.findViewById(R.id.description_text);
            final ImageView dialogImage = dialogView.findViewById(R.id.custom_dialog_schematic);
            final CheckBox doNotShowDialog = dialogView.findViewById(R.id.toggle_show_again);
            final Button okButton = dialogView.findViewById(R.id.dismiss_button);
            dialogText.setText(intro);
            dialogImage.setImageResource(imageID);
            dialogDesc.setText(desc);

            final SharedPreferences sharedPreferences = this.getSharedPreferences(PREF_NAME, MODE_PRIVATE);
            final AlertDialog dialog = builder.create();
            boolean skipDialog = sharedPreferences.getBoolean(KEY, false);
            okButton.setOnClickListener(v -> {
                if (doNotShowDialog.isChecked()) {
                    SharedPreferences.Editor editor = sharedPreferences.edit();
                    editor.putBoolean(KEY, true);
                    editor.apply();
                }
                dialog.dismiss();
            });
            if (!skipDialog) {
                dialog.show();
            }
        } catch (Exception e) {
            Log.e(TAG, "Error showing dialog.", e);
        }
    }

    private class SensorDataFetch extends AbstractSensorActivity.SensorDataFetch {

        private Double dataMLX90614ObjectTemp;
        private Double dataMLX90614AmbientTemp;
        /* Initialization required if updateUi is executed before getSensorData */
        private float timeElapsed = getTimeElapsed();

        @Override
        public void getSensorData() {
            try {
                if (sensorMLX90614 != null) {
                    dataMLX90614ObjectTemp = sensorMLX90614.getObjectTemperature();
                    dataMLX90614AmbientTemp = sensorMLX90614.getAmbientTemperature();
                }
            } catch (IOException e) {
                Log.e(TAG, "Error getting sensor data.", e);
            }

            timeElapsed = getTimeElapsed();
            entriesObjectTemperature.add(new Entry(timeElapsed, dataMLX90614ObjectTemp.floatValue()));
            entriesAmbientTemperature.add(new Entry(timeElapsed, dataMLX90614AmbientTemp.floatValue()));
        }

        public void updateUi() {

            if (isSensorDataAcquired()) {
                tvSensorMLX90614ObjectTemp.setText(DataFormatter.formatDouble(dataMLX90614ObjectTemp, DataFormatter.HIGH_PRECISION_FORMAT));
                tvSensorMLX90614AmbientTemp.setText(DataFormatter.formatDouble(dataMLX90614AmbientTemp, DataFormatter.HIGH_PRECISION_FORMAT));
            }

            LineDataSet dataSet1 = new LineDataSet(entriesObjectTemperature, getString(R.string.object_temp));
            LineDataSet dataSet2 = new LineDataSet(entriesAmbientTemperature, getString(R.string.ambient_temp));

            dataSet1.setDrawCircles(true);
            dataSet2.setDrawCircles(true);

            LineData data1 = new LineData(dataSet1);
            mChartObjectTemperature.setData(data1);
            mChartObjectTemperature.notifyDataSetChanged();
            mChartObjectTemperature.setVisibleXRangeMaximum(10);
            mChartObjectTemperature.moveViewToX(timeElapsed);

            LineData data2 = new LineData(dataSet2);
            mChartAmbientTemperature.setData(data2);
            mChartAmbientTemperature.notifyDataSetChanged();
            mChartAmbientTemperature.setVisibleXRangeMaximum(10);
            mChartAmbientTemperature.moveViewToX(timeElapsed);
        }
    }

    @Override
    protected AbstractSensorActivity.SensorDataFetch getSensorDataFetch() {
        return sensorDataFetch;
    }

    @Override
    protected int getLayoutResId() {
        return R.layout.sensor_mlx90614;
    }

    @Override
    protected int getTitleResId() {
        return R.string.mlx90614;
    }
}
