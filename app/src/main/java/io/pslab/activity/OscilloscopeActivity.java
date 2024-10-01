package io.pslab.activity;


import static io.pslab.others.AudioJack.SAMPLING_RATE;
import static io.pslab.others.MathUtils.map;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Point;
import android.location.Location;
import android.location.LocationManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.view.Display;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.IdRes;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.DefaultItemAnimator;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.components.Legend;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.data.LineDataSet;
import com.github.mikephil.charting.interfaces.datasets.ILineDataSet;
import com.google.android.material.snackbar.Snackbar;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.math3.complex.Complex;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;
import java.util.Timer;
import java.util.TimerTask;

import butterknife.BindView;
import butterknife.ButterKnife;
import io.pslab.R;
import io.pslab.activity.guide.GuideActivity;
import io.pslab.adapters.OscilloscopeMeasurementsAdapter;
import io.pslab.communication.AnalyticsClass;
import io.pslab.communication.ScienceLab;
import io.pslab.fragment.ChannelParametersFragment;
import io.pslab.fragment.DataAnalysisFragment;
import io.pslab.fragment.OscilloscopePlaybackFragment;
import io.pslab.fragment.TimebaseTriggerFragment;
import io.pslab.fragment.XYPlotFragment;
import io.pslab.models.OscilloscopeData;
import io.pslab.models.SensorDataBlock;
import io.pslab.others.AudioJack;
import io.pslab.others.CSVDataLine;
import io.pslab.others.CSVLogger;
import io.pslab.others.CustomSnackBar;
import io.pslab.others.GPSLogger;
import io.pslab.others.LocalDataLog;
import io.pslab.others.OscilloscopeAxisScale;
import io.pslab.others.OscilloscopeMeasurements;
import io.pslab.others.Plot2D;
import io.pslab.others.ScienceLabCommon;
import io.realm.Realm;
import io.realm.RealmObject;
import io.realm.RealmResults;

public class OscilloscopeActivity extends GuideActivity implements View.OnClickListener, OscilloscopeAxisScale.AxisScaleSetListener {

    private static final CSVDataLine CSV_HEADER = new CSVDataLine()
            .add("Timestamp")
            .add("DateTime")
            .add("Mode")
            .add("Channel")
            .add("xData")
            .add("yData")
            .add("Timebase")
            .add("lat")
            .add("lon");
    private final Object lock = new Object();
    @BindView(R.id.chart_os)
    public LineChart mChart;
    @BindView(R.id.tv_label_left_yaxis_os)
    public TextView leftYAxisLabel;
    @BindView(R.id.tv_unit_left_yaxis_os)
    public TextView leftYAxisLabelUnit;
    @BindView(R.id.tv_label_right_yaxis_os)
    public TextView rightYAxisLabel;
    @BindView(R.id.tv_unit_right_yaxis_os)
    public TextView rightYAxisLabelUnit;
    @BindView(R.id.tv_graph_label_xaxis_os)
    public TextView xAxisLabel;
    @BindView(R.id.tv_unit_xaxis_os)
    public TextView xAxisLabelUnit;
    public int samples;
    public double timeGap;
    public double timebase;
    public double maxTimebase = 102.4f;
    public boolean isCH1Selected;
    public boolean isCH2Selected;
    public boolean isCH3Selected;
    public boolean isMICSelected;
    public static boolean isInBuiltMicSelected;
    public boolean isAudioInputSelected;
    public boolean isTriggerSelected;
    public boolean isTriggered;
    private boolean isFourierTransformSelected;
    public boolean isXYPlotSelected;
    private boolean isDataAnalysisFragSelected;
    public boolean sineFit;
    public boolean squareFit;
    public String triggerChannel;
    public String triggerMode;
    public String curveFittingChannel1;
    public String curveFittingChannel2;
    public HashMap<String, Double> xOffsets;
    public HashMap<String, Double> yOffsets;
    public double trigger;
    public Plot2D graph;
    @BindView(R.id.layout_dock_os1)
    LinearLayout linearLayout;
    @BindView(R.id.layout_dock_os2)
    FrameLayout frameLayout;
    @BindView(R.id.layout_chart_os)
    RelativeLayout mChartLayout;
    @BindView(R.id.button_channel_parameters_os)
    ImageButton channelParametersButton;
    @BindView(R.id.button_timebase_os)
    ImageButton timebaseButton;
    @BindView(R.id.button_data_analysis_os)
    ImageButton dataAnalysisButton;
    @BindView(R.id.button_xy_plot_os)
    ImageButton xyPlotButton;
    @BindView(R.id.tv_channel_parameters_os)
    TextView channelParametersTextView;
    @BindView(R.id.tv_timebase_tigger_os)
    TextView timebaseTiggerTextView;
    @BindView(R.id.tv_data_analysis_os)
    TextView dataAnalysisTextView;
    @BindView(R.id.tv_xy_plot_os)
    TextView xyPlotTextView;
    @BindView(R.id.parent_layout)
    View parentLayout;
    @BindView(R.id.recyclerView)
    RecyclerView measurementsList;
    private Fragment channelParametersFragment;
    private Fragment timebaseTriggerFragment;
    private Fragment dataAnalysisFragment;
    private Fragment xyPlotFragment;
    private Fragment playbackFragment;
    private ScienceLab scienceLab;
    private int height;
    private int width;
    private XAxis x1;
    private YAxis y1;
    private YAxis y2;
    private XYPlotTask xyPlotTask;
    private AudioJack audioJack = null;
    private AnalyticsClass analyticsClass;
    private CaptureTask captureTask;
    private Thread monitorThread;
    private volatile boolean monitor = true;
    private double maxAmp, maxFreq;
    private boolean isRecording = false;
    private boolean isRunning = true;
    private boolean isMeasurementsChecked = false;
    private Realm realm;
    public RealmResults<OscilloscopeData> recordedOscilloscopeData;
    private CSVLogger csvLogger;
    private GPSLogger gpsLogger;
    private long block;
    private Timer recordTimer;
    private final long recordPeriod = 100;
    private String loggingXdata = "";
    private final String KEY_LOG = "has_log";
    private final String DATA_BLOCK = "data_block";
    private int currentPosition = 0;
    private Timer playbackTimer;
    private View mainLayout;
    private double lat;
    private double lon;
    public boolean isPlaybackFourierChecked = false;
    private HashMap<String, Integer> channelIndexMap;
    public static final Integer[] channelColors = {Color.CYAN, Color.GREEN, Color.WHITE, Color.MAGENTA};
    private final String[] loggingYdata = new String[4];
    public String xyPlotAxis1 = "CH1";
    public String xyPlotAxis2 = "CH2";
    private boolean isPlayingback = false;
    private boolean isPlaying = false;
    private MenuItem playMenu;
    private ArrayList<ArrayList<Entry>> dataEntries = new ArrayList<>();
    private String[] dataParamsChannels;

    private OscilloscopeAxisScale axisScale;

    public enum CHANNEL {CH1, CH2, CH3, MIC}

    private enum MODE {RISING, FALLING, DUAL}

    public enum ChannelMeasurements {FREQUENCY, PERIOD, AMPLITUDE, POSITIVE_PEAK, NEGATIVE_PEAK}

    public OscilloscopeActivity() {
        super(R.layout.activity_oscilloscope);
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);
        final int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
        getWindow().getDecorView().setSystemUiVisibility(flags);
        final View decorView = getWindow().getDecorView();
        decorView.setOnSystemUiVisibilityChangeListener(i -> {
            if ((i & View.SYSTEM_UI_FLAG_FULLSCREEN) == 0) {
                decorView.setSystemUiVisibility(flags);
            }
        });
        ButterKnife.bind(this);

        removeStatusBar();
        mainLayout = findViewById(R.id.oscilloscope_mail_layout);

        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        final ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setTitle(R.string.oscilloscope);
            actionBar.setDisplayHomeAsUpEnabled(true);
            actionBar.setDisplayShowHomeEnabled(true);
        }

        channelIndexMap = new HashMap<>();
        channelIndexMap.put(CHANNEL.CH1.toString(), 1);
        channelIndexMap.put(CHANNEL.CH2.toString(), 2);
        channelIndexMap.put(CHANNEL.CH3.toString(), 3);
        channelIndexMap.put(CHANNEL.MIC.toString(), 4);

        realm = LocalDataLog.with().getRealm();
        gpsLogger = new GPSLogger(this,
                (LocationManager) getSystemService(Context.LOCATION_SERVICE));
        csvLogger = new CSVLogger(getString(R.string.oscilloscope));

        scienceLab = ScienceLabCommon.scienceLab;
        x1 = mChart.getXAxis();
        y1 = mChart.getAxisLeft();
        y2 = mChart.getAxisRight();
        triggerChannel = CHANNEL.CH1.toString();
        trigger = 0;
        timebase = 875;
        samples = 512;
        timeGap = 2;

        axisScale = new OscilloscopeAxisScale();
        axisScale.addAxisScaledListener(this);

        xOffsets = new HashMap<>();
        xOffsets.put(CHANNEL.CH1.toString(), 0.0);
        xOffsets.put(CHANNEL.CH2.toString(), 0.0);
        xOffsets.put(CHANNEL.CH3.toString(), 0.0);
        xOffsets.put(CHANNEL.MIC.toString(), 0.0);
        yOffsets = new HashMap<>();
        yOffsets.put(CHANNEL.CH1.toString(), 0.0);
        yOffsets.put(CHANNEL.CH2.toString(), 0.0);
        yOffsets.put(CHANNEL.CH3.toString(), 0.0);
        yOffsets.put(CHANNEL.MIC.toString(), 0.0);

        sineFit = true;
        squareFit = false;
        isDataAnalysisFragSelected = false;
        graph = new Plot2D(this, new float[]{}, new float[]{}, 1);
        curveFittingChannel1 = "None";
        curveFittingChannel2 = "None";
        analyticsClass = new AnalyticsClass();

        Display display = getWindowManager().getDefaultDisplay();
        Point size = new Point();
        display.getSize(size);
        width = size.x;
        height = size.y;

        onWindowFocusChanged();

        channelParametersFragment = new ChannelParametersFragment();
        timebaseTriggerFragment = new TimebaseTriggerFragment();
        dataAnalysisFragment = new DataAnalysisFragment();
        xyPlotFragment = new XYPlotFragment();
        playbackFragment = new OscilloscopePlaybackFragment();

        if (findViewById(R.id.layout_dock_os2) != null) {
            addFragment(R.id.layout_dock_os2, channelParametersFragment);
        }

        channelParametersButton.setOnClickListener(this);
        timebaseButton.setOnClickListener(this);
        dataAnalysisButton.setOnClickListener(this);
        xyPlotButton.setOnClickListener(this);
        channelParametersTextView.setOnClickListener(this);
        timebaseTiggerTextView.setOnClickListener(this);
        dataAnalysisTextView.setOnClickListener(this);
        xyPlotTextView.setOnClickListener(this);

        measurementsList = findViewById(R.id.recyclerView);

        chartInit();

        final Runnable runnable = new Runnable() {

            private final List<String> channels = new ArrayList<>();

            @Override
            public void run() {
                //Thread to check which checkbox is enabled
                while (monitor) {
                    if (isRunning) {
                        if (isInBuiltMicSelected && audioJack == null) {
                            audioJack = new AudioJack("input");
                        }

                        channels.clear();

                        if (scienceLab.isConnected() && isXYPlotSelected) {
                            xyPlotTask = new XYPlotTask();
                            xyPlotTask.execute(xyPlotAxis1, xyPlotAxis2);
                            synchronized (lock) {
                                try {
                                    lock.wait();
                                } catch (InterruptedException e) {
                                    e.printStackTrace();
                                }
                            }
                        } else {
                            if (scienceLab.isConnected()) {
                                if (isCH1Selected) {
                                    channels.add(CHANNEL.CH1.toString());
                                }
                                if (isCH2Selected) {
                                    channels.add(CHANNEL.CH2.toString());
                                }
                                if (isCH3Selected) {
                                    channels.add(CHANNEL.CH3.toString());
                                }
                            }
                            if (isAudioInputSelected && isInBuiltMicSelected || (scienceLab.isConnected() && isMICSelected)) {
                                channels.add(CHANNEL.MIC.toString());
                            }
                            captureTask = new CaptureTask();
                            captureTask.execute(channels.toArray(new String[0]));
                            synchronized (lock) {
                                try {
                                    lock.wait();
                                } catch (InterruptedException e) {
                                    e.printStackTrace();
                                }
                            }
                        }

                        if ((!isInBuiltMicSelected) && audioJack != null) {
                            audioJack.release();
                            audioJack = null;
                        }

                        if (!(((isCH1Selected || isCH2Selected || isCH3Selected || isMICSelected) && scienceLab.isConnected()) || isInBuiltMicSelected) && !mChart.isEmpty()) {
                            mChart.post(() -> mChart.clearValues());
                        }
                    }
                }
            }
        };
        monitorThread = new Thread(runnable);
        monitorThread.start();

        if (getIntent().getExtras() != null && getIntent().getExtras().getBoolean(KEY_LOG)) {
            recordedOscilloscopeData = LocalDataLog.with()
                    .getBlockOfOscilloscopeRecords(getIntent().getExtras().getLong(DATA_BLOCK));
            isPlayingback = true;
            setLayoutForPlayback();
        }
    }

    @SuppressLint("NewApi")
    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            getWindow().getDecorView().setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.activity_landscape_menu, menu);
        return true;
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        playMenu = menu.findItem(R.id.play_data);
        menu.findItem(R.id.record_pause_data).setVisible(!isPlayingback);
        menu.findItem(R.id.play_data).setVisible(isPlayingback);
        return super.onPrepareOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                finish();
                break;
            case R.id.run_stop:
                if (isRunning) {
                    isRunning = false;
                    item.setTitle(R.string.control_run);
                } else {
                    isRunning = true;
                    item.setTitle(R.string.control_stop);
                }
                break;
            case R.id.record_pause_data:
                if (isRecording) {
                    isRecording = false;
                    item.setIcon(R.drawable.ic_record_white);
                    CustomSnackBar.showSnackBar(mainLayout,
                            getString(R.string.csv_store_text) + " " + csvLogger.getCurrentFilePath()
                            , getString(R.string.open), view -> {
                                Intent intent = new Intent(OscilloscopeActivity.this, DataLoggerActivity.class);
                                intent.putExtra(DataLoggerActivity.CALLER_ACTIVITY, getResources().getString(R.string.oscilloscope));
                                startActivity(intent);
                            }, Snackbar.LENGTH_SHORT);
                } else if (!isRecording && !scienceLab.isConnected()) {
                    CustomSnackBar.showSnackBar(mainLayout, getString(R.string.device_not_connected), null, null, Snackbar.LENGTH_SHORT);

                } else {
                    isRecording = true;
                    item.setIcon(R.drawable.ic_record_stop_white);
                    block = System.currentTimeMillis();
                    if (gpsLogger.isGPSEnabled()) {
                        Location location = gpsLogger.getDeviceLocation();
                        if (location != null) {
                            lat = location.getLatitude();
                            lon = location.getLongitude();
                        } else {
                            lat = 0.0;
                            lon = 0.0;
                        }
                    } else {
                        lat = 0.0;
                        lon = 0.0;
                    }
                    csvLogger = new CSVLogger(getResources().getString(R.string.oscilloscope));
                    csvLogger.prepareLogFile();
                    csvLogger.writeMetaData(getResources().getString(R.string.oscilloscope));
                    csvLogger.writeCSVFile(CSV_HEADER);
                    recordSensorDataBlockID(new SensorDataBlock(block, getResources().getString(R.string.oscilloscope)));
                    CustomSnackBar.showSnackBar(mainLayout, getString(R.string.data_recording_start), null, null, Snackbar.LENGTH_SHORT);
                }
                break;
            case R.id.show_guide:
                toggleGuide();
                break;
            case R.id.show_logged_data:
                Intent intent = new Intent(OscilloscopeActivity.this, DataLoggerActivity.class);
                intent.putExtra(DataLoggerActivity.CALLER_ACTIVITY, getResources().getString(R.string.oscilloscope));
                startActivity(intent);
                break;
            case R.id.play_data:
                if (isPlaying) {
                    isPlaying = false;
                    item.setIcon(R.drawable.ic_play_arrow_white_24dp);
                    pauseData();
                } else {
                    isPlaying = true;
                    item.setIcon(R.drawable.ic_pause_white_24dp);
                    playRecordedData();
                }
                break;
            case R.id.auto_scale:
                if (((isCH1Selected || isCH2Selected || isCH3Selected || isMICSelected) && scienceLab.isConnected()) || isInBuiltMicSelected) {
                    autoScale();
                }
                break;
            case R.id.measurements:
                if (!isMeasurementsChecked) {
                    isMeasurementsChecked = true;
                    item.setChecked(true);
                    measurementsList.setVisibility(View.VISIBLE);
                } else {
                    isMeasurementsChecked = false;
                    item.setChecked(false);
                    measurementsList.setVisibility(View.INVISIBLE);
                }
            default:
                break;
        }
        return true;
    }

    private void setLayoutForPlayback() {
        findViewById(R.id.layout_dock_os1).setVisibility(View.GONE);
        RelativeLayout.LayoutParams lineChartParams = (RelativeLayout.LayoutParams) mChartLayout.getLayoutParams();
        RelativeLayout.LayoutParams frameLayoutParams = (RelativeLayout.LayoutParams) frameLayout.getLayoutParams();
        lineChartParams.height = height * 3 / 4;
        lineChartParams.width = RelativeLayout.LayoutParams.MATCH_PARENT;
        mChartLayout.setLayoutParams(lineChartParams);
        frameLayoutParams.height = height / 4;
        frameLayoutParams.width = RelativeLayout.LayoutParams.MATCH_PARENT;
        frameLayout.setLayoutParams(frameLayoutParams);
        replaceFragment(R.id.layout_dock_os2, playbackFragment, "Playback Fragment");
    }

    public void playRecordedData() {
        final Handler handler = new Handler();
        if (playbackTimer == null) {
            playbackTimer = new Timer();
        }
        playbackTimer.schedule(new TimerTask() {
            @Override
            public void run() {
                handler.post(() -> {
                    try {
                        if (currentPosition < recordedOscilloscopeData.size()) {
                            OscilloscopeData data = recordedOscilloscopeData.get(currentPosition);
                            int mode = data.getMode();
                            List<ILineDataSet> dataSets = new ArrayList<>();
                            ArrayList<ArrayList<Entry>> entries = new ArrayList<>();
                            for (int i = 0; i < mode; i++) {
                                data = recordedOscilloscopeData.get(currentPosition);
                                entries.add(new ArrayList<>());
                                String[] xData = data.getDataX().split(" ");
                                String[] yData = data.getDataY().split(" ");
                                if (!isPlaybackFourierChecked) {
                                    int n = Math.min(xData.length, yData.length);
                                    for (int j = 0; j < n; j++) {
                                        if (xData[j].length() > 0 && yData[j].length() > 0) {
                                            entries.get(i).add(new Entry(Float.parseFloat(xData[j]), Float.parseFloat(yData[j])));
                                        }
                                    }
                                    axisScale.setLeftYAxisScale(16f, -16f);
                                    axisScale.setRightYAxisScale(16f, -16f);
                                    axisScale.setXAxisScale(data.getTimebase());
                                } else {
                                    Complex[] yComplex = new Complex[yData.length];
                                    for (int j = 0; j < yData.length; j++) {
                                        yComplex[j] = Complex.valueOf(Double.parseDouble(yData[j]));
                                    }
                                    Complex[] fftOut = fft(yComplex);
                                    int n = fftOut.length;
                                    double mA = 0;
                                    double factor = samples * timeGap * 1e-3;
                                    double mF = (n / 2 - 1) / factor;
                                    for (int j = 0; j < n / 2; j++) {
                                        float y = (float) fftOut[j].abs() / samples;
                                        if (y > mA) {
                                            mA = y;
                                        }
                                        entries.get(i).add(new Entry((float) (j / factor), y));
                                    }
                                    axisScale.setLeftYAxisScale(mA, 0);
                                    axisScale.setRightYAxisScale(mA, 0);
                                    axisScale.setXAxisScale(mF);
                                }
                                currentPosition++;
                                LineDataSet dataSet;
                                dataSet = new LineDataSet(entries.get(i), data.getChannel());
                                dataSet.setDrawCircles(false);
                                dataSet.setColor(channelColors[i]);
                                dataSets.add(dataSet);
                                ((OscilloscopePlaybackFragment) playbackFragment).setTimeBase(String.valueOf(data.getTimebase()));
                            }
                            LineData lineData = new LineData(dataSets);
                            mChart.setData(lineData);
                            mChart.notifyDataSetChanged();
                            mChart.invalidate();
                        } else {
                            playbackTimer.cancel();
                            playbackTimer = null;
                            playMenu.setIcon(R.drawable.ic_play_arrow_white_24dp);
                            currentPosition = 0;
                        }
                    } catch (Exception e) {
                        if (playbackTimer != null) {
                            playbackTimer.cancel();
                            playbackTimer = null;
                        }
                        playMenu.setIcon(R.drawable.ic_play_arrow_white_24dp);
                        currentPosition = 0;
                    }
                });

            }
        }, 0, recordPeriod);
    }

    public void pauseData() {
        if (playbackTimer != null) {
            playbackTimer.cancel();
            playbackTimer = null;
        }
    }

    public void setFourierTransformSelected(boolean isSelected) {
        isFourierTransformSelected = isSelected;

        if (!isFourierTransformSelected) {
            axisScale.setXAxisScale(OscilloscopeAxisScale.DEFAULT_X_AXIS_SCALE);
            axisScale.setLeftYAxisScale(OscilloscopeAxisScale.DEFAULT_Y_AXIS_SCALE);
            axisScale.setRightYAxisScale(OscilloscopeAxisScale.DEFAULT_Y_AXIS_SCALE);
        }
    }

    private void logChannelData(String[] channels) {
        long timestamp = System.currentTimeMillis();
        int noOfChannels = channels.length;
        String dateTime = CSVLogger.FILE_NAME_FORMAT.format(new Date(timestamp));
        for (int i = 0; i < noOfChannels; i++) {
            recordSensorData(new OscilloscopeData(timestamp + i, block, noOfChannels, channels[i], loggingXdata, loggingYdata[i], axisScale.getXAxisScale(), lat, lon));
            csvLogger.writeCSVFile(
                    new CSVDataLine()
                            .add(timestamp)
                            .add(dateTime)
                            .add(noOfChannels)
                            .add(channels[i])
                            .add(loggingXdata)
                            .add(loggingYdata[i])
                            .add(axisScale.getXAxisScale())
                            .add(lat)
                            .add(lon)
            );
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        removeStatusBar();
    }

    private void removeStatusBar() {
        if (Build.VERSION.SDK_INT < 16) {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    WindowManager.LayoutParams.FLAG_FULLSCREEN);
        } else {
            View decorView = getWindow().getDecorView();

            decorView.setSystemUiVisibility((View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY));
        }
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.button_channel_parameters_os:
            case R.id.tv_channel_parameters_os:
                replaceFragment(R.id.layout_dock_os2, channelParametersFragment, "ChannelParametersFragment");
                clearTextBackgroundColor();
                channelParametersTextView.setBackgroundColor(getResources().getColor(R.color.colorPrimaryDark));
                isDataAnalysisFragSelected = false;
                break;

            case R.id.button_timebase_os:
            case R.id.tv_timebase_tigger_os:
                replaceFragment(R.id.layout_dock_os2, timebaseTriggerFragment, "TimebaseTiggerFragment");
                clearTextBackgroundColor();
                timebaseTiggerTextView.setBackgroundColor(getResources().getColor(R.color.colorPrimaryDark));
                isDataAnalysisFragSelected = false;
                break;

            case R.id.button_data_analysis_os:
            case R.id.tv_data_analysis_os:
                replaceFragment(R.id.layout_dock_os2, dataAnalysisFragment, "DataAnalysisFragment");
                clearTextBackgroundColor();
                dataAnalysisTextView.setBackgroundColor(getResources().getColor(R.color.colorPrimaryDark));
                isDataAnalysisFragSelected = true;
                break;

            case R.id.button_xy_plot_os:
            case R.id.tv_xy_plot_os:
                replaceFragment(R.id.layout_dock_os2, xyPlotFragment, "XYPlotFragment");
                clearTextBackgroundColor();
                xyPlotTextView.setBackgroundColor(getResources().getColor(R.color.colorPrimaryDark));
                isDataAnalysisFragSelected = false;
                break;

            default:
                break;
        }
    }

    @SuppressLint("ResourceType")
    private void clearTextBackgroundColor() {
        channelParametersTextView.setBackgroundColor(getResources().getColor(R.color.customBorderFill));
        timebaseTiggerTextView.setBackgroundColor(getResources().getColor(R.color.customBorderFill));
        dataAnalysisTextView.setBackgroundColor(getResources().getColor(R.color.customBorderFill));
        xyPlotTextView.setBackgroundColor(getResources().getColor(R.color.customBorderFill));
    }

    public void onWindowFocusChanged() {
        RelativeLayout.LayoutParams lineChartParams = (RelativeLayout.LayoutParams) mChartLayout.getLayoutParams();
        RelativeLayout.LayoutParams frameLayoutParams = (RelativeLayout.LayoutParams) frameLayout.getLayoutParams();
        if (getResources().getBoolean(R.bool.isTablet)) {
            lineChartParams.height = height * 3 / 4;
            lineChartParams.width = width * 9 / 10;
            mChartLayout.setLayoutParams(lineChartParams);
            frameLayoutParams.height = height / 4;
            frameLayoutParams.width = width * 9 / 10;
            frameLayout.setLayoutParams(frameLayoutParams);
        } else {
            lineChartParams.height = height * 3 / 5;
            lineChartParams.width = width * 7 / 8;
            mChartLayout.setLayoutParams(lineChartParams);
            frameLayoutParams.height = height * 2 / 5;
            frameLayoutParams.width = width * 7 / 8;
            frameLayout.setLayoutParams(frameLayoutParams);
        }
    }

    protected void addFragment(@IdRes int containerViewId,
                               @NonNull Fragment fragment) {
        getSupportFragmentManager().beginTransaction()
                .add(containerViewId, fragment, "ChannelParametersFragment").commit();
    }

    protected void replaceFragment(@IdRes int containerViewId,
                                   @NonNull Fragment fragment,
                                   @NonNull String fragmentTag) {
        getSupportFragmentManager().beginTransaction()
                .replace(containerViewId, fragment, fragmentTag).commit();
    }

    @Override
    public void onBackPressed() {
        finish();
    }

    @Override
    protected void onDestroy() {
        monitor = false;
        if (captureTask != null) {
            captureTask.cancel(true);
        }
        if (recordTimer != null) {
            recordTimer.cancel();
            recordTimer = null;
        }
        if (audioJack != null) {
            audioJack.release();
            audioJack = null;
        }
        super.onDestroy();
    }

    public void chartInit() {
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

        x1.setTextColor(Color.WHITE);
        x1.setDrawGridLines(true);
        x1.setAvoidFirstLastClipping(true);
        x1.setAxisMinimum(0f);
        x1.setAxisMaximum(875f);

        y1.setTextColor(Color.WHITE);
        y1.setAxisMaximum(16f);
        y1.setAxisMinimum(-16f);
        y1.setDrawGridLines(true);

        y2.setAxisMaximum(16f);
        y2.setAxisMinimum(-16f);
        y2.setTextColor(Color.WHITE);
        y2.setEnabled(true);
    }

    public OscilloscopeAxisScale getAxisScale() {
        return axisScale;
    }

    @Override
    public void onXAxisScaleSet(double timebase) {
        x1.setAxisMinimum(0);
        x1.setAxisMaximum((float) timebase);
        if (timebase == 875f)
            xAxisLabelUnit.setText("(μs)");
        else
            xAxisLabelUnit.setText("(ms)");

        this.timebase = timebase;
        mChart.fitScreen();
        mChart.invalidate();
    }

    @Override
    public void onLeftYAxisScaleSet(double upperLimit, double lowerLimit) {
        y1.setAxisMaximum((float) upperLimit);
        y1.setAxisMinimum((float) lowerLimit);
        if (upperLimit == 500f)
            leftYAxisLabelUnit.setText("(mV)");
        else
            leftYAxisLabelUnit.setText("(V)");
        mChart.fitScreen();
        mChart.invalidate();
    }

    @Override
    public void onRightYAxisScaleSet(double upperLimit, double lowerLimit) {
        y2.setAxisMaximum((float) upperLimit);
        y2.setAxisMinimum((float) lowerLimit);
        if (upperLimit == 500f)
            rightYAxisLabelUnit.setText("(mV)");
        else
            rightYAxisLabelUnit.setText("(V)");
        mChart.fitScreen();
        mChart.invalidate();
    }

    public void setLeftYAxisLabel(String leftYAxisInput) {
        leftYAxisLabel.setText(leftYAxisInput);
    }

    public void setXAxisLabel(String xAxisInput) {
        xAxisLabel.setText(xAxisInput);
    }

    public class CaptureTask extends AsyncTask<String, Void, Void> {
        private final ArrayList<ArrayList<Entry>> entries = new ArrayList<>();
        private final ArrayList<ArrayList<Entry>> curveFitEntries = new ArrayList<>();
        private Integer noOfChannels;
        private String[] paramsChannels;
        private String channel;

        @Override
        protected Void doInBackground(String... channels) {
            paramsChannels = channels;
            noOfChannels = channels.length;
            if (isInBuiltMicSelected) {
                noOfChannels--;
            }
            try {
                double[] xData;
                double[] yData;
                double xValue;
                ArrayList<String[]> yDataString = new ArrayList<>();
                String[] xDataString = null;
                maxAmp = 0;
                scienceLab.captureTraces(4, samples, timeGap, channel, false, null);
                Thread.sleep((long) (samples * timeGap * 1e-3));
                for (int i = 0; i < noOfChannels; i++) {
                    entries.add(new ArrayList<>());
                    channel = channels[i];
                    isTriggered = false;
                    HashMap<String, double[]> data;
                    data = scienceLab.fetchTrace(channelIndexMap.get(channel));
                    xData = data.get("x");
                    yData = data.get("y");
                    xValue = xData[0];
                    int n = Math.min(xData.length, yData.length);
                    xDataString = new String[n];
                    yDataString.add(new String[n]);
                    Complex[] fftOut = null;
                    if (isFourierTransformSelected) {
                        Complex[] yComplex = new Complex[yData.length];
                        for (int j = 0; j < yData.length; j++) {
                            yComplex[j] = Complex.valueOf(yData[j]);
                        }
                        fftOut = fft(yComplex);
                    }
                    double factor = samples * timeGap * 1e-3;
                    maxFreq = (n / 2 - 1) / factor;
                    double mA = 0;
                    double prevY = yData[0];
                    boolean increasing = false;
                    for (int j = 0; j < n; j++) {
                        double currY = yData[j];
                        xData[j] = xData[j] / ((timebase == 875) ? 1 : 1000);
                        if (!isFourierTransformSelected) {
                            if (isTriggerSelected && triggerChannel.equals(channel)) {
                                if (currY > prevY) {
                                    increasing = true;
                                } else if (currY < prevY && increasing) {
                                    increasing = false;
                                }
                                if (isTriggered) {
                                    double k = xValue / ((timebase == 875) ? 1 : 1000);
                                    entries.get(i).add(new Entry((float) k, (float) yData[j]));
                                    xValue += timeGap;
                                }
                                if (Objects.equals(triggerMode, MODE.RISING.toString()) && prevY < trigger && currY >= trigger && increasing) {
                                    isTriggered = true;
                                } else if (Objects.equals(triggerMode, MODE.FALLING.toString()) && prevY > trigger && currY <= trigger && !increasing) {
                                    isTriggered = true;
                                } else if (Objects.equals(triggerMode, MODE.DUAL.toString()) && ((prevY < trigger && currY >= trigger && increasing) || (prevY > trigger && currY <= trigger && !increasing))) {
                                    isTriggered = true;
                                }
                                prevY = currY;
                            } else {
                                entries.get(i).add(new Entry((float) xData[j], (float) yData[j]));
                            }
                        } else {
                            if (j < n / 2) {
                                float y = (float) fftOut[j].abs() / samples;
                                if (y > mA) {
                                    mA = y;
                                }
                                entries.get(i).add(new Entry((float) (j / factor), y));
                            }
                        }
                        xDataString[j] = String.valueOf(xData[j]);
                        yDataString.get(i)[j] = String.valueOf(yData[j]);
                    }
                    if (sineFit && isDataAnalysisFragSelected && channel.equals(curveFittingChannel1)) {
                        if (curveFitEntries.size() == 0 || curveFitEntries.get(curveFitEntries.size() - 1) == null) {
                            curveFitEntries.add(new ArrayList<>());
                        }
                        double[] sinFit = analyticsClass.sineFit(xData, yData);
                        double amp = sinFit[0];
                        double freq = sinFit[1];
                        double offset = sinFit[2];
                        double phase = sinFit[3];

                        freq = freq / 1e6;
                        double max = xData[xData.length - 1];
                        for (int j = 0; j < 500; j++) {
                            double x = j * max / 500;
                            double y = offset + amp * Math.sin(Math.abs(freq * (2 * Math.PI)) * x + phase * Math.PI / 180);
                            curveFitEntries.get(curveFitEntries.size() - 1).add(new Entry((float) x, (float) y));
                        }
                    }

                    if (squareFit && isDataAnalysisFragSelected && channel.equals(curveFittingChannel1)) {
                        if (curveFitEntries.size() == 0 || curveFitEntries.get(curveFitEntries.size() - 1) == null) {
                            curveFitEntries.add(new ArrayList<>());
                        }
                        double[] sqFit = analyticsClass.squareFit(xData, yData);
                        double amp = sqFit[0];
                        double freq = sqFit[1];
                        double phase = sqFit[2];
                        double dc = sqFit[3];
                        double offset = sqFit[4];

                        freq = freq / 1e6;
                        double max = xData[xData.length - 1];
                        for (int j = 0; j < 500; j++) {
                            double x = j * max / 500;
                            double t = 2 * Math.PI * freq * (x - phase);
                            double y;
                            if (t % (2 * Math.PI) < 2 * Math.PI * dc) {
                                y = offset + amp;
                            } else {
                                y = offset - 2 * amp;
                            }
                            curveFitEntries.get(curveFitEntries.size() - 1).add(new Entry((float) x, (float) y));
                        }
                    }
                    if (mA > maxAmp) {
                        maxAmp = mA;
                    }
                }


                if (isInBuiltMicSelected) {
                    noOfChannels++;
                    isTriggered = false;
                    entries.add(new ArrayList<>());
                    if (audioJack == null) {
                        audioJack = new AudioJack("input");
                    }
                    short[] buffer = audioJack.read();
                    yDataString.add(new String[buffer.length]);

                    int n = buffer.length;
                    Complex[] fftOut = null;
                    if (isFourierTransformSelected) {
                        Complex[] yComplex = new Complex[n];
                        for (int j = 0; j < n; j++) {
                            float audioValue = (float) map(buffer[j], -32768, 32767, -3, 3);
                            yComplex[j] = Complex.valueOf(audioValue);
                        }
                        fftOut = fft(yComplex);
                    }
                    double factor = buffer.length * timeGap * 1e-3;
                    maxFreq = (n / 2 - 1) / factor;
                    double mA = 0;
                    if (xDataString == null) {
                        xDataString = new String[n];
                    }
                    float prevY = (float) map(buffer[0], -32768, 32767, -3, 3);
                    boolean increasing = false;
                    double xDataPoint = 0;
                    for (int i = 0; i < n; i++) {
                        float j = (float) (((double) i / SAMPLING_RATE) * 1000000.0);
                        j = j / ((timebase == 875) ? 1 : 1000);
                        float audioValue = (float) map(buffer[i], -32768, 32767, -3, 3);
                        float currY = audioValue;
                        if (!isFourierTransformSelected) {
                            if (noOfChannels == 1) {
                                xDataString[i] = String.valueOf(j);
                            }
                            if (isTriggerSelected && triggerChannel.equals(CHANNEL.MIC.toString())) {
                                if (currY > prevY) {
                                    increasing = true;
                                } else if (currY < prevY) {
                                    increasing = false;
                                }
                                if (Objects.equals(triggerMode, MODE.RISING.toString()) && prevY < trigger && currY >= trigger && increasing) {
                                    isTriggered = true;
                                } else if (Objects.equals(triggerMode, MODE.FALLING.toString()) && prevY > trigger && currY <= trigger && !increasing) {
                                    isTriggered = true;
                                } else if (Objects.equals(triggerMode, MODE.DUAL.toString()) && ((prevY < trigger && currY >= trigger && increasing) || (prevY > trigger && currY <= trigger && !increasing))) {
                                    isTriggered = true;
                                }
                                if (isTriggered) {
                                    float k = (float) ((xDataPoint / SAMPLING_RATE) * 1000000.0);
                                    k = k / ((timebase == 875) ? 1 : 1000);
                                    entries.get(entries.size() - 1).add(new Entry(k, audioValue));
                                    xDataPoint++;
                                }
                                prevY = currY;
                            } else {
                                entries.get(entries.size() - 1).add(new Entry(j, audioValue));
                            }
                        } else {
                            if (i < n / 2) {
                                float y = (float) fftOut[i].abs() / samples;
                                if (y > mA) {
                                    mA = y;
                                }
                                entries.get(entries.size() - 1).add(new Entry((float) (i / factor), y));
                            }
                        }
                        yDataString.get(yDataString.size() - 1)[i] = String.valueOf(audioValue);
                    }
                    if (mA > maxAmp) {
                        maxAmp = mA;
                    }

                }
                if (isRecording) {
                    loggingXdata = StringUtils.join(" ", xDataString);
                    for (int i = 0; i < yDataString.size(); i++) {
                        loggingYdata[i] = StringUtils.join(" ", yDataString.get(i));
                    }
                    runOnUiThread(() -> logChannelData(paramsChannels));
                }

            } catch (NullPointerException e) {
                cancel(true);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            return null;
        }

        @Override
        protected void onPostExecute(Void aVoid) {
            super.onPostExecute(aVoid);
            dataEntries = new ArrayList<>(entries);
            dataParamsChannels = paramsChannels.clone();

            List<ILineDataSet> dataSets = new ArrayList<>();
            if (!isFourierTransformSelected) {
                for (int i = 0; i < Math.min(entries.size(), paramsChannels.length); i++) {
                    ArrayList<Entry> entryArrayList = entries.get(i);
                    for (int j = 0; j < entryArrayList.size(); j++) {
                        Entry entry = entryArrayList.get(j);
                        entry.setX((float) (entry.getX() - xOffsets.get(paramsChannels[i])));
                        entry.setY((float) (entry.getY() + yOffsets.get(paramsChannels[i])));
                    }
                }
            }

            if (!isFourierTransformSelected) {
                for (int i = 0; i < Math.min(entries.size(), paramsChannels.length); i++) {
                    CHANNEL channel = CHANNEL.valueOf(paramsChannels[i]);
                    double minY = Double.MAX_VALUE;
                    double maxY = -1 * Double.MIN_VALUE;
                    double yRange;
                    double[] voltage = new double[512];
                    ArrayList<Entry> entryArrayList = dataEntries.get(i);
                    for (int j = 0; j < entryArrayList.size(); j++) {
                        Entry entry = entryArrayList.get(j);
                        if (j < voltage.length - 1) {
                            voltage[j] = entry.getY();
                        }
                        if (entry.getY() > maxY) {
                            maxY = entry.getY();
                        }
                        if (entry.getY() < minY) {
                            minY = entry.getY();
                        }
                    }
                    final double frequency;
                    if (Objects.equals(dataParamsChannels[i], CHANNEL.MIC.toString())) {
                        frequency = analyticsClass.findFrequency(voltage, ((double) 1 / SAMPLING_RATE));
                    } else {
                        frequency = analyticsClass.findFrequency(voltage, timeGap / 1000000.0);
                    }
                    double period = (1 / frequency) * 1000.0;
                    yRange = maxY - minY;
                    OscilloscopeMeasurements.channel.get(channel).put(ChannelMeasurements.FREQUENCY, frequency);
                    OscilloscopeMeasurements.channel.get(channel).put(ChannelMeasurements.PERIOD, period);
                    OscilloscopeMeasurements.channel.get(channel).put(ChannelMeasurements.AMPLITUDE, yRange);
                    OscilloscopeMeasurements.channel.get(channel).put(ChannelMeasurements.POSITIVE_PEAK, maxY);
                    OscilloscopeMeasurements.channel.get(channel).put(ChannelMeasurements.NEGATIVE_PEAK, minY);
                }
            }

            for (int i = 0; i < Math.min(entries.size(), paramsChannels.length); i++) {
                LineDataSet dataSet;
                dataSet = new LineDataSet(entries.get(i), paramsChannels[i]);
                dataSet.setDrawCircles(false);
                dataSet.setColor(channelColors[i]);
                dataSets.add(dataSet);

            }
            for (int i = 0; i < curveFitEntries.size(); i++) {
                LineDataSet dataSet;
                dataSet = new LineDataSet(curveFitEntries.get(i), "Fit");
                dataSet.setDrawCircles(false);
                dataSet.setColor(Color.YELLOW);
                dataSets.add(dataSet);
            }
            LineData data = new LineData(dataSets);
            if (isFourierTransformSelected) {
                axisScale.setXAxisScale(maxFreq);
                axisScale.setLeftYAxisScale(maxAmp, 0);
                axisScale.setRightYAxisScale(maxAmp, 0);
            }
            if (isMeasurementsChecked) {
                RecyclerView.LayoutManager layoutManager = new LinearLayoutManager(OscilloscopeActivity.this);
                measurementsList.setItemAnimator(new DefaultItemAnimator());
                measurementsList.setLayoutManager(layoutManager);
                OscilloscopeMeasurementsAdapter adapter = new OscilloscopeMeasurementsAdapter(dataParamsChannels, channelColors);
                measurementsList.setAdapter(adapter);
            }
            mChart.setData(data);
            mChart.notifyDataSetChanged();
            mChart.invalidate();
            synchronized (lock) {
                lock.notify();
            }
        }
    }

    public void autoScale() {
        double minY = Double.MAX_VALUE;
        double maxY = Double.MIN_VALUE;
        double maxPeriod = -1 * Double.MIN_VALUE;
        double yRange;
        double yPadding;
        double[] voltage = new double[512];
        for (int i = 0; i < dataParamsChannels.length; i++) {
            if (dataEntries.size() > i) {
                ArrayList<Entry> entryArrayList = dataEntries.get(i);
                for (int j = 0; j < entryArrayList.size(); j++) {
                    Entry entry = entryArrayList.get(j);
                    if (j < voltage.length - 1) {
                        voltage[j] = entry.getY();
                    }
                    if (entry.getY() > maxY) {
                        maxY = entry.getY();
                    }
                    if (entry.getY() < minY) {
                        minY = entry.getY();
                    }
                }
                final double frequency;
                if (Objects.equals(dataParamsChannels[i], CHANNEL.MIC.toString())) {
                    frequency = analyticsClass.findSignalFrequency(voltage, ((double) 1 / SAMPLING_RATE));
                } else {
                    frequency = analyticsClass.findSignalFrequency(voltage, timeGap / 1000000.0);
                }
                double period = (1 / frequency) * 1000.0;
                if (period > maxPeriod) {
                    maxPeriod = period;
                }
            }
        }
        yRange = maxY - minY;
        yPadding = yRange * 0.1;
        if (maxPeriod > 0) {
            double xAxisScale = Math.min((maxPeriod * 5), maxTimebase);
            double yAxisScale;
            if (Math.abs(maxY) >= Math.abs(minY)) {
                yAxisScale = maxY + yPadding;
            } else {
                yAxisScale = -1 * (minY - yPadding);
            }
            samples = 512;
            timeGap = (2 * xAxisScale * 1000.0) / samples;

            axisScale.setXAxisScale(xAxisScale);
            axisScale.setLeftYAxisScale(yAxisScale);
            axisScale.setRightYAxisScale(yAxisScale);
        } else {
            Toast.makeText(this, getString(R.string.auto_scale_error), Toast.LENGTH_SHORT).show();
        }
    }

    public class XYPlotTask extends AsyncTask<String, Void, Void> {
        private String analogInput1;
        private String analogInput2;
        private float[] xFloatData;
        private float[] yFloatData;

        @Override
        protected Void doInBackground(String... params) {
            analogInput1 = params[0];
            analogInput2 = params[1];
            HashMap<String, double[]> data;
            if (analogInput1.equals(analogInput2)) {
                scienceLab.captureTraces(1, samples, timeGap, analogInput1, isTriggerSelected, null);
                data = scienceLab.fetchTrace(1);
                double[] yData = data.get("y");
                int n = yData.length;
                xFloatData = new float[n];
                yFloatData = new float[n];
                for (int i = 0; i < n; i++) {
                    xFloatData[i] = (float) yData[i];
                    yFloatData[i] = (float) yData[i];
                }
            } else {
                int noChannels = 1;
                if ((analogInput1.equals(CHANNEL.CH1.toString()) && analogInput2.equals(CHANNEL.CH2.toString())) || (analogInput1.equals(CHANNEL.CH2.toString()) && analogInput2.equals(CHANNEL.CH1.toString()))) {
                    noChannels = 2;
                    scienceLab.captureTraces(noChannels, 175, timeGap, "CH1", isTriggerSelected, null);
                    data = scienceLab.fetchTrace(1);
                    double[] yData1 = data.get("y");
                    data = scienceLab.fetchTrace(2);
                    double[] yData2 = data.get("y");
                    int n = Math.min(yData1.length, yData2.length);
                    xFloatData = new float[n];
                    yFloatData = new float[n];
                    for (int i = 0; i < n; i++) {
                        xFloatData[i] = (float) yData1[i];
                        yFloatData[i] = (float) yData2[i];
                    }

                } else {
                    noChannels = 4;
                    scienceLab.captureTraces(noChannels, 175, timeGap, "CH1", isTriggerSelected, null);
                    data = scienceLab.fetchTrace(channelIndexMap.get(analogInput1) + 1);
                    double[] yData1 = data.get("y");
                    data = scienceLab.fetchTrace(channelIndexMap.get(analogInput2) + 1);
                    double[] yData2 = data.get("y");
                    int n = Math.min(yData1.length, yData2.length);
                    xFloatData = new float[n];
                    yFloatData = new float[n];
                    for (int i = 0; i < n; i++) {
                        xFloatData[i] = (float) yData1[i];
                        yFloatData[i] = (float) yData2[i];
                    }
                }

            }
            try {
                Thread.sleep(200);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            return null;
        }

        @Override
        protected void onPostExecute(Void aVoid) {
            super.onPostExecute(aVoid);
            graph.plotData(xFloatData, yFloatData, 1);
            synchronized (lock) {
                lock.notify();
            }
        }
    }

    public Complex[] fft(Complex[] input) {
        Complex[] x = input;
        int n = x.length;

        if (n == 1) return new Complex[]{x[0]};

        if (n % 2 != 0) {
            x = Arrays.copyOfRange(x, 0, x.length - 1);
        }

        Complex[] halfArray = new Complex[n / 2];
        for (int k = 0; k < n / 2; k++) {
            halfArray[k] = x[2 * k];
        }
        Complex[] q = fft(halfArray);

        for (int k = 0; k < n / 2; k++) {
            halfArray[k] = x[2 * k + 1];
        }
        Complex[] r = fft(halfArray);

        Complex[] y = new Complex[n];
        for (int k = 0; k < n / 2; k++) {
            double kth = -2 * k * Math.PI / n;
            Complex wk = new Complex(Math.cos(kth), Math.sin(kth));
            if (r[k] == null) {
                r[k] = new Complex(1);
            }
            if (q[k] == null) {
                q[k] = new Complex(1);
            }
            y[k] = q[k].add(wk.multiply(r[k]));
            y[k + n / 2] = q[k].subtract(wk.multiply(r[k]));
        }
        return y;
    }

    public void recordSensorDataBlockID(SensorDataBlock block) {
        realm.beginTransaction();
        realm.copyToRealm(block);
        realm.commitTransaction();
    }

    public void recordSensorData(RealmObject sensorData) {
        realm.beginTransaction();
        realm.copyToRealm((OscilloscopeData) sensorData);
        realm.commitTransaction();
    }
}