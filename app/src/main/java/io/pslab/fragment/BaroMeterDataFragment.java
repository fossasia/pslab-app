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
import com.github.mikephil.charting.interfaces.datasets.ILineDataSet;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Timer;
import java.util.TimerTask;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.Unbinder;
import io.pslab.DataFormatter;
import io.pslab.R;
import io.pslab.activity.BarometerActivity;
import io.pslab.communication.ScienceLab;
import io.pslab.communication.peripherals.I2C;
import io.pslab.communication.sensors.BMP180;
import io.pslab.interfaces.OperationCallback;
import io.pslab.models.BaroData;
import io.pslab.models.PSLabSensor;
import io.pslab.models.SensorDataBlock;
import io.pslab.others.CSVDataLine;
import io.pslab.others.CSVLogger;
import io.pslab.others.CustomSnackBar;
import io.pslab.others.ScienceLabCommon;

import static android.content.Context.SENSOR_SERVICE;
import static io.pslab.others.CSVLogger.CSV_DIRECTORY;

/**
 * Created by Padmal on 12/13/18.
 */

public class BaroMeterDataFragment extends Fragment implements OperationCallback {

    private static final CSVDataLine CSV_HEADER = new CSVDataLine()
            .add("Timestamp")
            .add("DateTime")
            .add("Pressure")
            .add("Altitude")
            .add("Latitude")
            .add("Longitude");

    private static int sensorType = 0;
    private static float highLimit = 1.2f;
    private static int updatePeriod = 1000;
    private long timeElapsed;
    private int count = 0, turns = 0;
    private float sum = 0;
    private boolean returningFromPause = false;

    private float baroValue = -1;

    private enum BARO_SENSOR {INBUILT_SENSOR, BMP180_SENSOR}

    @BindView(R.id.baro_max)
    TextView statMax;
    @BindView(R.id.baro_min)
    TextView statMin;
    @BindView(R.id.baro_avg)
    TextView statMean;
    @BindView(R.id.label_baro_sensor)
    TextView sensorLabel;
    @BindView(R.id.chart_baro_meter)
    LineChart mChart;
    @BindView(R.id.baro_meter)
    PointerSpeedometer baroMeter;
    @BindView(R.id.alti_value)
    TextView altiValue;

    private Timer graphTimer;
    private SensorManager sensorManager;
    private Sensor sensor;
    private long startTime, block;
    private ArrayList<Entry> pressureEntries;
    private ArrayList<Entry> altitudeEntries;
    private ArrayList<BaroData> recordedBaroArray;
    private BaroData sensorData;
    private YAxis y;
    private YAxis y2;
    private Unbinder unbinder;
    private long previousTimeElapsed = (System.currentTimeMillis() - startTime) / updatePeriod;
    private BarometerActivity baroSensor;
    private View rootView;

    public static BaroMeterDataFragment newInstance() {
        return new BaroMeterDataFragment();
    }

    public static void setParameters(float highLimit, int updatePeriod, String type) {
        BaroMeterDataFragment.highLimit = highLimit;
        BaroMeterDataFragment.updatePeriod = updatePeriod;
        BaroMeterDataFragment.sensorType = Integer.valueOf(type);
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        startTime = System.currentTimeMillis();
        pressureEntries = new ArrayList<>();
        altitudeEntries = new ArrayList<>();
        baroSensor = (BarometerActivity) getActivity();
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.fragment_barometer_data, container, false);
        unbinder = ButterKnife.bind(this, rootView);
        setupInstruments();
        return rootView;
    }

    @Override
    public void onResume() {
        super.onResume();
        if (baroSensor.playingData) {
            sensorLabel.setText(getResources().getString(R.string.baro_meter));
            recordedBaroArray = new ArrayList<>();
            resetInstrumentData();
            playRecordedData();
        } else if (baroSensor.viewingData) {
            sensorLabel.setText(getResources().getString(R.string.baro_meter));
            recordedBaroArray = new ArrayList<>();
            resetInstrumentData();
            plotAllRecordedData();
        } else if (!baroSensor.isRecording) {
            updateGraphs();
            sum = 0;
            count = 0;
            // REMOVE these fixed axis values to allow auto-scaling
            // currentMin = 2;
            // currentMax = 0.5f;
            pressureEntries.clear();
            altitudeEntries.clear();
            mChart.clear();
            mChart.invalidate();
            // Auto-scaling: reset min/max if using MPAndroidChart
            mChart.getAxisLeft().resetAxisMinimum();
            mChart.getAxisLeft().resetAxisMaximum();
            mChart.getAxisRight().resetAxisMinimum();
            mChart.getAxisRight().resetAxisMaximum();
            initiateBaroSensor(sensorType);
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
            sensorManager.unregisterListener(baroSensorEventListener);
        }
        unbinder.unbind();
    }

    private void plotAllRecordedData() {
        recordedBaroArray.addAll(baroSensor.recordedBaroData);
        if (recordedBaroArray.size() != 0) {
            for (BaroData d : recordedBaroArray) {
                if (currentMax < d.getBaro()) {
                    currentMax = d.getBaro();
                }
                if (currentMin > d.getBaro()) {
                    currentMin = d.getBaro();
                }
                Entry entry = new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getBaro());
                pressureEntries.add(entry);
                altitudeEntries.add(new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getAltitude()));
                altiValue.setText(String.format(Locale.getDefault(), PSLabSensor.BAROMETER_DATA_FORMAT, d.getAltitude()));
                baroMeter.setWithTremble(false);
                baroMeter.setSpeedAt(d.getBaro());
                sum += entry.getY();
            }
            y.setAxisMaximum(currentMax);
            y.setAxisMinimum(currentMin);
            y.setLabelCount(10);
            y2.setAxisMaximum(getAltitude(currentMax));
            y2.setAxisMinimum(getAltitude(currentMin));
            y2.setLabelCount(10);
            statMax.setText(String.format(Locale.getDefault(), PSLabSensor.BAROMETER_DATA_FORMAT, currentMax));
            statMin.setText(String.format(Locale.getDefault(), PSLabSensor.BAROMETER_DATA_FORMAT, currentMin));
            statMean.setText(String.format(Locale.getDefault(), PSLabSensor.BAROMETER_DATA_FORMAT, (sum / recordedBaroArray.size())));

            List<ILineDataSet> dataSets = new ArrayList<>();
            LineDataSet dataSet = new LineDataSet(pressureEntries, getString(R.string.baro_unit));
            dataSet.setDrawCircles(false);
            dataSet.setDrawValues(false);
            dataSet.setLineWidth(2);
            dataSets.add(dataSet);

            dataSet = new LineDataSet(altitudeEntries, getString(R.string.alti_unit));
            dataSet.setDrawCircles(false);
            dataSet.setDrawValues(false);
            dataSet.setLineWidth(2);
            dataSet.setColor(Color.YELLOW);
            dataSets.add(dataSet);
            LineData data = new LineData(dataSets);

            mChart.setData(data);
            mChart.notifyDataSetChanged();
            mChart.setVisibleXRangeMaximum(80);
            mChart.moveViewToX(data.getEntryCount());
            mChart.invalidate();
        }
    }

    private void playRecordedData() {
        recordedBaroArray.addAll(baroSensor.recordedBaroData);
        try {
            if (recordedBaroArray.size() > 1) {
                BaroData i = recordedBaroArray.get(1);
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
                        if (baroSensor.playingData) {
                            try {
                                BaroData d = recordedBaroArray.get(turns);
                                turns++;
                                if (currentMax < d.getBaro()) {
                                    currentMax = d.getBaro();
                                    statMax.setText(String.format(Locale.getDefault(), PSLabSensor.BAROMETER_DATA_FORMAT, d.getBaro()));
                                }
                                if (currentMin > d.getBaro()) {
                                    currentMin = d.getBaro();
                                    statMin.setText(String.format(Locale.getDefault(), PSLabSensor.BAROMETER_DATA_FORMAT, d.getBaro()));
                                }
                                y.setAxisMaximum(currentMax);
                                y.setAxisMinimum(currentMin);
                                y.setLabelCount(10);
                                y2.setAxisMaximum(getAltitude(currentMax));
                                y2.setAxisMinimum(getAltitude(currentMin));
                                y2.setLabelCount(10);
                                baroMeter.setWithTremble(false);
                                baroMeter.setSpeedAt(d.getBaro());

                                Entry entry = new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getBaro());
                                pressureEntries.add(entry);
                                altitudeEntries.add(new Entry((float) (d.getTime() - d.getBlock()) / 1000, d.getAltitude()));
                                count++;
                                sum += entry.getY();
                                statMean.setText(DataFormatter.formatDouble((sum / count), PSLabSensor.BAROMETER_DATA_FORMAT));
                                altiValue.setText(String.format(Locale.getDefault(), PSLabSensor.BAROMETER_DATA_FORMAT, d.getAltitude()));

                                List<ILineDataSet> dataSets = new ArrayList<>();
                                LineDataSet dataSet = new LineDataSet(pressureEntries, getString(R.string.baro_unit));
                                dataSet.setDrawCircles(false);
                                dataSet.setDrawValues(false);
                                dataSet.setLineWidth(2);
                                dataSets.add(dataSet);

                                dataSet = new LineDataSet(altitudeEntries, getString(R.string.alti_unit));
                                dataSet.setDrawCircles(false);
                                dataSet.setDrawValues(false);
                                dataSet.setLineWidth(2);
                                dataSet.setColor(Color.YELLOW);
                                dataSets.add(dataSet);
                                LineData data = new LineData(dataSets);

                                mChart.setData(data);
                                mChart.notifyDataSetChanged();
                                mChart.setVisibleXRangeMaximum(80);
                                mChart.moveViewToX(data.getEntryCount());
                                mChart.invalidate();
                            } catch (IndexOutOfBoundsException e) {
                                graphTimer.cancel();
                                graphTimer = null;
                                turns = 0;
                                baroSensor.playingData = false;
                                baroSensor.startedPlay = false;
                                baroSensor.invalidateOptionsMenu();
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
        baroSensor.startedPlay = true;
        try {
            if (recordedBaroArray.size() > 1) {
                BaroData i = recordedBaroArray.get(1);
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
        recordedBaroArray.clear();
        pressureEntries.clear();
        plotAllRecordedData();
        baroSensor.startedPlay = false;
        baroSensor.playingData = false;
        turns = 0;
        baroSensor.invalidateOptionsMenu();
    }

    @Override
    public void saveGraph() {
        baroSensor.csvLogger.prepareLogFile();
        baroSensor.csvLogger.writeMetaData(getResources().getString(R.string.baro_meter));
        baroSensor.csvLogger.writeCSVFile(CSV_HEADER);
        for (BaroData baroData : baroSensor.recordedBaroData) {
            baroSensor.csvLogger.writeCSVFile(
                    new CSVDataLine()
                            .add(baroData.getTime())
                            .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(baroData.getTime())))
                            .add(baroData.getBaro())
                            .add(baroData.getAltitude())
                            .add(baroData.getLat())
                            .add(baroData.getLon())
            );
        }
        View view = rootView.findViewById(R.id.barometer_linearlayout);
        view.setDrawingCacheEnabled(true);
        Bitmap b = view.getDrawingCache();
        try {
            b.compress(Bitmap.CompressFormat.JPEG, 100, new FileOutputStream(Environment.getExternalStorageDirectory().getAbsolutePath() +
                    File.separator + CSV_DIRECTORY + File.separator + baroSensor.getSensorName() +
                    File.separator + CSVLogger.FILE_NAME_FORMAT.format(new Date()) + "_graph.jpg"));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
    }

    private void setupInstruments() {
        baroMeter.setMaxSpeed(PreferenceManager.getDefaultSharedPreferences(getActivity()).getFloat(baroSensor.BAROMETER_LIMIT, 2));
        XAxis x = mChart.getXAxis();
        this.y = mChart.getAxisLeft();
        this.y2 = mChart.getAxisRight();

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

        y2.setTextColor(Color.WHITE);
        y2.setAxisMinimum(getAltitude(currentMin));
        y2.setAxisMaximum(getAltitude(currentMax));
        y2.setDrawGridLines(true);
        y2.setLabelCount(10);
    }

    @Override
    public void onPause() {
        super.onPause();
        if (graphTimer != null) {
            returningFromPause = true;
            graphTimer.cancel();
            graphTimer = null;
            if (baroSensor.playingData) {
                baroSensor.finish();
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
        if (getActivity() != null && baroSensor.isRecording) {
            if (baroSensor.writeHeaderToFile) {
                baroSensor.csvLogger.prepareLogFile();
                baroSensor.csvLogger.writeCSVFile(CSV_HEADER);
                block = timestamp;
                baroSensor.recordSensorDataBlockID(new SensorDataBlock(timestamp, baroSensor.getSensorName()));
                baroSensor.writeHeaderToFile = !baroSensor.writeHeaderToFile;
            }
            if (baroSensor.addLocation && baroSensor.gpsLogger.isGPSEnabled()) {
                Location location = baroSensor.gpsLogger.getDeviceLocation();
                baroSensor.csvLogger.writeCSVFile(
                        new CSVDataLine()
                                .add(timestamp)
                                .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp)))
                                .add(sensorReading)
                                .add(getAltitude(sensorReading))
                                .add(location.getLatitude())
                                .add(location.getLongitude())
                );
                sensorData = new BaroData(timestamp, block, baroValue, getAltitude(baroValue), location.getLatitude(), location.getLongitude());
            } else {
                baroSensor.csvLogger.writeCSVFile(
                        new CSVDataLine()
                                .add(timestamp)
                                .add(CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp)))
                                .add(sensorReading)
                                .add(getAltitude(sensorReading))
                                .add(0.0)
                                .add(0.0)
                );
                sensorData = new BaroData(timestamp, block, baroValue, getAltitude(baroValue), 0.0, 0.0);
            }
            baroSensor.recordSensorData(sensorData);
        } else {
            baroSensor.writeHeaderToFile = true;
        }
    }

    private void visualizeData() {
        if (currentMax < baroValue) {
            currentMax = baroValue;
            statMax.setText(String.format(Locale.getDefault(), PSLabSensor.BAROMETER_DATA_FORMAT, baroValue));
        }
        if (currentMin > baroValue) {
            currentMin = baroValue;
            statMin.setText(String.format(Locale.getDefault(), PSLabSensor.BAROMETER_DATA_FORMAT, baroValue));
        }
        y.setAxisMaximum(currentMax);
        y.setAxisMinimum(currentMin);
        y.setLabelCount(10);
        y2.setAxisMaximum(getAltitude(currentMax));
        y2.setAxisMinimum(getAltitude(currentMin));
        y2.setLabelCount(10);
        if (baroValue >= 0) {
            baroMeter.setWithTremble(false);
            baroMeter.setSpeedAt(baroValue);
            if (baroValue > highLimit)
                baroMeter.setPointerColor(Color.RED);
            else
                baroMeter.setPointerColor(Color.WHITE);

            timeElapsed = ((System.currentTimeMillis() - startTime) / updatePeriod);
            if (timeElapsed != previousTimeElapsed) {
                previousTimeElapsed = timeElapsed;
                Entry entry = new Entry((float) timeElapsed, baroValue);
                Long currentTime = System.currentTimeMillis();
                writeLogToFile(currentTime, baroValue);
                pressureEntries.add(entry);
                altitudeEntries.add(new Entry((float) timeElapsed, getAltitude(baroValue)));

                count++;
                sum += entry.getY();
                statMean.setText(DataFormatter.formatDouble((sum / count), PSLabSensor.BAROMETER_DATA_FORMAT));
                altiValue.setText(String.format(Locale.getDefault(), PSLabSensor.BAROMETER_DATA_FORMAT, getAltitude(baroValue)));

                List<ILineDataSet> dataSets = new ArrayList<>();
                LineDataSet dataSet = new LineDataSet(pressureEntries, getString(R.string.baro_unit));
                dataSet.setDrawCircles(false);
                dataSet.setDrawValues(false);
                dataSet.setLineWidth(2);
                dataSets.add(dataSet);

                dataSet = new LineDataSet(altitudeEntries, getString(R.string.alti_unit));
                dataSet.setDrawCircles(false);
                dataSet.setDrawValues(false);
                dataSet.setLineWidth(2);
                dataSet.setColor(Color.YELLOW);
                dataSets.add(dataSet);
                LineData data = new LineData(dataSets);

                mChart.setData(data);
                mChart.notifyDataSetChanged();
                mChart.setVisibleXRangeMaximum(80);
                mChart.moveViewToX(data.getEntryCount());
                mChart.invalidate();
            }
        }
    }

    private SensorEventListener baroSensorEventListener = new SensorEventListener() {

        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) {/**/}

        @Override
        public void onSensorChanged(SensorEvent event) {
            if (event.sensor.getType() == Sensor.TYPE_PRESSURE) {
                baroValue = Float.valueOf(String.format(Locale.ROOT, PSLabSensor.BAROMETER_DATA_FORMAT, event.values[0] / 1000));
            }
        }
    };

    private void resetInstrumentData() {
        baroValue = 0;
        count = 0;
        currentMin = 2;
        currentMax = 0.5f;
        sum = 0;
        sensor = null;
        if (sensorManager != null) {
            sensorManager.unregisterListener(baroSensorEventListener);
        }
        startTime = System.currentTimeMillis();
        statMax.setText(DataFormatter.formatDouble(0, DataFormatter.LOW_PRECISION_FORMAT));
        statMin.setText(DataFormatter.formatDouble(0, DataFormatter.LOW_PRECISION_FORMAT));
        statMean.setText(DataFormatter.formatDouble(0, DataFormatter.LOW_PRECISION_FORMAT));
        altiValue.setText(DataFormatter.formatDouble(0, DataFormatter.LOW_PRECISION_FORMAT));
        baroMeter.setSpeedAt(0);
        baroMeter.setWithTremble(false);
        pressureEntries.clear();
        altitudeEntries.clear();
    }

    private void initiateBaroSensor(int type) {
        BaroMeterDataFragment.BARO_SENSOR s = BaroMeterDataFragment.BARO_SENSOR.values()[type];
        resetInstrumentData();
        ScienceLab scienceLab;
        switch (s) {
            case INBUILT_SENSOR:
                sensorLabel.setText(getResources().getStringArray(R.array.baro_sensors)[0]);
                sensorManager = (SensorManager) getContext().getSystemService(SENSOR_SERVICE);
                sensor = sensorManager.getDefaultSensor(Sensor.TYPE_PRESSURE);
                if (sensor == null) {
                    CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content),
                            getResources().getString(R.string.no_baro_sensor), null, null, Snackbar.LENGTH_LONG);
                } else {
                    float max = sensor.getMaximumRange() / 1000;
                    PreferenceManager.getDefaultSharedPreferences(getActivity()).edit().putFloat(baroSensor.BAROMETER_LIMIT, max).apply();
                    baroMeter.setMaxSpeed(max);
                    sensorManager.registerListener(baroSensorEventListener,
                            sensor, SensorManager.SENSOR_DELAY_FASTEST);
                }
                break;
            case BMP180_SENSOR:
                sensorLabel.setText(getResources().getStringArray(R.array.baro_sensors)[1]);
                scienceLab = ScienceLabCommon.scienceLab;
                if (scienceLab.isConnected()) {
                    ArrayList<Integer> data;
                    try {
                        I2C i2c = scienceLab.i2c;
                        data = i2c.scan(null);
                        if (data.contains(0x23)) {
                            BMP180 sensorBMP180 = new BMP180(i2c, scienceLab);
                            sensorBMP180.setOversampling(10);
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
            default:
                break;
        }
    }

    private float getAltitude(float pressure) {
        if (pressure <= 0.0) {
            return 0;
        } else {
            return (float) (44330 * (1 - Math.pow(pressure, 1.0 / 5.255)));
        }
    }
}