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
import android.widget.LinearLayout;
import android.widget.TextView;

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
import io.pslab.activity.GyroscopeActivity;
import io.pslab.interfaces.OperationCallback;
import io.pslab.models.GyroData;
import io.pslab.models.SensorDataBlock;
import io.pslab.others.CSVDataLine;
import io.pslab.others.CSVLogger;
import io.pslab.others.CustomSnackBar;

import static android.content.Context.SENSOR_SERVICE;
import static io.pslab.others.CSVLogger.CSV_DIRECTORY;

public class GyroscopeDataFragment extends Fragment implements OperationCallback {

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
    private GyroData sensorData;
    private ArrayList<GyroData> recordedGyroArray;
    private GyroscopeActivity gyroSensor;
    private ArrayList<GyroscopeViewFragment> gyroscopeViewFragments = new ArrayList<>();
    private int[] colors = {Color.YELLOW, Color.MAGENTA, Color.GREEN};
    private DecimalFormat df = new DecimalFormat("+#0.0;-#0.0");
    private View rootView;
    private TextView noSensorText;
    private LinearLayout gyroLinearLayout;

    public static GyroscopeDataFragment newInstance() {
        return new GyroscopeDataFragment();
    }

    public static void setParameters(float highLimit, int updatePeriod, String gain) {
        GyroscopeDataFragment.highLimit = highLimit;
        GyroscopeDataFragment.updatePeriod = updatePeriod;
        GyroscopeDataFragment.gain = Integer.valueOf(gain);
    }

    public static Pair<Integer, Pair<Float, Float>> getParameters() {
        return new Pair<>(updatePeriod, new Pair<>(highLimit, gain));
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        startTime = System.currentTimeMillis();
        gyroSensor = (GyroscopeActivity) getActivity();
        for (GyroscopeViewFragment fragment : gyroscopeViewFragments) {
            fragment.clear();
        }
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.fragment_gyroscope_data, container, false);
        gyroscopeViewFragments.clear();
        gyroscopeViewFragments.add((GyroscopeViewFragment) getChildFragmentManager().findFragmentById(R.id.gyroscope_x_axis_fragment));
        gyroscopeViewFragments.add((GyroscopeViewFragment) getChildFragmentManager().findFragmentById(R.id.gyroscope_y_axis_fragment));
        gyroscopeViewFragments.add((GyroscopeViewFragment) getChildFragmentManager().findFragmentById(R.id.gyroscope_z_axis_fragment));

        gyroscopeViewFragments.get(1).getGyroAxisImage().setImageResource(R.drawable.phone_y_axis);
        gyroscopeViewFragments.get(2).getGyroAxisImage().setImageResource(R.drawable.phone_z_axis);
        gyroLinearLayout = rootView.findViewById(R.id.gyro_linearlayout);
        noSensorText = new TextView(getContext());

        setupInstruments();
        return rootView;
    }

    @Override
    public void onResume() {
        super.onResume();
        if (gyroSensor.playingData) {
            recordedGyroArray = new ArrayList<>();
            resetInstrumentData();
            playRecordedData();
        } else if (gyroSensor.viewingData) {
            recordedGyroArray = new ArrayList<>();
            resetInstrumentData();
            plotAllRecordedData();

        } else if (!gyroSensor.isRecording) {
            updateGraphs();
            initiateGyroSensor();
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
            sensorManager.unregisterListener(gyroScopeSensorEventListener);
        } else {
            gyroLinearLayout.removeView(noSensorText);
        }
    }

    private void plotAllRecordedData() {
        recordedGyroArray.addAll(gyroSensor.recordedGyroData);
        if (recordedGyroArray.size() != 0) {
            for (int i = 0; i < gyroscopeViewFragments.size(); i++) {
                GyroscopeViewFragment fragment = gyroscopeViewFragments.get(i);
                for (GyroData d : recordedGyroArray) {
                    if (fragment.getCurrentMax() < d.getGyro()[i]) {
                        fragment.setCurrentMax(d.getGyro()[i]);
                    }
                    if (fragment.getCurrentMin() < d.getGyro()[i]) {
                        fragment.setCurrentMin(d.getGyro()[i]);
                    }
                    Entry entry = new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getGyro()[i]);
                    fragment.addEntry(entry);
                }

                fragment.setYaxis(highLimit);

                LineDataSet dataSet = new LineDataSet(fragment.getEntries(), getString(R.string.gyroscope));
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
        recordedGyroArray.addAll(gyroSensor.recordedGyroData);
        try {
            if (recordedGyroArray.size() > 1) {
                GyroData i = recordedGyroArray.get(1);
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
                        if (gyroSensor.playingData) {
                            try {
                                GyroData d = recordedGyroArray.get(turns);
                                turns++;
                                for (int i = 0; i < gyroscopeViewFragments.size(); i++) {
                                    GyroscopeViewFragment fragment = gyroscopeViewFragments.get(i);
                                    StringBuilder builder = new StringBuilder();
                                    builder.append(df.format(d.getGyro()[i]));
                                    builder.append(" ");
                                    builder.append(getResources().getString(R.string.radian_per_sec_text));
                                    fragment.setGyroValue(Html.fromHtml(builder.toString()));

                                    if (fragment.getCurrentMax() < d.getGyro()[i]) {
                                        fragment.setCurrentMax(d.getGyro()[i]);
                                        StringBuilder max_builder = new StringBuilder();
                                        max_builder.append("Max: ");
                                        max_builder.append(df.format(fragment.getCurrentMax()));
                                        max_builder.append(" ");
                                        max_builder.append(getResources().getString(R.string.radian_per_sec_text));
                                        fragment.setGyroMax(Html.fromHtml(max_builder.toString()));
                                    }
                                    if (fragment.getCurrentMin() < d.getGyro()[i]) {
                                        fragment.setCurrentMin(d.getGyro()[i]);
                                        StringBuilder min_builder = new StringBuilder();
                                        min_builder.append("Min: ");
                                        min_builder.append(df.format(fragment.getCurrentMax()));
                                        min_builder.append(" ");
                                        min_builder.append(getResources().getString(R.string.radian_per_sec_text));
                                        fragment.setGyroMin(Html.fromHtml(min_builder.toString()));
                                    }

                                    fragment.setYaxis(highLimit);
                                    Entry entryX = new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getGyro()[i]);
                                    fragment.addEntry(entryX);

                                    LineDataSet dataSet = new LineDataSet(fragment.getEntries(), getString(R.string.gyroscope));
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
                                gyroSensor.playingData = false;
                                gyroSensor.startedPlay = false;
                                gyroSensor.invalidateOptionsMenu();
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
        gyroSensor.startedPlay = true;
        try {
            if (recordedGyroArray.size() > 1) {
                GyroData i = recordedGyroArray.get(1);
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
    public void stopData() {
        if (graphTimer != null) {
            graphTimer.cancel();
            graphTimer = null;
        }
        recordedGyroArray.clear();
        for (GyroscopeViewFragment fragment : gyroscopeViewFragments) {
            fragment.clearEntry();
        }
        plotAllRecordedData();
        gyroSensor.startedPlay = false;
        gyroSensor.playingData = false;
        turns = 0;
        gyroSensor.invalidateOptionsMenu();
    }

    @Override
    public void saveGraph() {
        gyroSensor.csvLogger.prepareLogFile();
        gyroSensor.csvLogger.writeMetaData(getResources().getString(R.string.gyroscope));
        gyroSensor.csvLogger.writeCSVFile(CSV_HEADER);
        for (GyroData gyroData : gyroSensor.recordedGyroData) {
            gyroSensor.csvLogger.writeCSVFile(
                    new CSVDataLine()
                            .add(gyroData.getTime())
                            .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(gyroData.getTime())))
                            .add(gyroData.getGyroX())
                            .add(gyroData.getGyroY())
                            .add(gyroData.getGyroZ())
                            .add(gyroData.getLat())
                            .add(gyroData.getLon())
            );
        }
        View view = rootView.findViewById(R.id.gyro_linearlayout);
        view.setDrawingCacheEnabled(true);
        Bitmap b = view.getDrawingCache();
        try {
            b.compress(Bitmap.CompressFormat.JPEG, 100, new FileOutputStream(Environment.getExternalStorageDirectory().getAbsolutePath() +
                    File.separator + CSV_DIRECTORY + File.separator + gyroSensor.getSensorName() +
                    File.separator + CSVLogger.FILE_NAME_FORMAT.format(new Date()) + "_graph.jpg"));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
    }

    private void setupInstruments() {
        for (GyroscopeViewFragment fragment : gyroscopeViewFragments) {
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
            if (gyroSensor.playingData) {
                gyroSensor.finish();
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
        if (getActivity() != null && gyroSensor.isRecording) {
            if (gyroSensor.writeHeaderToFile) {
                gyroSensor.csvLogger.prepareLogFile();
                gyroSensor.csvLogger.writeMetaData(getResources().getString(R.string.gyroscope));
                gyroSensor.csvLogger.writeCSVFile(CSV_HEADER);
                gyroSensor.csvLogger.writeCSVFile(CSV_HEADER);
                block = timestamp;
                gyroSensor.recordSensorDataBlockID(new SensorDataBlock(timestamp, gyroSensor.getSensorName()));
                gyroSensor.writeHeaderToFile = !gyroSensor.writeHeaderToFile;
            }
            if (gyroSensor.addLocation && gyroSensor.gpsLogger.isGPSEnabled()) {
                Location location = gyroSensor.gpsLogger.getDeviceLocation();
                gyroSensor.csvLogger.writeCSVFile(
                        new CSVDataLine()
                                .add(timestamp)
                                .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp)))
                                .add(readingX)
                                .add(readingY)
                                .add(readingZ)
                                .add(location.getLatitude())
                                .add(location.getLongitude())
                );
                sensorData = new GyroData(timestamp, block, gyroscopeViewFragments.get(0).getCurrentValue(), gyroscopeViewFragments.get(1).getCurrentValue(), gyroscopeViewFragments.get(2).getCurrentValue(), location.getLatitude(), location.getLongitude());
            } else {
                gyroSensor.csvLogger.writeCSVFile(
                        new CSVDataLine()
                                .add(timestamp)
                                .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp)))
                                .add(readingX)
                                .add(readingY)
                                .add(readingZ)
                                .add(0.0)
                                .add(0.0)
                );
                sensorData = new GyroData(timestamp, block, gyroscopeViewFragments.get(0).getCurrentValue(), gyroscopeViewFragments.get(1).getCurrentValue(), gyroscopeViewFragments.get(2).getCurrentValue(), 0.0, 0.0);
            }
            gyroSensor.recordSensorData(sensorData);
        } else {
            gyroSensor.writeHeaderToFile = true;
        }
    }

    private void visualizeData() {
        if (!isAdded()) return;
        for (int i = 0; i < gyroscopeViewFragments.size(); i++) {
            GyroscopeViewFragment fragment = gyroscopeViewFragments.get(i);
            if (!fragment.isAdded()) continue;

            long timeElapsed = (System.currentTimeMillis() - startTime) / 1000;
            if (timeElapsed != fragment.getPreviousTimeElapsed()) {
                fragment.setPreviousTimeElapsed(timeElapsed);
                fragment.addEntry(new Entry((float) timeElapsed, fragment.getCurrentValue()));

                LineDataSet dataSet = new LineDataSet(fragment.getEntries(), getString(R.string.gyroscope));
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
        writeLogToFile(currentTime, gyroscopeViewFragments.get(0).getCurrentValue(), gyroscopeViewFragments.get(1).getCurrentValue(), gyroscopeViewFragments.get(2).getCurrentValue());
    }

    private SensorEventListener gyroScopeSensorEventListener = new SensorEventListener() {

        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) {/**/}

        @Override
        public void onSensorChanged(SensorEvent event) {
            if (event.sensor.getType() == Sensor.TYPE_GYROSCOPE) {
                for (int i = 0; i < gyroscopeViewFragments.size(); i++) {
                    GyroscopeViewFragment fragment = gyroscopeViewFragments.get(i);
                    fragment.setCurrentValue(event.values[i]);
                    StringBuilder builder = new StringBuilder();
                    builder.append(df.format(fragment.getCurrentValue()));
                    builder.append(" ");
                    builder.append(getResources().getString(R.string.radian_per_sec_text));
                    fragment.setGyroValue(Html.fromHtml(builder.toString()));

                    if (fragment.getCurrentValue() > fragment.getCurrentMax()) {
                        builder.insert(0, getResources().getString(R.string.text_max));
                        builder.insert(3, " ");
                        fragment.setGyroMax(Html.fromHtml(builder.toString()));
                        fragment.setCurrentMax(fragment.getCurrentValue());
                    } else if (fragment.getCurrentValue() < fragment.getCurrentMin()) {
                        builder.insert(0, getResources().getString(R.string.text_min));
                        builder.insert(3, " ");
                        fragment.setGyroMin(Html.fromHtml(builder.toString()));
                        fragment.setCurrentMin(fragment.getCurrentValue());
                    }
                }
            }
        }
    };

    private void resetInstrumentData() {
        for (GyroscopeViewFragment fragment : gyroscopeViewFragments) {
            fragment.clear();
        }
    }

    private void initiateGyroSensor() {
        resetInstrumentData();
        sensorManager = (SensorManager) getContext().getSystemService(SENSOR_SERVICE);
        if (sensorManager == null) {
            noSensorLayoutUpdate();
        } else {
            sensor = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
            if (sensor == null) {
                CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                        getString(R.string.no_gyroscope_sensor), null, null, Snackbar.LENGTH_LONG);
            } else {
                sensorManager.registerListener(gyroScopeSensorEventListener,
                        sensor, SensorManager.SENSOR_DELAY_FASTEST);
            }
        }
    }

    private void noSensorLayoutUpdate() {
        gyroscopeViewFragments.clear();
        rootView.findViewById(R.id.gyroscope_x_axis_fragment).setVisibility(View.GONE);
        rootView.findViewById(R.id.gyroscope_y_axis_fragment).setVisibility(View.GONE);
        rootView.findViewById(R.id.gyroscope_z_axis_fragment).setVisibility(View.GONE);
        noSensorText.setText(getResources().getString(R.string.no_data_recorded_gyro));
        noSensorText.setAllCaps(true);
        gyroLinearLayout.addView(noSensorText);
    }
}
