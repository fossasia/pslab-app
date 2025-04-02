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

import android.text.Html;
import android.util.Pair;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.data.LineDataSet;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;

import io.pslab.R;
import io.pslab.activity.AccelerometerActivity;
import io.pslab.interfaces.OperationCallback;
import io.pslab.models.AccelerometerData;
import io.pslab.models.SensorDataBlock;
import io.pslab.others.CSVDataLine;
import io.pslab.others.CSVLogger;
import io.pslab.others.CustomSnackBar;

import static android.content.Context.SENSOR_SERVICE;
import static io.pslab.others.CSVLogger.CSV_DIRECTORY;

/**
 * Created by Kunal on 18-12-18
 */

public class AccelerometerDataFragment extends Fragment implements OperationCallback {

    private static final CSVDataLine CSV_HEADER = new CSVDataLine()
            .add("Timestamp")
            .add("DateTime")
            .add("ReadingsX")
            .add("ReadingsY")
            .add("ReadingsZ")
            .add("Latitude")
            .add("Longitude");
    private static int updatePeriod = 1000;
    private static float highLimit = 1.2f;
    private static float gain = 1;
    private int turns = 0;
    private boolean returningFromPause = false;
    private Timer graphTimer;
    private SensorManager sensorManager;
    private Sensor sensor;
    private long startTime, block;
    private AccelerometerData sensorData;
    private ArrayList<AccelerometerData> recordedAccelerometerArray;
    private AccelerometerActivity accelerometerSensor;
    private ArrayList<AccelerometerViewFragment> accelerometerViewFragments = new ArrayList<>();
    private int[] colors = {Color.YELLOW, Color.MAGENTA, Color.GREEN};
    private DecimalFormat df = new DecimalFormat("+#0.0;-#0.0");
    private View rootView;

    public static AccelerometerDataFragment newInstance() {
        return new AccelerometerDataFragment();
    }

    public static void setParameters(float highLimit, int updatePeriod, String gain) {
        AccelerometerDataFragment.highLimit = highLimit;
        AccelerometerDataFragment.updatePeriod = updatePeriod;
        AccelerometerDataFragment.gain = Integer.valueOf(gain);
    }

    public static Pair<Integer, Pair<Float, Float>> getParameters() {
        return new Pair<>(updatePeriod, new Pair<>(highLimit, gain));
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        startTime = System.currentTimeMillis();
        accelerometerSensor = (AccelerometerActivity) getActivity();
        for (AccelerometerViewFragment fragment : accelerometerViewFragments) {
            fragment.clear();
        }
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.fragment_accelerometer_data, container, false);
        accelerometerViewFragments.clear();
        accelerometerViewFragments.add((AccelerometerViewFragment) getChildFragmentManager().findFragmentById(R.id.accelerometer_x_axis_fragment));
        accelerometerViewFragments.add((AccelerometerViewFragment) getChildFragmentManager().findFragmentById(R.id.accelerometer_y_axis_fragment));
        accelerometerViewFragments.add((AccelerometerViewFragment) getChildFragmentManager().findFragmentById(R.id.accelerometer_z_axis_fragment));

        accelerometerViewFragments.get(1).getAccelerationAxisImage().setImageResource(R.drawable.phone_y_axis);
        accelerometerViewFragments.get(2).getAccelerationAxisImage().setImageResource(R.drawable.phone_z_axis);

        setupInstruments();
        return rootView;
    }

    @Override
    public void onResume() {
        super.onResume();
        if (accelerometerSensor.playingData) {
            recordedAccelerometerArray = new ArrayList<>();
            resetInstrumentData();
            playRecordedData();
        } else if (accelerometerSensor.viewingData) {
            recordedAccelerometerArray = new ArrayList<>();
            resetInstrumentData();
            plotAllRecordedData();
        } else if (!accelerometerSensor.isRecording) {
            updateGraphs();
            initiateAccelerometerSensor();
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
            sensorManager.unregisterListener(accelerometerSensorEventListener);
        }
    }

    private void plotAllRecordedData() {
        recordedAccelerometerArray.addAll(accelerometerSensor.recordedAccelerometerData);
        if (recordedAccelerometerArray.size() != 0) {
            for (int i = 0; i < accelerometerViewFragments.size(); i++) {
                AccelerometerViewFragment fragment = accelerometerViewFragments.get(i);
                for (AccelerometerData d : recordedAccelerometerArray) {
                    if (fragment.getCurrentMax() < d.getAccelerometer()[i]) {
                        fragment.setCurrentMax(d.getAccelerometer()[i]);
                    }
                    if (fragment.getCurrentMin() > d.getAccelerometer()[i]) {
                        fragment.setCurrentMin(d.getAccelerometer()[i]);
                    }
                    Entry entry = new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getAccelerometer()[i]);
                    fragment.addEntry(entry);
                }

                fragment.setYaxis(highLimit);

                LineDataSet dataSet = new LineDataSet(fragment.getEntries(), getString(R.string.accelerometer));
                dataSet.setDrawCircles(false);
                dataSet.setDrawValues(false);
                dataSet.setLineWidth(2);

                dataSet.setDrawCircles(false);
                dataSet.setDrawValues(false);
                dataSet.setMode(LineDataSet.Mode.CUBIC_BEZIER);
                dataSet.setLineWidth(1);
                dataSet.setColor(colors[i]);
                LineData data = new LineData(dataSet);
                fragment.setChartData(data);
            }
        }
    }

    private void playRecordedData() {
        recordedAccelerometerArray.addAll(accelerometerSensor.recordedAccelerometerData);
        try {
            if (recordedAccelerometerArray.size() > 1) {
                AccelerometerData i = recordedAccelerometerArray.get(1);
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
                        if (accelerometerSensor.viewingData) {
                            try {
                                AccelerometerData d = recordedAccelerometerArray.get(turns);
                                turns++;
                                for (int i = 0; i < accelerometerViewFragments.size(); i++) {
                                    AccelerometerViewFragment fragment = accelerometerViewFragments.get(i);
                                    StringBuilder builder = new StringBuilder();
                                    builder.append(df.format(d.getAccelerometer()[i]));
                                    builder.append(" ");
                                    builder.append(getResources().getString(R.string.acceleration_unit));
                                    fragment.setAccelerationValue(Html.fromHtml(builder.toString()));

                                    if (fragment.getCurrentMax() < d.getAccelerometer()[i]) {
                                        fragment.setCurrentMax(d.getAccelerometer()[i]);
                                        StringBuilder max_builder = new StringBuilder();
                                        max_builder.append("Max: ");
                                        max_builder.append(df.format(fragment.getCurrentMax()));
                                        max_builder.append(" ");
                                        max_builder.append(getResources().getString(R.string.acceleration_unit));
                                        fragment.setAccelerationMax(Html.fromHtml(max_builder.toString()));
                                    }
                                    if (fragment.getCurrentMin() > d.getAccelerometer()[i]) {
                                        fragment.setCurrentMin(d.getAccelerometer()[i]);
                                        StringBuilder min_builder = new StringBuilder();
                                        min_builder.append("Min: ");
                                        min_builder.append(df.format(fragment.getCurrentMax()));
                                        min_builder.append(" ");
                                        min_builder.append(getResources().getString(R.string.acceleration_unit));
                                        fragment.setAccelerationMin(Html.fromHtml(min_builder.toString()));
                                    }

                                    fragment.setYaxis(highLimit);
                                    Entry entryX = new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getAccelerometer()[i]);
                                    fragment.addEntry(entryX);

                                    LineDataSet dataSet = new LineDataSet(fragment.getEntries(), getString(R.string.accelerometer));
                                    dataSet.setDrawCircles(false);
                                    dataSet.setDrawValues(false);
                                    dataSet.setMode(LineDataSet.Mode.CUBIC_BEZIER);
                                    dataSet.setLineWidth(1);
                                    dataSet.setColor(colors[i]);
                                    LineData data = new LineData(dataSet);

                                    fragment.setChartData(data);
                                }
                            } catch (IndexOutOfBoundsException e) {
                                graphTimer.cancel();
                                graphTimer = null;
                                turns = 0;
                                accelerometerSensor.playingData = false;
                                accelerometerSensor.startedPlay = false;
                                accelerometerSensor.invalidateOptionsMenu();
                            }
                        }
                    }
                });
            }
        }, 0, timeGap);
    }

    @Override
    public void playData() {
        resetInstrumentData();
        accelerometerSensor.startedPlay = true;
        try {
            if (recordedAccelerometerArray.size() > 1) {
                AccelerometerData i = recordedAccelerometerArray.get(1);
                long timeGap = i.getTime() - i.getBlock();
                processRecordedData(timeGap);
            } else {
                processRecordedData(0);
            }
        } catch (IllegalArgumentException e) {
            CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                    getActivity().getResources().getString(R.string.no_data_fetched), null, null, Snackbar.LENGTH_SHORT);
        }
    }

    @Override
    public void stopData() {
        if (graphTimer != null) {
            graphTimer.cancel();
            graphTimer = null;
        }
        recordedAccelerometerArray.clear();
        for (AccelerometerViewFragment fragment : accelerometerViewFragments) {
            fragment.clearEntry();
        }
        plotAllRecordedData();
        accelerometerSensor.startedPlay = false;
        accelerometerSensor.playingData = false;
        turns = 0;
        accelerometerSensor.invalidateOptionsMenu();
    }

    @Override
    public void saveGraph() {
        accelerometerSensor.csvLogger.prepareLogFile();
        accelerometerSensor.csvLogger.writeMetaData(getResources().getString(R.string.accelerometer));
        accelerometerSensor.csvLogger.writeCSVFile(CSV_HEADER);
        for (AccelerometerData accelerometerData : accelerometerSensor.recordedAccelerometerData) {
            accelerometerSensor.csvLogger.writeCSVFile(
                    new CSVDataLine()
                            .add(accelerometerData.getTime())
                            .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(accelerometerData.getTime())))
                            .add(accelerometerData.getAccelerometerX())
                            .add(accelerometerData.getAccelerometerY())
                            .add(accelerometerData.getAccelerometerZ())
                            .add(accelerometerData.getLat())
                            .add(accelerometerData.getLon())
            );
        }
        View view = rootView.findViewById(R.id.accelerometer_linearlayout);
        view.setDrawingCacheEnabled(true);
        Bitmap b = view.getDrawingCache();
        try {
            b.compress(Bitmap.CompressFormat.JPEG, 100, new FileOutputStream(Environment.getExternalStorageDirectory().getAbsolutePath() +
                    File.separator + CSV_DIRECTORY + File.separator + accelerometerSensor.getSensorName() +
                    File.separator + CSVLogger.FILE_NAME_FORMAT.format(new Date()) + "_graph.jpg"));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
    }

    private void setupInstruments() {
        for (AccelerometerViewFragment fragment : accelerometerViewFragments) {
            fragment.setUp();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        if (graphTimer != null) {
            returningFromPause = true;
            graphTimer.cancel();
            graphTimer = null;
            if (accelerometerSensor.playingData) {
                accelerometerSensor.finish();
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

    private void writeLogToFile(long timestamp, float readingX, float readingY, float readingZ) {
        if (getActivity() != null && accelerometerSensor.isRecording) {
            if (accelerometerSensor.writeHeaderToFile) {
                accelerometerSensor.csvLogger.prepareLogFile();
                accelerometerSensor.csvLogger.writeMetaData(getResources().getString(R.string.accelerometer));
                accelerometerSensor.csvLogger.writeCSVFile(CSV_HEADER);
                block = timestamp;
                accelerometerSensor.recordSensorDataBlockID(new SensorDataBlock(timestamp, accelerometerSensor.getSensorName()));
                accelerometerSensor.writeHeaderToFile = !accelerometerSensor.writeHeaderToFile;
            }
            if (accelerometerSensor.addLocation && accelerometerSensor.gpsLogger.isGPSEnabled()) {
                Location location = accelerometerSensor.gpsLogger.getDeviceLocation();
                accelerometerSensor.csvLogger.writeCSVFile(
                        new CSVDataLine()
                                .add(timestamp)
                                .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp)))
                                .add(readingX)
                                .add(readingY)
                                .add(readingZ)
                                .add(location.getLatitude())
                                .add(location.getLongitude())
                );
                sensorData = new AccelerometerData(timestamp, block, accelerometerViewFragments.get(0).getCurrentValue(), accelerometerViewFragments.get(1).getCurrentValue(), accelerometerViewFragments.get(2).getCurrentValue(), location.getLatitude(), location.getLongitude());
            } else {
                accelerometerSensor.csvLogger.writeCSVFile(
                        new CSVDataLine()
                                .add(timestamp)
                                .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp)))
                                .add(readingX)
                                .add(readingY)
                                .add(readingZ)
                                .add(0.0)
                                .add(0.0)
                );
                sensorData = new AccelerometerData(timestamp, block, accelerometerViewFragments.get(0).getCurrentValue(), accelerometerViewFragments.get(1).getCurrentValue(), accelerometerViewFragments.get(2).getCurrentValue(), 0.0, 0.0);
            }
            accelerometerSensor.recordSensorData(sensorData);
        } else {
            accelerometerSensor.writeHeaderToFile = true;
        }
    }

    private void visualizeData() {
        if (!isAdded()) return;
        for (int i = 0; i < accelerometerViewFragments.size(); i++) {
            AccelerometerViewFragment fragment = accelerometerViewFragments.get(i);
            long timeElapsed = (System.currentTimeMillis() - startTime) / 1000;
            if (timeElapsed != fragment.getPreviousTimeElapsed()) {
                fragment.setPreviousTimeElapsed(timeElapsed);
                fragment.addEntry(new Entry((float) timeElapsed, fragment.getCurrentValue()));

                LineDataSet dataSet = new LineDataSet(fragment.getEntries(), getString(R.string.accelerometer));
                dataSet.setDrawCircles(false);
                dataSet.setDrawValues(false);
                dataSet.setMode(LineDataSet.Mode.CUBIC_BEZIER);
                dataSet.setLineWidth(1);
                dataSet.setColor(colors[i]);
                LineData data = new LineData(dataSet);

                fragment.setChartData(data);
                fragment.setYaxis(highLimit);
            }
        }
        Long currentTime = System.currentTimeMillis();
        writeLogToFile(currentTime, accelerometerViewFragments.get(0).getCurrentValue(), accelerometerViewFragments.get(1).getCurrentValue(), accelerometerViewFragments.get(2).getCurrentValue());
    }

    private SensorEventListener accelerometerSensorEventListener = new SensorEventListener() {

        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) {/**/}

        @Override
        public void onSensorChanged(SensorEvent event) {
            if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
                for (int i = 0; i < accelerometerViewFragments.size(); i++) {
                    AccelerometerViewFragment fragment = accelerometerViewFragments.get(i);
                    fragment.setCurrentValue(event.values[i]);
                    StringBuilder builder = new StringBuilder();
                    builder.append(df.format(fragment.getCurrentValue()));
                    builder.append(" ");
                    builder.append(getResources().getString(R.string.acceleration_unit));
                    fragment.setAccelerationValue(Html.fromHtml(builder.toString()));

                    if (fragment.getCurrentValue() > fragment.getCurrentMax()) {
                        builder.insert(0, getResources().getString(R.string.text_max));
                        builder.insert(3, " ");
                        fragment.setAccelerationMax(Html.fromHtml(builder.toString()));
                        fragment.setCurrentMax(fragment.getCurrentValue());
                    } else if (fragment.getCurrentValue() < fragment.getCurrentMin()) {
                        builder.insert(0, getResources().getString(R.string.text_min));
                        builder.insert(3, " ");
                        fragment.setAccelerationMin(Html.fromHtml(builder.toString()));
                        fragment.setCurrentMin(fragment.getCurrentValue());
                    }
                }
            }
        }
    };

    private void resetInstrumentData() {
        for (AccelerometerViewFragment fragment : accelerometerViewFragments) {
            fragment.clear();
        }
    }

    private void initiateAccelerometerSensor() {
        resetInstrumentData();
        sensorManager = (SensorManager) getContext().getSystemService(SENSOR_SERVICE);
        sensor = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        if (sensor == null) {
            CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                    getResources().getString(R.string.no_accelerometer_sensor), null, null, Snackbar.LENGTH_LONG);
        } else {
            sensorManager.registerListener(accelerometerSensorEventListener,
                    sensor, SensorManager.SENSOR_DELAY_FASTEST);
        }

    }
}