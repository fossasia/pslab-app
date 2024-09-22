package io.pslab.fragment;

import android.os.Bundle;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.fragment.app.Fragment;

import org.apache.commons.lang3.math.NumberUtils;

import io.pslab.R;
import io.pslab.activity.OscilloscopeActivity;
import io.pslab.others.FloatSeekBar;
import io.pslab.others.OscilloscopeAxisScale;

public class TimebaseTriggerFragment extends Fragment {

    private Spinner spinnerTriggerChannelSelect;
    private Spinner spinnerTriggerModeSelect;
    private FloatSeekBar seekBarTrigger;
    private TextView textViewTimeBase;
    private EditText editTextTrigger;
    private OscilloscopeAxisScale axisScale;
    private boolean ignore = false;


    public static TimebaseTriggerFragment newInstance() {
        return new TimebaseTriggerFragment();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {

        View v = inflater.inflate(R.layout.fragment_timebase_tigger, container, false);

        //seekBarTimebase = (SeekBar) v.findViewById(R.id.seekBar_timebase_tt);
        FloatSeekBar seekBarTimebase = v.findViewById(R.id.seekBar_timebase_tt);
        seekBarTrigger = v.findViewById(R.id.seekBar_trigger);
        textViewTimeBase = v.findViewById(R.id.tv_timebase_values_tt);
        editTextTrigger = v.findViewById(R.id.tv_trigger_values_tt);
        spinnerTriggerChannelSelect = v.findViewById(R.id.spinner_trigger_channel_tt);
        spinnerTriggerModeSelect = v.findViewById(R.id.spinner_trigger_mode_tt);
        CheckBox checkBoxTrigger = v.findViewById(R.id.checkbox_trigger_tt);
        seekBarTimebase.setSaveEnabled(false);

        axisScale = ((OscilloscopeActivity) this.getActivity()).getAxisScale();

        boolean tabletSize = getResources().getBoolean(R.bool.isTablet);

        if (tabletSize) {
            editTextTrigger.setTextSize(TypedValue.COMPLEX_UNIT_SP, 18);
            textViewTimeBase.setTextSize(TypedValue.COMPLEX_UNIT_SP, 18);
        }

        if (OscilloscopeActivity.isInBuiltMicSelected) {
            seekBarTimebase.setMax(6);
            seekBarTimebase.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override
                public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                    //samples are in the power of 2 so that sinefit can be applied
                    switch (progress) {
                        case 0:
                            textViewTimeBase.setText(getString(R.string.timebase_microsec, 875f));
                            axisScale.setXAxisScale(0.875);
                            ((OscilloscopeActivity) getActivity()).timebase = 875;
                            ((OscilloscopeActivity) getActivity()).samples = 512;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 1:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 1f));
                            axisScale.setXAxisScale(1);
                            ((OscilloscopeActivity) getActivity()).timebase = 1000;
                            ((OscilloscopeActivity) getActivity()).samples = 512;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 2:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 2f));
                            axisScale.setXAxisScale(2);
                            ((OscilloscopeActivity) getActivity()).timebase = 2000;
                            ((OscilloscopeActivity) getActivity()).samples = 512;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 3:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 4f));
                            axisScale.setXAxisScale(4);
                            ((OscilloscopeActivity) getActivity()).timebase = 4000;
                            ((OscilloscopeActivity) getActivity()).samples = 512;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 4:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 8f));
                            axisScale.setXAxisScale(8);
                            ((OscilloscopeActivity) getActivity()).timebase = 8000;
                            ((OscilloscopeActivity) getActivity()).samples = 1024;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 5:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 25.60));
                            axisScale.setXAxisScale(25.60);
                            ((OscilloscopeActivity) getActivity()).timebase = 25600;
                            ((OscilloscopeActivity) getActivity()).samples = 1024;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 6:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 38.40));
                            axisScale.setXAxisScale(38.40);
                            ((OscilloscopeActivity) getActivity()).timebase = 38400;
                            ((OscilloscopeActivity) getActivity()).samples = 1024;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        default:
                            break;
                    }
                }

                @Override
                public void onStartTrackingTouch(SeekBar seekBar) {

                }

                @Override
                public void onStopTrackingTouch(SeekBar seekBar) {

                }
            });
            seekBarTimebase.setProgress(0);
        } else {
            seekBarTimebase.setMax(8);
            seekBarTimebase.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override
                public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                    //samples are in the power of 2 so that sinefit can be applied
                    switch (progress) {
                        case 0:
                            textViewTimeBase.setText(getString(R.string.timebase_microsec, 875f));
                            axisScale.setXAxisScale(0.875);
                            ((OscilloscopeActivity) getActivity()).timebase = 875;
                            ((OscilloscopeActivity) getActivity()).samples = 512;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 1:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 1f));
                            axisScale.setXAxisScale(1);
                            ((OscilloscopeActivity) getActivity()).timebase = 1000;
                            ((OscilloscopeActivity) getActivity()).samples = 512;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 2:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 2f));
                            axisScale.setXAxisScale(2);
                            ((OscilloscopeActivity) getActivity()).timebase = 2000;
                            ((OscilloscopeActivity) getActivity()).samples = 512;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 3:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 4f));
                            axisScale.setXAxisScale(4);
                            ((OscilloscopeActivity) getActivity()).timebase = 4000;
                            ((OscilloscopeActivity) getActivity()).samples = 512;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 4:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 8f));
                            axisScale.setXAxisScale(8);
                            ((OscilloscopeActivity) getActivity()).timebase = 8000;
                            ((OscilloscopeActivity) getActivity()).samples = 1024;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 5:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 25.60));
                            axisScale.setXAxisScale(25.60);
                            ((OscilloscopeActivity) getActivity()).timebase = 25600;
                            ((OscilloscopeActivity) getActivity()).samples = 1024;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 6:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 38.40));
                            axisScale.setXAxisScale(38.40);
                            ((OscilloscopeActivity) getActivity()).timebase = 38400;
                            ((OscilloscopeActivity) getActivity()).samples = 1024;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 7:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 51.20));
                            axisScale.setXAxisScale(51.20);
                            ((OscilloscopeActivity) getActivity()).timebase = 51200;
                            ((OscilloscopeActivity) getActivity()).samples = 1024;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        case 8:
                            textViewTimeBase.setText(getString(R.string.timebase_milisec, 102.40));
                            axisScale.setXAxisScale(102.40);
                            ((OscilloscopeActivity) getActivity()).timebase = 102400;
                            ((OscilloscopeActivity) getActivity()).samples = 1024;
                            ((OscilloscopeActivity) getActivity()).timeGap = (2 * ((OscilloscopeActivity) getActivity()).timebase) / ((OscilloscopeActivity) getActivity()).samples;
                            break;
                        default:
                            break;
                    }
                }

                @Override
                public void onStartTrackingTouch(SeekBar seekBar) {

                }

                @Override
                public void onStopTrackingTouch(SeekBar seekBar) {

                }
            });
            seekBarTimebase.setProgress(0);
        }
        seekBarTrigger.setters(-1 * axisScale.getLeftYAxisScaleUpper(), axisScale.getLeftYAxisScaleUpper());
        seekBarTrigger.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (!ignore) {
                    editTextTrigger.setText(String.format("%s V", seekBarTrigger.getValue()));
                    ((OscilloscopeActivity) getActivity()).trigger = seekBarTrigger.getValue();
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        });
        seekBarTrigger.setProgress(50);

        String[] channels = {"CH1", "CH2", "CH3", "MIC"};
        ArrayAdapter<String> channelsAdapter;
        if (tabletSize) {
            channelsAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner_tablet, channels);
        } else {
            channelsAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner, channels);
        }

        channelsAdapter.setDropDownViewResource(android.R.layout.simple_dropdown_item_1line);

        spinnerTriggerChannelSelect.setAdapter(channelsAdapter);
        spinnerTriggerChannelSelect.setSelection(channelsAdapter.getPosition("CH1"), true);
        spinnerTriggerChannelSelect.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                ((OscilloscopeActivity) getActivity()).triggerChannel = spinnerTriggerChannelSelect.getItemAtPosition(position).toString();
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        String[] modes = {"Rising Edge", "Falling Edge", "Dual Edge"};
        ArrayAdapter<String> modesAdapter;
        if (tabletSize) {
            modesAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner_tablet, modes);
        } else {
            modesAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner, modes);
        }

        modesAdapter.setDropDownViewResource(android.R.layout.simple_dropdown_item_1line);

        spinnerTriggerModeSelect.setAdapter(modesAdapter);
        spinnerTriggerModeSelect.setSelection(modesAdapter.getPosition("Rising Edge"), true);
        ((OscilloscopeActivity) getActivity()).triggerMode = "RISING";
        spinnerTriggerModeSelect.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                switch (spinnerTriggerModeSelect.getItemAtPosition(position).toString()) {
                    case "Rising Edge":
                        ((OscilloscopeActivity) getActivity()).triggerMode = "RISING";
                        break;
                    case "Falling Edge":
                        ((OscilloscopeActivity) getActivity()).triggerMode = "FALLING";
                        break;
                    case "Dual Edge":
                        ((OscilloscopeActivity) getActivity()).triggerMode = "DUAL";
                        break;
                    default:
                        break;
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                // Do nothing
            }
        });

        editTextTrigger.setOnTouchListener((v1, event) -> {
            editTextTrigger.setCursorVisible(true);
            return false;
        });

        editTextTrigger.setOnEditorActionListener((textView, i, keyEvent) -> {
            if (i == EditorInfo.IME_ACTION_DONE) {
                String voltageValue = editTextTrigger.getText().toString().replace("V", "");
                voltageValue = voltageValue.replace(" ", "");
                if (NumberUtils.isCreatable(voltageValue)) {
                    ignore = true;
                    if (Double.parseDouble(voltageValue) > axisScale.getLeftYAxisScaleUpper()) {
                        editTextTrigger.setText(String.format("%s V", axisScale.getLeftYAxisScaleUpper()));
                        seekBarTrigger.setValue(axisScale.getLeftYAxisScaleUpper());
                        ((OscilloscopeActivity) getActivity()).trigger = seekBarTrigger.getValue();
                        ignore = false;
                    } else if (Double.parseDouble(voltageValue) < -axisScale.getLeftYAxisScaleUpper()) {
                        editTextTrigger.setText(String.format("%s V", -axisScale.getLeftYAxisScaleUpper()));
                        seekBarTrigger.setValue(-axisScale.getLeftYAxisScaleUpper());
                        ((OscilloscopeActivity) getActivity()).trigger = seekBarTrigger.getValue();
                        ignore = false;
                    } else {
                        seekBarTrigger.setValue(Double.parseDouble(voltageValue));
                        editTextTrigger.setText(String.format("%s V", Double.parseDouble(voltageValue)));
                        ((OscilloscopeActivity) getActivity()).trigger = seekBarTrigger.getValue();
                        ignore = false;
                    }
                } else {
                    seekBarTrigger.setProgress(50);
                }
            }
            editTextTrigger.setCursorVisible(false);
            return false;
        });

        checkBoxTrigger.setOnCheckedChangeListener((buttonView, isChecked) -> ((OscilloscopeActivity) getActivity()).isTriggerSelected = isChecked);

        return v;
    }
}