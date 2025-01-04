package io.pslab.sensors;

import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.text.Editable;
import android.util.Log;
import android.view.MenuItem;
import android.view.View;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.RelativeLayout;
import android.widget.SeekBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.components.Legend;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.interfaces.datasets.ILineDataSet;

import java.util.Locale;

import io.pslab.R;
import io.pslab.communication.ScienceLab;
import io.pslab.others.ScienceLabCommon;

abstract class AbstractSensorActivity extends AppCompatActivity {
    private static final String TAG = AbstractSensorActivity.class.getSimpleName();

    private static final String KEY_PLAY = TAG + "_play";
    private static final String KEY_RUN_INDEFINITELY = TAG + "_run_indefinitely";
    private static final String KEY_TIME_GAP = TAG + "_time_gap";
    private static final String KEY_FLAG = TAG + "_flag";
    private static final String KEY_START_TIME = TAG + "_start_time";
    private static final String KEY_COUNTER = TAG + "_counter";

    private int counter;
    private ScienceLab scienceLab;
    private long startTime;
    private int flag;
    private boolean play = false;
    private boolean runIndefinitely = true;
    private int timeGap = 100;

    private RelativeLayout sensorDock;
    private SeekBar timeGapSeekbar;
    private TextView timeGapLabel;
    private CheckBox indefiniteSamplesCheckBox;
    private EditText samplesEditBox;
    private ImageButton playPauseButton;

    private HandlerThread handlerThread;
    private Handler handler;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(getLayoutResId());

        if (savedInstanceState != null) {
            play = savedInstanceState.getBoolean(KEY_PLAY);
            runIndefinitely = savedInstanceState.getBoolean(KEY_RUN_INDEFINITELY);
            timeGap = savedInstanceState.getInt(KEY_TIME_GAP);
            flag = savedInstanceState.getInt(KEY_FLAG);
            startTime = savedInstanceState.getLong(KEY_START_TIME);
            counter = savedInstanceState.getInt(KEY_COUNTER);
        }

        sensorDock = findViewById(R.id.sensor_control_dock_layout);
        indefiniteSamplesCheckBox = sensorDock.findViewById(R.id.checkBox_samples_sensor);
        timeGapSeekbar = sensorDock.findViewById(R.id.seekBar_timegap_sensor);
        timeGapLabel = sensorDock.findViewById(R.id.tv_timegap_label);
        samplesEditBox = sensorDock.findViewById(R.id.editBox_samples_sensors);
        playPauseButton = sensorDock.findViewById(R.id.imageButton_play_pause_sensor);

        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        final ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setTitle(getTitleResId());
            actionBar.setDisplayHomeAsUpEnabled(true);
            actionBar.setDisplayShowHomeEnabled(true);
        }

        setSensorDock();
        sensorDock.setVisibility(View.VISIBLE);

        scienceLab = ScienceLabCommon.scienceLab;

        handlerThread = new HandlerThread("MyHandlerThread");
        handlerThread.start();
        Looper looper = handlerThread.getLooper();
        handler = new Handler(looper);

        if (play) {
            startTimerTask();
        }
    }

    @Override
    protected void onDestroy() {
        play = false;
        handlerThread.quit();
        super.onDestroy();
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);

        outState.putBoolean(KEY_PLAY, play);
        outState.putBoolean(KEY_RUN_INDEFINITELY, runIndefinitely);
        outState.putInt(KEY_TIME_GAP, timeGap);
        outState.putInt(KEY_FLAG, flag);
        outState.putLong(KEY_START_TIME, startTime);
    }

    @NonNull
    private Runnable getTimerTask() {

        return () -> {
            if (play && scienceLab.isConnected() && shouldPlay()) {
                if (flag == 0) {
                    startTime = System.currentTimeMillis();
                    flag = 1;
                }
                SensorDataFetch sensorDataFetch = getSensorDataFetch();
                if (sensorDataFetch == null) {
                    Log.w(TAG, "No SensorDataFetch!");
                } else {
                    sensorDataFetch.execute();
                }
                if (play) {
                    startTimerTask();
                }
            } else {
                setPlayButton(false);
            }
        };
    }

    private void startTimerTask() {
        handler.postDelayed(getTimerTask(), timeGap);
    }

    protected ScienceLab getScienceLab() {
        return scienceLab;
    }

    private void setSensorDock() {
        final int step = 1;
        final int max = 1000;
        final int min = 100;

        playPauseButton.setOnClickListener(v -> {
            if (play && scienceLab.isConnected()) {
                play = false;
            } else if (!scienceLab.isConnected()) {
                play = false;
            } else {
                play = true;
                startTimerTask();
                if (!indefiniteSamplesCheckBox.isChecked()) {
                    Editable text = samplesEditBox.getText();
                    counter = text.length() == 0 ? 0 : Integer.parseInt(text.toString());
                }
            }
            setPlayButton(play);
        });

        setPlayButton(play);

        sensorDock.setVisibility(View.VISIBLE);

        indefiniteSamplesCheckBox.setChecked(runIndefinitely);
        samplesEditBox.setEnabled(!runIndefinitely);
        samplesEditBox.setText(String.valueOf(counter));
        indefiniteSamplesCheckBox.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                runIndefinitely = true;
                samplesEditBox.setEnabled(false);
            } else {
                runIndefinitely = false;
                samplesEditBox.setEnabled(true);
            }
        });

        timeGapSeekbar.setMax((max - min) / step);
        timeGapSeekbar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                timeGap = min + (progress * step);
                timeGapLabel.setText(
                        String.format(
                                Locale.getDefault(),
                                "%d%s", timeGap, getString(R.string.unit_milliseconds)
                        )
                );
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                // nothing to do here
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                // nothing to do here
            }
        });
    }

    private void setPlayButton(boolean isPlaying) {
        playPauseButton.setImageResource(isPlaying ? R.drawable.circle_pause_button : R.drawable.circle_play_button);
    }

    protected boolean shouldPlay() {
        if (play) {
            if (indefiniteSamplesCheckBox.isChecked())
                return true;
            else if (counter > 0) {
                counter--;
                return true;
            } else {
                play = false;
                return false;
            }
        } else {
            return false;
        }
    }

    /**
     * Get time of first start of sensor data capture.
     *
     * @return time in ms
     */
    protected long getStartTime() {
        return startTime;
    }

    /**
     * Update data of a chart.
     *
     * @param chart       chart to update
     * @param timeElapsed time elapsed since last update of chart
     * @param dataSet     data set which contains data to display
     */
    protected static void updateChart(LineChart chart, float timeElapsed, ILineDataSet dataSet) {
        updateChart(chart, timeElapsed, new LineData(dataSet));
    }

    /**
     * Update data of a chart.
     *
     * @param chart       chart to update
     * @param timeElapsed time elapsed since last update of chart
     * @param dataSets    data sets which contains data to display
     */
    protected static void updateChart(LineChart chart, float timeElapsed, ILineDataSet... dataSets) {
        updateChart(chart, timeElapsed, new LineData(dataSets));
    }

    private static void updateChart(LineChart chart, float timeElapsed, LineData data) {
        data.setValueTextSize(0f); // turn off text
        chart.setData(data);
        chart.notifyDataSetChanged();
        chart.setVisibleXRangeMaximum(10);
        chart.moveViewToX(timeElapsed);
    }

    protected void initChart(LineChart chart) {
        XAxis x = chart.getXAxis();
        YAxis y = chart.getAxisLeft();
        YAxis y2 = chart.getAxisRight();

        chart.setTouchEnabled(true);
        chart.setHighlightPerDragEnabled(true);
        chart.setDragEnabled(true);
        chart.setScaleEnabled(true);
        chart.setDrawGridBackground(false);
        chart.setPinchZoom(true);
        chart.setScaleYEnabled(false);
        chart.setBackgroundColor(Color.BLACK);
        chart.getDescription().setEnabled(false);
        chart.setAutoScaleMinMaxEnabled(true);
        chart.setNoDataText(getString(R.string.no_data_fetched));
        chart.setNoDataTextColor(Color.YELLOW);
        chart.setNoDataTextTypeface(Typeface.MONOSPACE);

        Legend l = chart.getLegend();
        l.setForm(Legend.LegendForm.LINE);
        l.setTextColor(Color.WHITE);

        x.setTextColor(Color.WHITE);
        x.setDrawGridLines(true);
        x.setAvoidFirstLastClipping(true);

        y.setTextColor(Color.WHITE);
        y.setDrawGridLines(true);
        y.setLabelCount(10, true);
        y.setGranularity(0.1f);

        y2.setDrawGridLines(false);

    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finish();
        }
        return true;
    }

    protected abstract SensorDataFetch getSensorDataFetch();

    protected abstract int getLayoutResId();

    protected abstract int getTitleResId();

    protected abstract class SensorDataFetch {

        protected float getTimeElapsed() {
            return (System.currentTimeMillis() - getStartTime()) / 1000f;
        }

        protected void execute() {
            if (getSensorData()) {
                updateUi();
            }
        }

        /**
         * Does whatever is necessary to get data from sensor.
         *
         * @return {@code true} if data was fetched successfully, else {@code false}
         */
        abstract boolean getSensorData();

        /**
         * Called whenever new data is read from sensor.
         */
        abstract void updateUi();
    }
}
