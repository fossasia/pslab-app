package io.pslab.fragment;

import android.os.Bundle;
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

import androidx.fragment.app.Fragment;

import io.pslab.R;
import io.pslab.activity.OscilloscopeActivity;
import io.pslab.others.FloatSeekBar;
import io.pslab.others.OscilloscopeAxisScale;

public class DataAnalysisFragment extends Fragment {

    private Spinner spinnerChannelSelect1;
    private Spinner spinnerChannelSelect2;
    private Spinner spinnerChannelSelectHorizontalOffset;
    private Spinner spinnerChannelSelectVerticalOffset;
    private FloatSeekBar seekBarHorizontalOffset;
    private FloatSeekBar seekBarVerticalOffset;
    private EditText editTextHorizontalOffset;
    private EditText editTextVerticalOffset;
    private OscilloscopeAxisScale axisScale;
    private boolean ignore = false;

    public static DataAnalysisFragment newInstance() {
        return new DataAnalysisFragment();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View v = inflater.inflate(R.layout.fragment_data_analysis_main, container, false);
        String[] curveFits = {"Sine Fit", "Square Fit"};
        String[] channels = {"None", "CH1", "CH2", "CH3", "MIC"};

        Spinner spinnerCurveFit = v.findViewById(R.id.spinner_curve_fit_da);
        spinnerChannelSelect1 = v.findViewById(R.id.spinner_channel_select_da1);
        spinnerChannelSelect2 = v.findViewById(R.id.spinner_channel_select_da2);
        spinnerChannelSelectHorizontalOffset = v.findViewById(R.id.spinner_channel_select_horizontal_offset);
        spinnerChannelSelectVerticalOffset = v.findViewById(R.id.spinner_channel_select_vertical_offset);
        seekBarHorizontalOffset = v.findViewById(R.id.seekbar_horizontal_offset);
        seekBarVerticalOffset = v.findViewById(R.id.seekbar_vertical_offset);
        editTextHorizontalOffset = v.findViewById(R.id.edittext_horizontal_offset);
        editTextVerticalOffset = v.findViewById(R.id.edittext_vertical_offset);
        CheckBox checkBoxFouierTransform = v.findViewById(R.id.checkBox_fourier_da);
        boolean tabletSize = getResources().getBoolean(R.bool.isTablet);
        ArrayAdapter<String> curveFitAdapter;
        ArrayAdapter<String> adapter;

        axisScale = ((OscilloscopeActivity) this.getActivity()).getAxisScale();

        if (tabletSize) {
            curveFitAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner_tablet, curveFits);
            adapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner_tablet, channels);
        } else {
            curveFitAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner, curveFits);
            adapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner, channels);
        }

        curveFitAdapter.setDropDownViewResource(android.R.layout.simple_dropdown_item_1line);
        adapter.setDropDownViewResource(android.R.layout.simple_dropdown_item_1line);

        spinnerCurveFit.setAdapter(curveFitAdapter);
        spinnerChannelSelect1.setAdapter(adapter);
        spinnerChannelSelect2.setAdapter(adapter);
        spinnerChannelSelectHorizontalOffset.setAdapter(adapter);
        spinnerChannelSelectVerticalOffset.setAdapter(adapter);

        spinnerCurveFit.setSelection(curveFitAdapter.getPosition("Sine Fit"), true);
        spinnerChannelSelect1.setSelection(adapter.getPosition("None"), true);
        spinnerChannelSelect2.setSelection(adapter.getPosition("None"), true);
        spinnerChannelSelectHorizontalOffset.setSelection(adapter.getPosition("None"), true);
        spinnerChannelSelectVerticalOffset.setSelection(adapter.getPosition("None"), true);

        spinnerCurveFit.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                if (position == 0) {
                    ((OscilloscopeActivity) getActivity()).sineFit = true;
                    ((OscilloscopeActivity) getActivity()).squareFit = false;
                } else {
                    ((OscilloscopeActivity) getActivity()).sineFit = false;
                    ((OscilloscopeActivity) getActivity()).squareFit = true;
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        spinnerChannelSelect1.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                ((OscilloscopeActivity) getActivity()).curveFittingChannel1 = spinnerChannelSelect1.getItemAtPosition(position).toString();
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        spinnerChannelSelect2.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                ((OscilloscopeActivity) getActivity()).curveFittingChannel2 = spinnerChannelSelect2.getItemAtPosition(position).toString();
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        spinnerChannelSelectHorizontalOffset.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> adapterView, View view, int i, long l) {
                if (spinnerChannelSelectHorizontalOffset.getSelectedItem() != "None") {
                    seekBarHorizontalOffset.setValue(((OscilloscopeActivity) getActivity()).xOffsets.get(spinnerChannelSelectHorizontalOffset.getSelectedItem().toString()));
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> adapterView) {
                // Do nothing
            }
        });

        spinnerChannelSelectVerticalOffset.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> adapterView, View view, int i, long l) {
                if (spinnerChannelSelectVerticalOffset.getSelectedItem() != "None") {
                    seekBarVerticalOffset.setValue(((OscilloscopeActivity) getActivity()).yOffsets.get(spinnerChannelSelectVerticalOffset.getSelectedItem().toString()));
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> adapterView) {
                // Do nothing
            }
        });

        if (axisScale.getXAxisScale() == 875) {
            seekBarHorizontalOffset.setters(0, axisScale.getXAxisScale() / 1000.0);
        } else {
            seekBarHorizontalOffset.setters(0, axisScale.getXAxisScale());
        }
        seekBarHorizontalOffset.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int i, boolean b) {
                if (!ignore) {
                    editTextHorizontalOffset.setText(String.format("%s", seekBarHorizontalOffset.getValue()));
                    ((OscilloscopeActivity) getActivity()).xOffsets.put(spinnerChannelSelectHorizontalOffset.getSelectedItem().toString(), seekBarHorizontalOffset.getValue());
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                // Do nothing
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                // Do nothing
            }
        });
        seekBarHorizontalOffset.setProgress(100);
        seekBarHorizontalOffset.setProgress(0);

        seekBarVerticalOffset.setters(-1 * axisScale.getLeftYAxisScaleUpper(), axisScale.getLeftYAxisScaleUpper());
        seekBarVerticalOffset.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int i, boolean b) {
                if (!ignore) {
                    editTextVerticalOffset.setText(String.format("%s", seekBarVerticalOffset.getValue()));
                    ((OscilloscopeActivity) getActivity()).yOffsets.put(spinnerChannelSelectVerticalOffset.getSelectedItem().toString(), seekBarVerticalOffset.getValue());
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                // Do nothing
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                // Do nothing
            }
        });
        seekBarVerticalOffset.setProgress(50);

        editTextHorizontalOffset.setOnTouchListener((v1, event) -> {
            editTextHorizontalOffset.setCursorVisible(true);
            return false;
        });

        editTextHorizontalOffset.setOnEditorActionListener((textView, i, keyEvent) -> {
            if (i == EditorInfo.IME_ACTION_DONE) {
                if (!editTextHorizontalOffset.getText().toString().isEmpty() && !editTextHorizontalOffset.getText().toString().equals("-") && !editTextHorizontalOffset.getText().toString().equals(".") && !editTextVerticalOffset.getText().toString().equals("-.")) {
                    double xAxisScale = (axisScale.getXAxisScale() == 875) ? axisScale.getXAxisScale() / 1000.0 : axisScale.getXAxisScale();
                    ignore = true;
                    if (Double.parseDouble(editTextHorizontalOffset.getText().toString()) > xAxisScale) {
                        editTextHorizontalOffset.setText(String.format("%s", xAxisScale));
                        seekBarHorizontalOffset.setValue(xAxisScale);
                        ((OscilloscopeActivity) getActivity()).xOffsets.put(spinnerChannelSelectHorizontalOffset.getSelectedItem().toString(), seekBarHorizontalOffset.getValue());
                        ignore = false;
                    } else {
                        seekBarHorizontalOffset.setValue(Double.parseDouble(editTextHorizontalOffset.getText().toString()));
                        editTextHorizontalOffset.setText(String.format("%s", Double.parseDouble(editTextHorizontalOffset.getText().toString())));
                        ((OscilloscopeActivity) getActivity()).xOffsets.put(spinnerChannelSelectHorizontalOffset.getSelectedItem().toString(), seekBarHorizontalOffset.getValue());
                        ignore = false;
                    }
                } else {
                    seekBarHorizontalOffset.setProgress(0);
                }
            }
            editTextHorizontalOffset.setCursorVisible(false);
            return false;
        });

        editTextVerticalOffset.setOnTouchListener((v12, event) -> {
            editTextVerticalOffset.setCursorVisible(true);
            return false;
        });

        editTextVerticalOffset.setOnEditorActionListener((textView, i, keyEvent) -> {
            if (i == EditorInfo.IME_ACTION_DONE) {
                if (!editTextVerticalOffset.getText().toString().isEmpty() && !editTextVerticalOffset.getText().toString().equals("-") && !editTextVerticalOffset.getText().toString().equals(".") && !editTextVerticalOffset.getText().toString().equals("-.")) {
                    ignore = true;
                    if (Double.parseDouble(editTextVerticalOffset.getText().toString()) > axisScale.getXAxisScale()) {
                        editTextVerticalOffset.setText(String.format("%s", axisScale.getXAxisScale()));
                        seekBarVerticalOffset.setValue(axisScale.getXAxisScale());
                        ((OscilloscopeActivity) getActivity()).yOffsets.put(spinnerChannelSelectVerticalOffset.getSelectedItem().toString(), seekBarVerticalOffset.getValue());
                        ignore = false;
                    } else if (Double.parseDouble(editTextVerticalOffset.getText().toString()) < -axisScale.getXAxisScale()) {
                        editTextVerticalOffset.setText(String.format("%s", -axisScale.getXAxisScale()));
                        seekBarVerticalOffset.setValue(-axisScale.getXAxisScale());
                        ((OscilloscopeActivity) getActivity()).yOffsets.put(spinnerChannelSelectVerticalOffset.getSelectedItem().toString(), seekBarVerticalOffset.getValue());
                        ignore = false;
                    } else {
                        seekBarVerticalOffset.setValue(Double.parseDouble(editTextVerticalOffset.getText().toString()));
                        editTextVerticalOffset.setText(String.format("%s", Double.parseDouble(editTextVerticalOffset.getText().toString())));
                        ((OscilloscopeActivity) getActivity()).yOffsets.put(spinnerChannelSelectVerticalOffset.getSelectedItem().toString(), seekBarVerticalOffset.getValue());
                        ignore = false;
                    }
                } else {
                    seekBarVerticalOffset.setProgress(50);
                }
            }
            editTextVerticalOffset.setCursorVisible(false);

            return false;
        });

        checkBoxFouierTransform.setOnCheckedChangeListener((buttonView, isChecked) -> ((OscilloscopeActivity) getActivity()).setFourierTransformSelected(isChecked));
        return v;
    }
}
