package io.pslab.adapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.math.RoundingMode;
import java.text.DecimalFormat;

import io.pslab.R;
import io.pslab.activity.OscilloscopeActivity.ChannelMeasurements;
import io.pslab.activity.OscilloscopeActivity.CHANNEL;
import io.pslab.others.OscilloscopeMeasurements;

public class OscilloscopeMeasurementsAdapter extends RecyclerView.Adapter<OscilloscopeMeasurementsAdapter.ViewHolder> {

    private final String[] channels;
    private final Integer[] channelColors;

    public static class ViewHolder extends RecyclerView.ViewHolder {

        private final TextView measurementsView;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            this.measurementsView = itemView.findViewById(R.id.textview_measurements);
        }

        public void setMeasurements(@NonNull String channelString, @NonNull Integer channelColor) {
            CHANNEL channel = CHANNEL.valueOf(channelString);
            double frequency = OscilloscopeMeasurements.channel.get(channel).get(ChannelMeasurements.FREQUENCY);
            double amplitude = OscilloscopeMeasurements.channel.get(channel).get(ChannelMeasurements.AMPLITUDE);
            double period = OscilloscopeMeasurements.channel.get(channel).get(ChannelMeasurements.PERIOD);
            double positivePeak = OscilloscopeMeasurements.channel.get(channel).get(ChannelMeasurements.POSITIVE_PEAK);
            double negativePeak = OscilloscopeMeasurements.channel.get(channel).get(ChannelMeasurements.NEGATIVE_PEAK);
            DecimalFormat df = new DecimalFormat("0.00");
            df.setRoundingMode(RoundingMode.CEILING);
            if (frequency >= 1000) {
                frequency /= 1000;
                String string = "Vpp: " + df.format(amplitude) + " V\nVp+: " + df.format(positivePeak) + " V  Vp-: " + df.format(negativePeak) + " V\nf: " + df.format(frequency) + " kHz  P: " + df.format(period) + " ms";
                measurementsView.setTextColor(channelColor);
                measurementsView.setText(string);
            } else {
                String string = "Vpp: " + df.format(amplitude) + " V\nVp+: " + df.format(positivePeak) + " V  Vp-: " + df.format(negativePeak) + " V\nf: " + df.format(frequency) + " Hz  P: " + df.format(period) + " ms";
                measurementsView.setTextColor(channelColor);
                measurementsView.setText(string);
            }
        }
    }

    public OscilloscopeMeasurementsAdapter(@NonNull String[] channels, @NonNull Integer[] channelColors) {
        this.channels = channels;
        this.channelColors = channelColors;
    }

    @NonNull
    @Override
    public OscilloscopeMeasurementsAdapter.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View itemView = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.measurement_item, parent, false);
        return new ViewHolder(itemView);
    }

    @Override
    public void onBindViewHolder(@NonNull OscilloscopeMeasurementsAdapter.ViewHolder holder, int position) {
        holder.setMeasurements(channels[position], channelColors[position]);
    }

    @Override
    public int getItemCount() {
        return channels.length;
    }
}
