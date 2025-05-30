package io.pslab.fragment;

import android.graphics.Bitmap;
import android.graphics.Color;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.location.Location;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import androidx.annotation.NonNull;

import com.google.android.material.snackbar.Snackbar;
import androidx.fragment.app.Fragment;

import androidx.preference.PreferenceManager;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.github.anastr.speedviewlib.PointerSpeedometer;
import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.components.Legend;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.data.LineDataSet;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;
import java.util.Timer;
import java.util.TimerTask;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.Unbinder;
import io.pslab.DataFormatter;
import io.pslab.R;
import io.pslab.activity.LuxMeterActivity;
import io.pslab.communication.ScienceLab;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.BH1750;
import io.pslab.communication.sensors.TSL2561;
import io.pslab.interfaces.OperationCallback;
import io.pslab.models.LuxData;
import io.pslab.models.PSLabSensor;
import io.pslab.models.SensorDataBlock;
import io.pslab.others.CSVDataLine;
import io.pslab.others.CSVLogger;
import io.pslab.others.CustomSnackBar;
import io.pslab.others.ScienceLabCommon;

import static android.content.Context.SENSOR_SERVICE;
import static io.pslab.others.CSVLogger.CSV_DIRECTORY;

/**
 * Created by Padmal on 11/2/18.
 */

public class LuxMeterDataFragment extends Fragment implements OperationCallback {

    private static final CSVDataLine CSV_HEADER =
            new CSVDataLine()
                    .add("Timestamp")
                    .add("DateTime")
                    .add("Readings")
                    .add("Latitude")
                    .add("Longitude");

    private static int sensorType = 0;
    private static int highLimit = 2000;
    private static int updatePeriod = 100;
    private static int gain = 1;
    private long timeElapsed;
    private int count = 0, turns = 0;
    private float sum = 0;
    private boolean returningFromPause = false;

    private float luxValue = -1;

    private enum LUX_SENSOR {INBUILT_SENSOR, BH1750_SENSOR, TSL2561_SENSOR}

    @BindView(R.id.lux_max)
    TextView statMax;
    @BindView(R.id.lux_min)
    TextView statMin;
    @BindView(R.id.lux_avg)
    TextView statMean;
    @BindView(R.id.label_lux_sensor)
    TextView sensorLabel;
    @BindView(R.id.chart_lux_meter)
    LineChart mChart;
    @BindView(R.id.light_meter)
    PointerSpeedometer lightMeter;

    private Timer graphTimer;
    private SensorManager sensorManager;
    private Sensor sensor;
    private long startTime, block;
    private ArrayList<Entry> entries;
    private ArrayList<LuxData> recordedLuxArray;
    private LuxData sensorData;
    private YAxis y;
    private Unbinder unbinder;
    private long previousTimeElapsed = (System.currentTimeMillis() - startTime) / updatePeriod;
    private LuxMeterActivity luxSensor;
    private View rootView;

    public static LuxMeterDataFragment newInstance() {
        return new LuxMeterDataFragment();
    }

    public static void setParameters(int highLimit, int updatePeriod, String type, String gain) {
        LuxMeterDataFragment.highLimit = highLimit;
        LuxMeterDataFragment.updatePeriod = updatePeriod;
        LuxMeterDataFragment.sensorType = Integer.valueOf(type);
        LuxMeterDataFragment.gain = Integer.valueOf(gain);
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        startTime = System.currentTimeMillis();
        entries = new ArrayList<>();
        luxSensor = (LuxMeterActivity) getActivity();
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.fragment_lux_meter_data, container, false);
        unbinder = ButterKnife.bind(this, rootView);
        setupInstruments();
        return rootView;
    }

    @Override
    public void onResume() {
        super.onResume();
        if (luxSensor.playingData) {
            sensorLabel.setText(getResources().getString(R.string.lux_meter));
            recordedLuxArray = new ArrayList<>();
            resetInstrumentData();
            playRecordedData();
        } else if (luxSensor.viewingData) {
            sensorLabel.setText(getResources().getString(R.string.lux_meter));
            recordedLuxArray = new ArrayList<>();
            resetInstrumentData();
            plotAllRecordedData();
        } else if (!luxSensor.isRecording) {
            updateGraphs();
            sum = 0;
            count = 0;
            // REMOVE these fixed axis values to allow auto-scaling
            // currentMin = 10000;
            // currentMax = 0;
            entries.clear();
            mChart.clear();
            mChart.invalidate();
             // Auto-scaling: reset min/max if using MPAndroidChart
             mChart.getAxisLeft().resetAxisMinimum();
             mChart.getAxisLeft().resetAxisMaximum();
             mChart.getAxisRight().resetAxisMinimum();
             mChart.getAxisRight().resetAxisMaximum();
             initiateBaroSensor(sensorType);
            initiateLuxSensor(sensorType);
        } else if (returningFromPause) {
            updateGraphs();
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        if (graphTimer != null) {
            graphTimer.cancel();
        }
        if (sensorManager != null) {
            sensorManager.unregisterListener(lightSensorEventListener);
        }
        unbinder.unbind();
    }

    private void plotAllRecordedData() {
        recordedLuxArray.addAll(luxSensor.recordedLuxData);
        if (recordedLuxArray.size() != 0) {
            for (LuxData d : recordedLuxArray) {
                if (currentMax < d.getLux()) {
                    currentMax = d.getLux();
                }
                if (currentMin > d.getLux()) {
                    currentMin = d.getLux();
                }
                Entry entry = new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getLux());
                entries.add(entry);
                lightMeter.setWithTremble(false);
                lightMeter.setSpeedAt(d.getLux());
                sum += entry.getY();
            }
            y.setAxisMaximum(currentMax);
            y.setAxisMinimum(currentMin);
            y.setLabelCount(10);
            statMax.setText(String.format(Locale.getDefault(), PSLabSensor.LUXMETER_DATA_FORMAT, currentMax));
            statMin.setText(String.format(Locale.getDefault(), PSLabSensor.LUXMETER_DATA_FORMAT, currentMin));
            statMean.setText(String.format(Locale.getDefault(), PSLabSensor.LUXMETER_DATA_FORMAT, (sum / recordedLuxArray.size())));

            LineDataSet dataSet = new LineDataSet(entries, getString(R.string.lux));
            dataSet.setDrawCircles(false);
            dataSet.setDrawValues(false);
            dataSet.setLineWidth(2);
            LineData data = new LineData(dataSet);

            mChart.setData(data);
            mChart.notifyDataSetChanged();
            mChart.setVisibleXRangeMaximum(80);
            mChart.moveViewToX(data.getEntryCount());
            mChart.invalidate();
        }
    }

    private void playRecordedData() {
        recordedLuxArray.addAll(luxSensor.recordedLuxData);
        try {
            if (recordedLuxArray.size() > 1) {
                LuxData i = recordedLuxArray.get(1);
                long timeGap = i.getTime() - i.getBlock();
                processRecordedData(timeGap);
            } else {
                processRecordedData(0);
            }
        } catch (IllegalArgumentException e) {
            CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                    getString(R.string.no_data_fetched), null, null, Snackbar.LENGTH_SHORT);
        }
    }

    private void processRecordedData(long timeGap) {
        final Handler handler = new Handler();
        if (graphTimer != null) {
            graphTimer.cancel();
        } else {
            graphTimer = new Timer();
        }
        graphTimer.schedule(new TimerTask() {
            @Override
            public void run() {
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        if (luxSensor.playingData) {
                            try {
                                LuxData d = recordedLuxArray.get(turns);
                                turns++;
                                if (currentMax < d.getLux()) {
                                    currentMax = d.getLux();
                                    statMax.setText(String.format(Locale.getDefault(), PSLabSensor.LUXMETER_DATA_FORMAT, d.getLux()));
                                }
                                if (currentMin > d.getLux()) {
                                    currentMin = d.getLux();
                                    statMin.setText(String.format(Locale.getDefault(), PSLabSensor.LUXMETER_DATA_FORMAT, d.getLux()));
                                }
                                y.setAxisMaximum(currentMax);
                                y.setAxisMinimum(currentMin);
                                y.setLabelCount(10);
                                lightMeter.setWithTremble(false);
                                lightMeter.setSpeedAt(d.getLux());

                                Entry entry = new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getLux());
                                entries.add(entry);
                                count++;
                                sum += entry.getY();
                                statMean.setText(DataFormatter.formatDouble((sum / count), PSLabSensor.LUXMETER_DATA_FORMAT));

                                LineDataSet dataSet = new LineDataSet(entries, getString(R.string.lux));
                                dataSet.setDrawCircles(false);
                                dataSet.setDrawValues(false);
                                dataSet.setLineWidth(2);
                                LineData data = new LineData(dataSet);

                                mChart.setData(data);
                                mChart.notifyDataSetChanged();
                                mChart.setVisibleXRangeMaximum(80);
                                mChart.moveViewToX(data.getEntryCount());
                                mChart.invalidate();
                            } catch (IndexOutOfBoundsException e) {
                                graphTimer.cancel();
                                graphTimer = null;
                                turns = 0;
                                luxSensor.playingData = false;
                                luxSensor.startedPlay = false;
                                luxSensor.invalidateOptionsMenu();
                            }
                        }
                    }
                });
            }
        }, 0, timeGap);
    }

    @Override
    public void stopData() {
        if (graphTimer != null) {
            graphTimer.cancel();
            graphTimer = null;
        }
        recordedLuxArray.clear();
        entries.clear();
        plotAllRecordedData();
        luxSensor.startedPlay = false;
        luxSensor.playingData = false;
        turns = 0;
        luxSensor.invalidateOptionsMenu();
    }

    @Override
    public void playData() {
        resetInstrumentData();
        luxSensor.startedPlay = true;
        try {
            if (recordedLuxArray.size() > 1) {
                LuxData i = recordedLuxArray.get(1);
                long timeGap = i.getTime() - i.getBlock();
                processRecordedData(timeGap);
            } else {
                processRecordedData(0);
            }
        } catch (IllegalArgumentException e) {
            CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                    getString(R.string.no_data_fetched), null, null, Snackbar.LENGTH_SHORT);
        }
    }

    @Override
    public void saveGraph() {
        luxSensor.csvLogger.prepareLogFile();
        luxSensor.csvLogger.writeMetaData(getResources().getString(R.string.lux_meter));
        luxSensor.csvLogger.writeCSVFile(CSV_HEADER);
        for (LuxData luxData : luxSensor.recordedLuxData) {
            luxSensor.csvLogger.writeCSVFile(
                    new CSVDataLine()
                            .add(luxData.getTime())
                            .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(luxData.getTime())))
                            .add(luxData.getLux())
                            .add(luxData.getLat())
                            .add(luxData.getLon())
            );
        }
        View view = rootView.findViewById(R.id.luxmeter_linearlayout);
        view.setDrawingCacheEnabled(true);
        Bitmap b = view.getDrawingCache();
        try {
            b.compress(Bitmap.CompressFormat.JPEG, 100, new FileOutputStream(Environment.getExternalStorageDirectory().getAbsolutePath() +
                    File.separator + CSV_DIRECTORY + File.separator + luxSensor.getSensorName() +
                    File.separator + CSVLogger.FILE_NAME_FORMAT.format(new Date()) + "_graph.jpg"));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
    }


    private void setupInstruments() {
        lightMeter.setMaxSpeed(PreferenceManager.getDefaultSharedPreferences(getActivity()).getFloat(luxSensor.LUXMETER_LIMIT, 10000));

        XAxis x = mChart.getXAxis();
        this.y = mChart.getAxisLeft();
        YAxis y2 = mChart.getAxisRight();

        mChart.setTouchEnabled(true);
        mChart.setHighlightPerDragEnabled(true);
        mChart.setDragEnabled(true);
        mChart.setScaleEnabled(true);
        mChart.setDrawGridBackground(false);
        mChart.setPinchZoom(true);
        mChart.setScaleYEnabled(true);
        mChart.setBackgroundColor(Color.BLACK);
        mChart.getDescription().setEnabled(false);

        LineData data = new LineData();
        mChart.setData(data);

        Legend l = mChart.getLegend();
        l.setForm(Legend.LegendForm.LINE);
        l.setTextColor(Color.WHITE);

        x.setTextColor(Color.WHITE);
        x.setDrawGridLines(true);
        x.setAvoidFirstLastClipping(true);

        y.setTextColor(Color.WHITE);
        y.setAxisMaximum(currentMax);
        y.setAxisMinimum(currentMin);
        y.setDrawGridLines(true);
        y.setLabelCount(10);

        y2.setDrawGridLines(false);
    }

    @Override
    public void onPause() {
        super.onPause();
        if (graphTimer != null) {
            returningFromPause = true;
            graphTimer.cancel();
            graphTimer = null;
            if (luxSensor.playingData) {
                luxSensor.finish();
            }
        }
    }

    private void updateGraphs() {
        final Handler handler = new Handler();
        if (graphTimer != null) {
            graphTimer.cancel();
        }
        graphTimer = new Timer();
        graphTimer.schedule(new TimerTask() {
            @Override
            public void run() {
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            visualizeData();
                        } catch (NullPointerException e) {
                            /* Pass for another refresh round */
                        }
                    }
                });
            }
        }, 0, updatePeriod);
    }

    private void writeLogToFile(long timestamp, float sensorReading) {
        if (getActivity() != null && luxSensor.isRecording) {
            if (luxSensor.writeHeaderToFile) {
                luxSensor.csvLogger.prepareLogFile();
                luxSensor.csvLogger.writeMetaData(getResources().getString(R.string.lux_meter));
                luxSensor.csvLogger.writeCSVFile(CSV_HEADER);
                block = timestamp;
                luxSensor.recordSensorDataBlockID(new SensorDataBlock(timestamp, luxSensor.getSensorName()));
                luxSensor.writeHeaderToFile = !luxSensor.writeHeaderToFile;
            }
            if (luxSensor.addLocation && luxSensor.gpsLogger.isGPSEnabled()) {
                Location location = luxSensor.gpsLogger.getDeviceLocation();
                luxSensor.csvLogger.writeCSVFile(
                        new CSVDataLine()
                                .add(timestamp)
                                .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp)))
                                .add(sensorReading)
                                .add(location.getLatitude())
                                .add(location.getLongitude())
                );
                sensorData = new LuxData(timestamp, block, luxValue, location.getLatitude(), location.getLongitude());
            } else {
                luxSensor.csvLogger.writeCSVFile(
                        new CSVDataLine()
                                .add(timestamp)
                                .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp)))
                                .add(sensorReading)
                                .add(0.0)
                                .add(0.0)
                );
                sensorData = new LuxData(timestamp, block, luxValue, 0.0, 0.0);
            }
            luxSensor.recordSensorData(sensorData);
        } else {
            luxSensor.writeHeaderToFile = true;
        }
    }

    private void visualizeData() {
        if (currentMax < luxValue) {
            currentMax = luxValue;
            statMax.setText(String.format(Locale.getDefault(), PSLabSensor.LUXMETER_DATA_FORMAT, luxValue));
        }
        if (currentMin > luxValue) {
            currentMin = luxValue;
            statMin.setText(String.format(Locale.getDefault(), PSLabSensor.LUXMETER_DATA_FORMAT, luxValue));
        }
        y.setAxisMaximum(currentMax);
        y.setAxisMinimum(currentMin);
        y.setLabelCount(10);
        if (luxValue >= 0) {
            lightMeter.setWithTremble(false);
            lightMeter.setSpeedAt(luxValue);
            if (luxValue > highLimit)
                lightMeter.setPointerColor(Color.RED);
            else
                lightMeter.setPointerColor(Color.WHITE);

            timeElapsed = ((System.currentTimeMillis() - startTime) / updatePeriod);
            if (timeElapsed != previousTimeElapsed) {
                previousTimeElapsed = timeElapsed;
                Entry entry = new Entry((float) timeElapsed, luxValue);
                Long currentTime = System.currentTimeMillis();
                writeLogToFile(currentTime, luxValue);
                entries.add(entry);

                count++;
                sum += entry.getY();
                statMean.setText(String.format(Locale.getDefault(), PSLabSensor.LUXMETER_DATA_FORMAT, (sum / count)));

                LineDataSet dataSet = new LineDataSet(entries, getString(R.string.lux));
                dataSet.setDrawCircles(false);
                dataSet.setDrawValues(false);
                dataSet.setLineWidth(2);
                LineData data = new LineData(dataSet);

                mChart.setData(data);
                mChart.notifyDataSetChanged();
                mChart.setVisibleXRangeMaximum(80);
                mChart.moveViewToX(data.getEntryCount());
                mChart.invalidate();
            }
        }
    }

    private SensorEventListener lightSensorEventListener = new SensorEventListener() {

        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) {/**/}

        @Override
        public void onSensorChanged(SensorEvent event) {
            if (event.sensor.getType() == Sensor.TYPE_LIGHT) {
                luxValue = event.values[0];
            }
        }
    };

    private void resetInstrumentData() {
        luxValue = 0;
        count = 0;
        currentMin = 10000;
        currentMax = 0;
        sum = 0;
        sensor = null;
        if (sensorManager != null) {
            sensorManager.unregisterListener(lightSensorEventListener);
        }
        startTime = System.currentTimeMillis();
        statMax.setText(DataFormatter.formatDouble(0, DataFormatter.LOW_PRECISION_FORMAT));
        statMin.setText(DataFormatter.formatDouble(0, DataFormatter.LOW_PRECISION_FORMAT));
        statMean.setText(DataFormatter.formatDouble(0, DataFormatter.LOW_PRECISION_FORMAT));
        lightMeter.setSpeedAt(0);
        lightMeter.setWithTremble(false);
        entries.clear();
    }

    private void initiateLuxSensor(int type) {
        LUX_SENSOR s = LUX_SENSOR.values()[type];
        resetInstrumentData();
        ScienceLab scienceLab;
        switch (s) {
            case INBUILT_SENSOR:
                sensorLabel.setText(getResources().getStringArray(R.array.lux_sensors)[0]);
                sensorManager = (SensorManager) getContext().getSystemService(SENSOR_SERVICE);
                sensor = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT);
                if (sensor == null) {
                    CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                            getString(R.string.no_lux_sensor), null, null, Snackbar.LENGTH_LONG);
                } else {
                    float max = sensor.getMaximumRange() * 10000;
                    PreferenceManager.getDefaultSharedPreferences(getActivity()).edit().putFloat(luxSensor.LUXMETER_LIMIT, max).apply();
                    lightMeter.setMaxSpeed(max);
                    sensorManager.registerListener(lightSensorEventListener,
                            sensor, SensorManager.SENSOR_DELAY_FASTEST);
                }
                break;
            case BH1750_SENSOR:
                sensorLabel.setText(getResources().getStringArray(R.array.lux_sensors)[1]);
                scienceLab = ScienceLabCommon.scienceLab;
                if (scienceLab.isConnected()) {
                    ArrayList<Integer> data;
                    try {
                        I2C i2c = scienceLab.i2c;
                        data = i2c.scan(null);
                        if (data.contains(0x23)) {
                            BH1750 sensorBH1750 = new BH1750(i2c);
                            sensorBH1750.setRange(String.valueOf(gain));
                            sensorType = 0;
                        } else {
                            CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                                    getString(R.string.sensor_not_connected_tls), null, null, Snackbar.LENGTH_SHORT);
                            sensorType = 0;
                        }
                    } catch (IOException | InterruptedException e) {
                        e.printStackTrace();
                    }
                } else {
                    CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                            getString(R.string.device_not_found), null, null, Snackbar.LENGTH_SHORT);
                    sensorType = 0;
                }

                break;
            case TSL2561_SENSOR:
                sensorLabel.setText(getResources().getStringArray(R.array.lux_sensors)[2]);
                scienceLab = ScienceLabCommon.scienceLab;
                if (scienceLab.isConnected()) {
                    try {
                        I2C i2c = scienceLab.i2c;
                        ArrayList<Integer> data;
                        data = i2c.scan(null);
                        if (data.contains(0x39)) {
                            TSL2561 sensorTSL2561 = new TSL2561(i2c, scienceLab);
                            sensorTSL2561.setGain(String.valueOf(gain));
                            sensorType = 2;
                        } else {
                            CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                                    getString(R.string.sensor_not_connected_tls), null, null, Snackbar.LENGTH_SHORT);
                            sensorType = 0;
                        }
                    } catch (IOException | InterruptedException e) {
                        e.printStackTrace();
                    }
                } else {
                    CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                            getString(R.string.device_not_found), null, null, Snackbar.LENGTH_SHORT);
                    sensorType = 0;
                }
                break;
            default:
                break;
        }
    }
}
