package io.pslab.fragment;

import static android.content.Context.SENSOR_SERVICE;
import static io.pslab.others.CSVLogger.CSV_DIRECTORY;

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
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.preference.PreferenceManager;

import com.github.anastr.speedviewlib.PointerSpeedometer;
import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.components.Legend;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.data.LineDataSet;
import com.google.android.material.snackbar.Snackbar;

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
import io.pslab.activity.ThermometerActivity;
import io.pslab.communication.ScienceLab;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.SHT21;
import io.pslab.interfaces.OperationCallback;
import io.pslab.models.PSLabSensor;
import io.pslab.models.SensorDataBlock;
import io.pslab.models.ThermometerData;
import io.pslab.others.CSVDataLine;
import io.pslab.others.CSVLogger;
import io.pslab.others.CustomSnackBar;
import io.pslab.others.ScienceLabCommon;

public class ThermometerDataFragment extends Fragment implements OperationCallback {

    private static final String TAG = ThermometerDataFragment.class.getSimpleName();

    private static final CSVDataLine CSV_HEADER = new CSVDataLine()
            .add("Timestamp")
            .add("DateTime")
            .add("Readings")
            .add("Latitude")
            .add("Longitude");
    private static int sensorType = 0;
    private static int highLimit = 50;
    private static int updatePeriod = 1000;
    private long timeElapsed;
    private int count = 0, turns = 0;
    private float sum = 0;
    private boolean returningFromPause = false;
    private static String unit = "°C";
    private float tempValue = -1;

    private enum THERMOMETER_SENSOR {INBUILT_SENSOR, SHT21_SENSOR}

    @BindView(R.id.thermo_max)
    TextView statMax;
    @BindView(R.id.thermo_min)
    TextView statMin;
    @BindView(R.id.thermo_avg)
    TextView statMean;
    @BindView(R.id.label_thermo_sensor)
    TextView sensorLabel;
    @BindView(R.id.chart_thermo_meter)
    LineChart mChart;
    @BindView(R.id.thermo_meter)
    PointerSpeedometer thermometer;
    @BindView(R.id.label_thermo_stat_min)
    TextView label_statMin;
    @BindView(R.id.label_thermo_stat_avg)
    TextView label_statAvg;
    @BindView(R.id.label_thermo_stat_max)
    TextView label_statMax;

    private Timer graphTimer;
    private SensorManager sensorManager;
    private Sensor sensor;
    private long startTime, block;
    private ArrayList<Entry> entries;
    private ArrayList<ThermometerData> recordedThermoArray;
    private ThermometerData sensorData;
    private float currentMin = 125;
    private float currentMax = -40;
    private YAxis y;
    private Unbinder unbinder;
    private long previousTimeElapsed = (System.currentTimeMillis() - startTime) / updatePeriod;
    private ThermometerActivity thermoSensor;
    private ThermometerSettingsFragment thermoSettings;
    private View rootView;

    public static ThermometerDataFragment newInstance() {
        return new ThermometerDataFragment();
    }

    public static void setParameters(int updatePeriod, String type, String unit) {
        ThermometerDataFragment.updatePeriod = updatePeriod;
        ThermometerDataFragment.sensorType = Integer.parseInt(type);
        ThermometerDataFragment.unit = unit;

    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        startTime = System.currentTimeMillis();
        entries = new ArrayList<>();
        thermoSensor = (ThermometerActivity) getActivity();
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.activity_thermometer, container, false);
        unbinder = ButterKnife.bind(this, rootView);
        setupInstruments();
        return rootView;
    }

    @Override
    public void onResume() {
        super.onResume();
        if (thermoSensor.playingData) {
            sensorLabel.setText(getResources().getString(R.string.thermometer));
            recordedThermoArray = new ArrayList<>();
            resetInstrumentData();
            playRecordedData();
        } else if (thermoSensor.viewingData) {
            sensorLabel.setText(getResources().getString(R.string.thermometer));
            recordedThermoArray = new ArrayList<>();
            resetInstrumentData();
            plotAllRecordedData();
        } else if (!thermoSensor.isRecording) {
            updateGraphs();
            sum = 0;
            count = 0;
            setUnit();
            entries.clear();
            mChart.clear();
            mChart.invalidate();
            initiateThermoSensor(sensorType);
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
            sensorManager.unregisterListener(thermoSensorEventListener);
        }
        unbinder.unbind();
    }

    private void plotAllRecordedData() {
        recordedThermoArray.addAll(thermoSensor.recordedThermometerData);
        if (recordedThermoArray.size() != 0) {
            for (ThermometerData d : recordedThermoArray) {
                if (currentMax < d.getTemp()) {
                    currentMax = d.getTemp();
                }
                if (currentMin > d.getTemp()) {
                    currentMin = d.getTemp();
                }
                Entry entry = new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getTemp());
                entries.add(entry);
                thermometer.setWithTremble(false);
                thermometer.setSpeedAt(d.getTemp());
                sum += entry.getY();
            }
            y.setAxisMaximum(currentMax);
            y.setAxisMinimum(currentMin);
            y.setLabelCount(10);
            statMax.setText(String.format(Locale.getDefault(), PSLabSensor.THERMOMETER_DATA_FORMAT, currentMax));
            statMin.setText(String.format(Locale.getDefault(), PSLabSensor.THERMOMETER_DATA_FORMAT, currentMin));
            statMean.setText(String.format(Locale.getDefault(), PSLabSensor.THERMOMETER_DATA_FORMAT, (sum / recordedThermoArray.size())));

            LineDataSet dataSet = new LineDataSet(entries, PreferenceManager.getDefaultSharedPreferences(getActivity()).getString(thermoSettings.KEY_THERMO_UNIT, "°C"));
            dataSet.setDrawCircles(false);
            dataSet.setDrawValues(false);
            dataSet.setLineWidth(2);
            LineData data = new LineData(dataSet);

            mChart.setData(data);
            mChart.notifyDataSetChanged();
            mChart.setVisibleXRangeMaximum(800);
            mChart.moveViewToX(data.getEntryCount());
            mChart.invalidate();
        }
    }

    private void playRecordedData() {
        recordedThermoArray.addAll(thermoSensor.recordedThermometerData);
        try {
            if (recordedThermoArray.size() > 1) {
                ThermometerData i = recordedThermoArray.get(1);
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
                        if (thermoSensor.playingData) {
                            try {
                                ThermometerData d = recordedThermoArray.get(turns);
                                turns++;
                                if (currentMax < d.getTemp()) {
                                    currentMax = d.getTemp();
                                    statMax.setText(String.format(Locale.getDefault(), PSLabSensor.THERMOMETER_DATA_FORMAT, d.getTemp()));
                                }
                                if (currentMin > d.getTemp()) {
                                    currentMin = d.getTemp();
                                    statMin.setText(String.format(Locale.getDefault(), PSLabSensor.THERMOMETER_DATA_FORMAT, d.getTemp()));
                                }
                                y.setAxisMaximum(currentMax);
                                y.setAxisMinimum(currentMin);
                                y.setLabelCount(10);
                                thermometer.setWithTremble(false);
                                thermometer.setSpeedAt(d.getTemp());

                                Entry entry = new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getTemp());
                                entries.add(entry);
                                count++;
                                sum += entry.getY();
                                statMean.setText(DataFormatter.formatDouble((sum / count), PSLabSensor.THERMOMETER_DATA_FORMAT));

                                LineDataSet dataSet = new LineDataSet(entries, PreferenceManager.getDefaultSharedPreferences(getActivity()).getString(thermoSettings.KEY_THERMO_UNIT.toString(), "°C"));
                                dataSet.setDrawCircles(false);
                                dataSet.setDrawValues(false);
                                dataSet.setLineWidth(2);
                                LineData data = new LineData(dataSet);

                                mChart.setData(data);
                                mChart.notifyDataSetChanged();
                                mChart.setVisibleXRangeMaximum(800);
                                mChart.moveViewToX(data.getEntryCount());
                                mChart.invalidate();
                            } catch (IndexOutOfBoundsException e) {
                                graphTimer.cancel();
                                graphTimer = null;
                                turns = 0;
                                thermoSensor.playingData = false;
                                thermoSensor.startedPlay = false;
                                thermoSensor.invalidateOptionsMenu();
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
        recordedThermoArray.clear();
        entries.clear();
        plotAllRecordedData();
        thermoSensor.startedPlay = false;
        thermoSensor.playingData = false;
        turns = 0;
        thermoSensor.invalidateOptionsMenu();
    }

    @Override
    public void playData() {
        resetInstrumentData();
        thermoSensor.startedPlay = true;
        try {
            if (recordedThermoArray.size() > 1) {
                ThermometerData i = recordedThermoArray.get(1);
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
        thermoSensor.csvLogger.prepareLogFile();
        thermoSensor.csvLogger.writeMetaData(getResources().getString(R.string.thermometer));
        thermoSensor.csvLogger.writeCSVFile(CSV_HEADER);
        for (ThermometerData thermometerData : thermoSensor.recordedThermometerData) {
            thermoSensor.csvLogger.writeCSVFile(
                    new CSVDataLine()
                            .add(thermometerData.getTime())
                            .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(thermometerData.getTime())))
                            .add(thermometerData.getTemp())
                            .add(thermometerData.getLat())
                            .add(thermometerData.getLon())
            );
        }
        View view = rootView.findViewById(R.id.thermometer_linearlayout);
        view.setDrawingCacheEnabled(true);
        Bitmap b = view.getDrawingCache();
        try {
            b.compress(Bitmap.CompressFormat.JPEG, 100, new FileOutputStream(Environment.getExternalStorageDirectory().getAbsolutePath() +
                    File.separator + CSV_DIRECTORY + File.separator + thermoSensor.getSensorName() +
                    File.separator + CSVLogger.FILE_NAME_FORMAT.format(new Date()) + "_graph.jpg"));
        } catch (FileNotFoundException e) {
            Log.e(TAG, "Unable to save bitmap", e);
        }
    }

    private void setupInstruments() {
        setUnit();
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
        y2.setMaxWidth(0);
    }

    @Override
    public void onPause() {
        super.onPause();
        if (graphTimer != null) {
            returningFromPause = true;
            graphTimer.cancel();
            graphTimer = null;
            if (thermoSensor.playingData) {
                thermoSensor.finish();
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
        if (getActivity() != null && thermoSensor.isRecording) {
            if (thermoSensor.writeHeaderToFile) {
                thermoSensor.csvLogger.prepareLogFile();
                thermoSensor.csvLogger.writeMetaData(getResources().getString(R.string.thermometer));
                thermoSensor.csvLogger.writeCSVFile(CSV_HEADER);
                block = timestamp;
                thermoSensor.recordSensorDataBlockID(new SensorDataBlock(timestamp, thermoSensor.getSensorName()));
                thermoSensor.writeHeaderToFile = !thermoSensor.writeHeaderToFile;
            }
            if (thermoSensor.addLocation && thermoSensor.gpsLogger.isGPSEnabled()) {
                String dateTime = CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp));
                Location location = thermoSensor.gpsLogger.getDeviceLocation();
                thermoSensor.csvLogger.writeCSVFile(
                        new CSVDataLine()
                                .add(timestamp)
                                .add(dateTime)
                                .add(sensorReading)
                                .add(location.getLatitude())
                                .add(location.getLongitude())
                );
                sensorData = new ThermometerData(timestamp, block, tempValue, location.getLatitude(), location.getLongitude());
            } else {
                thermoSensor.csvLogger.writeCSVFile(
                        new CSVDataLine()
                                .add(timestamp)
                                .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp)))
                                .add(sensorReading)
                                .add(0.0)
                                .add(0.0)
                );
                sensorData = new ThermometerData(timestamp, block, tempValue, 0.0, 0.0);
            }
            thermoSensor.recordSensorData(sensorData);
        } else {
            thermoSensor.writeHeaderToFile = true;
        }
    }

    private void visualizeData() {
        if (currentMax < tempValue) {
            currentMax = tempValue;
            statMax.setText(String.format(Locale.getDefault(), PSLabSensor.THERMOMETER_DATA_FORMAT, tempValue));
        }
        if (currentMin > tempValue) {
            currentMin = tempValue;
            statMin.setText(String.format(Locale.getDefault(), PSLabSensor.THERMOMETER_DATA_FORMAT, tempValue));
        }
        y.setAxisMaximum(currentMax);
        y.setAxisMinimum(currentMin);
        y.setLabelCount(10);
        if (tempValue >= 0) {
            thermometer.setWithTremble(false);
            thermometer.setSpeedAt(tempValue);
            if (tempValue > highLimit)
                thermometer.setBackgroundCircleColor(Color.RED);
            else {
                thermometer.setBackgroundCircleColor(getResources().getColor(R.color.primaryBlue));
            }

            timeElapsed = ((System.currentTimeMillis() - startTime) / updatePeriod);
            if (timeElapsed != previousTimeElapsed) {
                previousTimeElapsed = timeElapsed;
                Entry entry = new Entry((float) timeElapsed, tempValue);
                Long currentTime = System.currentTimeMillis();
                writeLogToFile(currentTime, tempValue);
                entries.add(entry);

                count++;
                sum += entry.getY();
                statMean.setText(String.format(Locale.getDefault(), PSLabSensor.THERMOMETER_DATA_FORMAT, (sum / count)));

                LineDataSet dataSet = new LineDataSet(entries, PreferenceManager.getDefaultSharedPreferences(getActivity()).getString(thermoSettings.KEY_THERMO_UNIT, "°C"));
                dataSet.setDrawCircles(false);
                dataSet.setDrawValues(false);
                dataSet.setLineWidth(2);
                LineData data = new LineData(dataSet);

                mChart.setData(data);
                mChart.notifyDataSetChanged();
                mChart.setVisibleXRangeMaximum(800);
                mChart.moveViewToX(data.getEntryCount());
                mChart.invalidate();
            }
        }
    }

    private SensorEventListener thermoSensorEventListener = new SensorEventListener() {

        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) {/**/}

        @Override
        public void onSensorChanged(SensorEvent event) {
            if (event.sensor.getType() == Sensor.TYPE_AMBIENT_TEMPERATURE) {
                tempValue = event.values[0];
            }
        }
    };

    private void resetInstrumentData() {
        tempValue = 0;
        count = 0;
        setUnit();
        sum = 0;
        sensor = null;
        if (sensorManager != null) {
            sensorManager.unregisterListener(thermoSensorEventListener);
        }
        startTime = System.currentTimeMillis();
        statMax.setText(DataFormatter.formatDouble(0, DataFormatter.LOW_PRECISION_FORMAT));
        statMin.setText(DataFormatter.formatDouble(0, DataFormatter.LOW_PRECISION_FORMAT));
        statMean.setText(DataFormatter.formatDouble(0, DataFormatter.LOW_PRECISION_FORMAT));
        thermometer.setSpeedAt(0);
        thermometer.setWithTremble(false);
        entries.clear();
    }

    private void initiateThermoSensor(int type) {
        THERMOMETER_SENSOR s = THERMOMETER_SENSOR.values()[type];
        resetInstrumentData();
        ScienceLab scienceLab;
        switch (s) {
            case INBUILT_SENSOR:
                sensorLabel.setText(getResources().getStringArray(R.array.thermo_sensors)[0]);
                sensorManager = (SensorManager) getContext().getSystemService(SENSOR_SERVICE);
                sensor = sensorManager.getDefaultSensor(Sensor.TYPE_AMBIENT_TEMPERATURE);
                if (sensor == null) {
                    CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                            getString(R.string.no_thermometer_sensor), null, null, Snackbar.LENGTH_LONG);
                } else {
                    float max = sensor.getMaximumRange();
                    PreferenceManager.getDefaultSharedPreferences(getActivity()).edit().putFloat(thermoSensor.THERMOMETER_MAX_LIMIT, max).apply();
                    thermometer.setMaxSpeed(max);
                    sensorManager.registerListener(thermoSensorEventListener,
                            sensor, SensorManager.SENSOR_DELAY_FASTEST);
                }
                break;
            case SHT21_SENSOR:
                sensorLabel.setText(getResources().getStringArray(R.array.thermo_sensors)[1]);
                scienceLab = ScienceLabCommon.scienceLab;
                if (scienceLab.isConnected()) {
                    try {
                        I2C i2c = scienceLab.i2c;
                        ArrayList<Integer> data;
                        data = i2c.scan(null);
                        if (data.contains(0x39)) {
                            SHT21 sensorSHT21 = new SHT21(i2c, scienceLab);
                            sensorSHT21.setMode(SHT21.Mode.TEMPERATURE);
                            sensorType = 1;
                        } else {
                            CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                                    getString(R.string.sensor_not_connected_tls), null, null, Snackbar.LENGTH_SHORT);
                            sensorType = 0;
                        }
                    } catch (IOException | InterruptedException e) {
                        Log.e(TAG, "Unable to get data from sensor.", e);
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

    public void setUnit() {
        if ("°F".equals(ThermometerDataFragment.unit)) {
            currentMax = 257;
            currentMin = -40;
            thermometer.setMaxSpeed(PreferenceManager.getDefaultSharedPreferences(getActivity()).getFloat(thermoSensor.THERMOMETER_MAX_LIMIT, 257));
            thermometer.setMinSpeed(PreferenceManager.getDefaultSharedPreferences(getActivity()).getFloat(thermoSensor.THERMOMETER_MIN_LIMIT, -40));
            label_statAvg.setText(R.string.avg_thermo_fahrenheit);
            label_statMax.setText(R.string.max_thermo_fahrenheit);
            label_statMin.setText(R.string.min_thermo_fahrenheit);
            thermometer.setUnit("°F");
        } else {
            currentMax = 125;
            currentMin = -40;
            thermometer.setMaxSpeed(PreferenceManager.getDefaultSharedPreferences(getActivity()).getFloat(thermoSensor.THERMOMETER_MAX_LIMIT, 125));
            thermometer.setMinSpeed(PreferenceManager.getDefaultSharedPreferences(getActivity()).getFloat(thermoSensor.THERMOMETER_MIN_LIMIT, -40));
            label_statAvg.setText(R.string.avg_thermo_celcius);
            label_statMax.setText(R.string.max_thermo_celcius);
            label_statMin.setText(R.string.min_thermo_celcius);
            thermometer.setUnit("°C");
        }
    }
}
