package io.pslab.fragment;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.Spinner;

import androidx.fragment.app.Fragment;

import io.pslab.R;
import io.pslab.activity.OscilloscopeActivity;
import io.pslab.others.OscilloscopeAxisScale;
import io.pslab.others.ViewGroupUtils;

public class XYPlotFragment extends Fragment {

    private Spinner spinnerChannelSelect1;
    private Spinner spinnerChannelSelect2;
    private CheckBox checkBoxXYPlot;
    private OscilloscopeAxisScale axisScale;

    public static XYPlotFragment newInstance() {
        return new XYPlotFragment();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View v = inflater.inflate(R.layout.fragment_xyplot, container, false);
        final String[] channels = {"CH1", "CH2", "CH3", "MIC"};
        spinnerChannelSelect1 = v.findViewById(R.id.spinner_channel_select_xy1);
        spinnerChannelSelect2 = v.findViewById(R.id.spinner_channel_select_xy2);
        checkBoxXYPlot = v.findViewById(R.id.checkBox_enable_xy_xy);

        axisScale = ((OscilloscopeActivity) getActivity()).getAxisScale();

        spinnerChannelSelect1.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> adapterView, View view, int position, long l) {
                ((OscilloscopeActivity) getActivity()).xyPlotAxis1 = channels[position];
                if (((OscilloscopeActivity) getActivity()).isXYPlotSelected) {
                    ((OscilloscopeActivity) getActivity()).setXAxisLabel(channels[position]);
                    ((OscilloscopeActivity) getActivity()).xAxisLabelUnit.setText("(V)");
                }

            }

            @Override
            public void onNothingSelected(AdapterView<?> adapterView) {

            }
        });
        spinnerChannelSelect2.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {

            @Override
            public void onItemSelected(AdapterView<?> adapterView, View view, int position, long l) {
                ((OscilloscopeActivity) getActivity()).xyPlotAxis2 = channels[position];
                if (((OscilloscopeActivity) getActivity()).isXYPlotSelected) {
                    ((OscilloscopeActivity) getActivity()).setLeftYAxisLabel(channels[position]);
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> adapterView) {

            }
        });
        boolean tabletSize = getResources().getBoolean(R.bool.isTablet);
        ArrayAdapter<String> channelsAdapter;

        if (tabletSize) {
            channelsAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner_tablet, channels);
        } else {
            channelsAdapter = new ArrayAdapter<>(this.getActivity(), R.layout.custom_spinner, channels);
        }

        channelsAdapter.setDropDownViewResource(android.R.layout.simple_dropdown_item_1line);

        spinnerChannelSelect1.setAdapter(channelsAdapter);
        spinnerChannelSelect2.setAdapter(channelsAdapter);

        spinnerChannelSelect1.setSelection(channelsAdapter.getPosition("CH1"), true);
        spinnerChannelSelect2.setSelection(channelsAdapter.getPosition("CH2"), true);

        checkBoxXYPlot.setOnCheckedChangeListener((buttonView, isChecked) -> {
            ((OscilloscopeActivity) getActivity()).isXYPlotSelected = isChecked;
            if (isChecked) {
                ViewGroupUtils.replaceView(((OscilloscopeActivity) getActivity()).mChart,
                        ((OscilloscopeActivity) getActivity()).graph);
                ((OscilloscopeActivity) getActivity()).setXAxisLabel(spinnerChannelSelect1.getSelectedItem().toString());
                ((OscilloscopeActivity) getActivity()).setLeftYAxisLabel(spinnerChannelSelect2.getSelectedItem().toString());
                ((OscilloscopeActivity) getActivity()).xAxisLabelUnit.setText("(V)");
                ((OscilloscopeActivity) getActivity()).rightYAxisLabel.setVisibility(View.INVISIBLE);
                ((OscilloscopeActivity) getActivity()).rightYAxisLabelUnit.setVisibility(View.INVISIBLE);


            } else {
                ViewGroupUtils.replaceView(((OscilloscopeActivity) getActivity()).graph,
                        ((OscilloscopeActivity) getActivity()).mChart);
                ((OscilloscopeActivity) getActivity()).rightYAxisLabel.setVisibility(View.VISIBLE);
                ((OscilloscopeActivity) getActivity()).rightYAxisLabelUnit.setVisibility(View.VISIBLE);
                ((OscilloscopeActivity) getActivity()).setXAxisLabel("time");
                axisScale.setXAxisScale(((OscilloscopeActivity) getActivity()).timebase);

            }

        });

        return v;
    }
}
