package io.pslab.fragment;

import android.Manifest;
import android.app.AlertDialog;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.Spinner;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;

import com.google.android.material.snackbar.Snackbar;

import io.pslab.DataFormatter;
import io.pslab.R;
import io.pslab.activity.OscilloscopeActivity;
import io.pslab.others.CustomSnackBar;
import io.pslab.others.OscilloscopeAxisScale;

public class ChannelParametersFragment extends Fragment {

    private static final int RECORD_AUDIO_REQUEST_CODE = 1;

    private static final double[] VOLTAGE_VALUES = {16, 8, 4, 3, 2, 1.5, 1, 0.5, 160};

    private Spinner spinnerRangeCh1;
    private Spinner spinnerRangeCh2;
    private Spinner spinnerChannelSelect;
    private CheckBox builtInMicCheckBox;
    private CheckBox pslabMicCheckBox;
    private OscilloscopeAxisScale axisScale;

    public static ChannelParametersFragment newInstance() {
        return new ChannelParametersFragment();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {

        View v = inflater.inflate(R.layout.fragment_channel_parameters, container, false);

        final String[] ranges = {"+/-16V", "+/-8V", "+/-4V", "+/-3V", "+/-2V", "+/-1" + DataFormatter.decSeparator + "5V", "+/-1V", "+/-500mV", "+/-160V"};
        final String[] channels = {"CH1", "CH2", "CH3", "MIC", "CAP", "RES", "VOL"};
        final String[] mics = {"MICROPHONE", "IN-BUILT MIC"};

        axisScale = ((OscilloscopeActivity) getActivity()).getAxisScale();

        spinnerRangeCh1 = v.findViewById(R.id.spinner_range_ch1_cp);
        spinnerRangeCh2 = v.findViewById(R.id.spinner_range_ch2_cp);
        spinnerChannelSelect = v.findViewById(R.id.spinner_channel_select_cp);

        boolean tabletSize = getResources().getBoolean(R.bool.isTablet);
        CheckBox checkBoxCH1 = v.findViewById(R.id.checkBox_ch1_cp);
        CheckBox checkBoxCH2 = v.findViewById(R.id.checkBox_ch2_cp);
        CheckBox checkBoxCH3 = v.findViewById(R.id.checkBox_ch3_cp);
        checkBoxCH3.setText(getString(R.string.ch3_value, 3.3));

        builtInMicCheckBox = v.findViewById(R.id.built_in_mic_cb);
        pslabMicCheckBox = v.findViewById(R.id.pslab_mic_cb);
        ArrayAdapter<String> rangesAdapter;
        ArrayAdapter<String> channelsAdapter;
        ArrayAdapter<String> micsAdapter;
        if (tabletSize) {
            rangesAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner_tablet, ranges);
            channelsAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner_tablet, channels);
            micsAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner_mic_tablet, mics);
        } else {
            rangesAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner, ranges);
            channelsAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner, channels);
            micsAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner_mic, mics);

        }
        rangesAdapter.setDropDownViewResource(android.R.layout.simple_dropdown_item_1line);
        channelsAdapter.setDropDownViewResource(android.R.layout.simple_dropdown_item_1line);
        micsAdapter.setDropDownViewResource(android.R.layout.simple_dropdown_item_1line);

        spinnerRangeCh1.setAdapter(rangesAdapter);
        spinnerRangeCh1.setSelection(rangesAdapter.getPosition("+/-16V"), true);
        spinnerRangeCh2.setAdapter(rangesAdapter);
        spinnerRangeCh2.setSelection(rangesAdapter.getPosition("+/-16V"), true);
        spinnerChannelSelect.setAdapter(channelsAdapter);
        spinnerChannelSelect.setSelection(channelsAdapter.getPosition("CH1"), true);

        spinnerRangeCh1.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                axisScale.setLeftYAxisScale(VOLTAGE_VALUES[position]);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        spinnerRangeCh2.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                axisScale.setRightYAxisScale(VOLTAGE_VALUES[position]);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        spinnerChannelSelect.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                switch (position) {
                    case 0:
                        ((OscilloscopeActivity) getActivity()).setLeftYAxisLabel(spinnerChannelSelect.getSelectedItem().toString());
                        spinnerRangeCh1.setEnabled(true);
                        break;
                    case 1:
                        axisScale.setLeftYAxisScale(16, -16);
                        ((OscilloscopeActivity) getActivity()).setLeftYAxisLabel(spinnerChannelSelect.getSelectedItem().toString());
                        spinnerRangeCh1.setEnabled(false);
                        break;
                    case 2:
                        axisScale.setLeftYAxisScale(3, -3);
                        ((OscilloscopeActivity) getActivity()).setLeftYAxisLabel(spinnerChannelSelect.getSelectedItem().toString());
                        spinnerRangeCh1.setEnabled(false);
                        break;
                    case 3:
                        axisScale.setLeftYAxisScale(3, -3);
                        ((OscilloscopeActivity) getActivity()).setLeftYAxisLabel(spinnerChannelSelect.getSelectedItem().toString());
                        break;
                    case 4:
                        axisScale.setLeftYAxisScale(3, 0);
                        ((OscilloscopeActivity) getActivity()).setLeftYAxisLabel(spinnerChannelSelect.getSelectedItem().toString());
                        spinnerRangeCh1.setEnabled(false);
                        break;
                    case 5:
                        axisScale.setLeftYAxisScale(3, 0);
                        ((OscilloscopeActivity) getActivity()).setLeftYAxisLabel(spinnerChannelSelect.getSelectedItem().toString());
                        spinnerRangeCh1.setEnabled(false);
                        break;
                    case 6:
                        axisScale.setLeftYAxisScale(3, 0);
                        ((OscilloscopeActivity) getActivity()).setLeftYAxisLabel(spinnerChannelSelect.getSelectedItem().toString());
                        spinnerRangeCh1.setEnabled(false);
                        break;
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        checkBoxCH1.setOnCheckedChangeListener((buttonView, isChecked) -> ((OscilloscopeActivity) getActivity()).isCH1Selected = isChecked);

        checkBoxCH2.setOnCheckedChangeListener((buttonView, isChecked) -> ((OscilloscopeActivity) getActivity()).isCH2Selected = isChecked);

        checkBoxCH3.setOnCheckedChangeListener((buttonView, isChecked) -> ((OscilloscopeActivity) getActivity()).isCH3Selected = isChecked);
        builtInMicCheckBox.setOnCheckedChangeListener((buttonView, isChecked) -> {
            ((OscilloscopeActivity) getActivity()).isInBuiltMicSelected = isChecked;
            ((OscilloscopeActivity) getActivity()).isAudioInputSelected = isChecked;
            if (isChecked) {
                ((OscilloscopeActivity) getActivity()).maxTimebase = 38.4f;
                if (pslabMicCheckBox.isChecked()) {
                    ((OscilloscopeActivity) getActivity()).isMICSelected = false;
                    pslabMicCheckBox.setChecked(false);
                    ((OscilloscopeActivity) getActivity()).isAudioInputSelected = true;
                }
                if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO}, RECORD_AUDIO_REQUEST_CODE);
                    ((OscilloscopeActivity) getActivity()).isAudioInputSelected = false;
                }
            } else {
                ((OscilloscopeActivity) getActivity()).maxTimebase = 102.4f;
            }
        });

        pslabMicCheckBox.setOnCheckedChangeListener((buttonView, isChecked) -> {
            ((OscilloscopeActivity) getActivity()).isMICSelected = isChecked;
            ((OscilloscopeActivity) getActivity()).isAudioInputSelected = isChecked;
            if (isChecked) {
                if (builtInMicCheckBox.isChecked()) {
                    ((OscilloscopeActivity) getActivity()).isInBuiltMicSelected = false;
                    builtInMicCheckBox.setChecked(false);
                    ((OscilloscopeActivity) getActivity()).isAudioInputSelected = true;
                }
                if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO}, RECORD_AUDIO_REQUEST_CODE);
                    ((OscilloscopeActivity) getActivity()).isAudioInputSelected = false;
                }
            }
        });
        return v;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == RECORD_AUDIO_REQUEST_CODE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                ((OscilloscopeActivity) getActivity()).isInBuiltMicSelected = true;
            } else {
                CustomSnackBar.showSnackBar(getActivity().findViewById(android.R.id.content), "This feature won't work.", null, null, Snackbar.LENGTH_SHORT);
                if (builtInMicCheckBox.isChecked()) builtInMicCheckBox.toggle();
            }
        }
    }

    private void openAlertDialogBox(String inputSource) {
        new AlertDialog.Builder(getActivity()).setIcon(android.R.drawable.ic_dialog_alert).setTitle("Message").setMessage("Connect a 10MOhm resistor with " + inputSource).setPositiveButton("OK", (dialog, which) -> {
        }).show();
    }
}
