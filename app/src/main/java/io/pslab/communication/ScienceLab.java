package io.pslab.communication;

import static java.lang.Math.pow;
import static io.pslab.others.MathUtils.linSpace;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.math3.analysis.polynomials.PolynomialFunction;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

import io.pslab.activity.MainActivity;
import io.pslab.communication.analogChannel.AnalogAquisitionChannel;
import io.pslab.communication.analogChannel.AnalogConstants;
import io.pslab.communication.analogChannel.AnalogInputSource;
import io.pslab.communication.digitalChannel.DigitalChannel;
import io.pslab.communication.peripherals.DACChannel;
import io.pslab.communication.peripherals.I2C;
import io.pslab.fragment.HomeFragment;
import io.pslab.others.InitializationVariable;
import io.pslab.others.ScienceLabCommon;

public class ScienceLab {

    private static final String TAG = ScienceLab.class.getSimpleName();
    public static Thread initialisationThread;
    public int DDS_CLOCK, MAX_SAMPLES, samples, triggerLevel, triggerChannel, errorCount,
            channelsInBuffer, digitalChannelsInBuffer, dataSplitting;
    public double sin1Frequency, sin2Frequency;
    double[] currents, gainValues, buffer;
    int[] currentScalars;
    double SOCKET_CAPACITANCE, resistanceScaling, timebase;
    private static final double CAPACITOR_DISCHARGE_VOLTAGE = 0.01 * 3.3;
    private static final int CTMU_CHANNEL = 0b11110;
    public boolean streaming;
    String[] allAnalogChannels, allDigitalChannels;
    final HashMap<String, AnalogInputSource> analogInputSources = new HashMap<>();
    final HashMap<String, Double> squareWaveFrequency = new HashMap<>();
    final HashMap<String, Integer> gains = new HashMap<>();
    final HashMap<String, String> waveType = new HashMap<>();
    final ArrayList<AnalogAquisitionChannel> aChannels = new ArrayList<>();
    final ArrayList<DigitalChannel> dChannels = new ArrayList<>();
    public final Map<String, DACChannel> dacChannels = new LinkedHashMap<>();
    private final Map<String, Double> values = new LinkedHashMap<>();

    private CommunicationHandler mCommunicationHandler;
    private PacketHandler mPacketHandler;
    private final CommandsProto mCommandsProto;
    private final AnalogConstants mAnalogConstants;
    private int LAChannelFrequency;
    public I2C i2c;

    /**
     * Constructor
     *
     * @param communicationHandler
     */
    public ScienceLab(CommunicationHandler communicationHandler) {
        mCommandsProto = new CommandsProto();
        mAnalogConstants = new AnalogConstants();
        if (communicationHandler != null) {
            mCommunicationHandler = communicationHandler;
            if (isDeviceFound() && MainActivity.hasPermission) {
                try {
                    mCommunicationHandler.open(1000000);
                    //Thread.sleep(200);
                    mPacketHandler = new PacketHandler(50, mCommunicationHandler);
                } catch (IOException | NullPointerException e) {
                    Log.e(TAG, "Error opening connection", e);
                }
            }
        } else {
            mPacketHandler = new PacketHandler(50, null);
        }
        if (isConnected()) {
            initializeVariables();
            new Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    initialisationThread = new Thread(new Runnable() {

                        @Override
                        public void run() {
                            try {
                                runInitSequence();
                            } catch (IOException e) {
                                Log.e(TAG, "Error in initialisation", e);
                            }
                            new Handler(Looper.getMainLooper()).post(new Runnable() {
                                @Override
                                public void run() {
                                    if (HomeFragment.booleanVariable == null) {
                                        HomeFragment.booleanVariable = new InitializationVariable();
                                    }
                                    HomeFragment.booleanVariable.setVariable(true);
                                }
                            });
                        }
                    });
                    initialisationThread.start();

                }
            }, 1000);
        }
    }

    private void initializeVariables() {
        DDS_CLOCK = 0;
        timebase = 40;
        MAX_SAMPLES = mCommandsProto.MAX_SAMPLES;
        samples = MAX_SAMPLES;
        triggerChannel = 0;
        triggerLevel = 550;
        errorCount = 0;
        channelsInBuffer = 0;
        digitalChannelsInBuffer = 0;
        currents = new double[]{0.55e-3, 0.55e-6, 0.55e-5, 0.55e-4};
        currentScalars = new int[]{1, 2, 3, 0};
        dataSplitting = mCommandsProto.DATA_SPLITTING;
        allAnalogChannels = mAnalogConstants.allAnalogChannels;
        LAChannelFrequency = 0;
        for (String aChannel : allAnalogChannels) {
            analogInputSources.put(aChannel, new AnalogInputSource(aChannel));
        }
        sin1Frequency = 0;
        sin2Frequency = 0;
        squareWaveFrequency.put("SQR1", 0.0);
        squareWaveFrequency.put("SQR2", 0.0);
        squareWaveFrequency.put("SQR3", 0.0);
        squareWaveFrequency.put("SQR4", 0.0);
        if (CommunicationHandler.PSLAB_VERSION == 6) {
            dacChannels.put("PCS", new DACChannel("PCS", new double[]{0, 3.3}, 0, 0));
            dacChannels.put("PV3", new DACChannel("PV3", new double[]{0, 3.3}, 1, 1));
            dacChannels.put("PV2", new DACChannel("PV2", new double[]{-3.3, 3.3}, 2, 0));
            dacChannels.put("PV1", new DACChannel("PV1", new double[]{-5., 5.}, 3, 1));
        } else {
            dacChannels.put("PCS", new DACChannel("PCS", new double[]{0, 3.3}, 0, 0));
            dacChannels.put("PV3", new DACChannel("PV3", new double[]{0, 3.3}, 1, 1));
            dacChannels.put("PV2", new DACChannel("PV2", new double[]{-3.3, 3.3}, 2, 2));
            dacChannels.put("PV1", new DACChannel("PV1", new double[]{-5., 5.}, 3, 3));
        }
        values.put("PV1", 0.);
        values.put("PV2", 0.);
        values.put("PV3", 0.);
        values.put("PCS", 0.);
    }

    private void runInitSequence() throws IOException {
        fetchFirmwareVersion();
        ArrayList<String> aboutArray = new ArrayList<>();
        if (!isConnected()) {
            Log.e(TAG, "Check hardware connections. Not connected");
        }
        streaming = false;
        for (String aChannel : mAnalogConstants.biPolars) {
            aChannels.add(new AnalogAquisitionChannel(aChannel));
        }
        gainValues = mAnalogConstants.gains;
        this.buffer = new double[10000];
        Arrays.fill(this.buffer, 0);
        SOCKET_CAPACITANCE = 46e-12;
        resistanceScaling = 1;
        allDigitalChannels = DigitalChannel.digitalChannelNames;
        gains.put("CH1", 0);
        gains.put("CH2", 0);
        for (int i = 0; i < 4; i++) {
            dChannels.add(new DigitalChannel(i));
        }
        i2c = new I2C(mPacketHandler);
        if (isConnected()) {
            for (String temp : new String[]{"CH1", "CH2"}) {
                this.setGain(temp, 0, true);
            }
            for (String temp : new String[]{"SI1", "SI2"}) {
                loadEquation(temp, "sine");
            }
        }
        this.clearBuffer(0, samples);
    }

    /**
     * @return Resistance of connected resistor between RES an GND pins
     */
    public Double getResistance() {
        double volt = this.getAverageVoltage("RES", null);
        if (volt > 3.295) return null;
        double current = (3.3 - volt) / 5.1e3;
        return (volt / current) * this.resistanceScaling;
    }

    public String getVersion() throws IOException {
        if (isConnected()) {
            return mPacketHandler.getVersion();
        } else {
            return "Not Connected";
        }
    }

    public void fetchFirmwareVersion() {
        if (isConnected()) {
            PacketHandler.PSLAB_FW_VERSION = mPacketHandler.getFirmwareVersion();
            if (PacketHandler.PSLAB_FW_VERSION == 2) {
                MainActivity.getInstance().runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        MainActivity.getInstance().showFirmwareDialog();
                    }
                });
            }
        }
    }

    public void close() {
        mPacketHandler.close();
    }

    private void captureFullSpeedHrInitialize(String channel, int samples, double timeGap, List<String> args) {
        timeGap = (int) (timeGap * 8) / 8;
        if (timeGap < 0.5) timeGap = (int) (0.5 * 8) / 8;
        if (samples > this.MAX_SAMPLES) {
            Log.v(TAG, "Sample limit exceeded. 10,000 max");
            samples = this.MAX_SAMPLES;
        }
        this.timebase = (int) (timeGap * 8) / 8;
        this.samples = samples;
        int CHOSA = this.analogInputSources.get(channel).CHOSA;

        try {
            mPacketHandler.sendByte(mCommandsProto.ADC);
            if (args.contains("SET_LOW"))
                mPacketHandler.sendByte(mCommandsProto.SET_LO_CAPTURE);
            else if (args.contains("SET_HIGH"))
                mPacketHandler.sendByte(mCommandsProto.SET_HI_CAPTURE);
            else if (args.contains("READ_CAP")) {
                mPacketHandler.sendByte(mCommandsProto.MULTIPOINT_CAPACITANCE);
            } else
                mPacketHandler.sendByte(mCommandsProto.CAPTURE_DMASPEED);
            mPacketHandler.sendByte(CHOSA | 0x80);
            mPacketHandler.sendInt(samples);
            mPacketHandler.sendInt((int) timeGap * 8);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
    }

    /**
     * @param channel Channel name 'CH1' / 'CH2' ... 'RES'
     * @param samples Number of samples to fetch. Maximum 10000/(total specified channels)
     * @param timeGap Timegap between samples in microseconds.
     * @param args    timestamp array ,voltage_value array
     * @return Timestamp array ,voltage_value array
     */
    public Map<String, double[]> captureFullSpeedHr(String channel, int samples, double timeGap, List<String> args) {
        this.captureFullSpeedHrInitialize(channel, samples, timeGap, args);
        try {
            Thread.sleep((long) (1e-6 * this.samples * this.timebase + 0.1));
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        Map<String, double[]> axisData = retrieveBufferData(channel, this.samples, this.timebase);
        if (axisData == null) {
            Log.v(TAG, "Retrieved Buffer Data as null");
            return null;
        }
        Map<String, double[]> retData = new HashMap<>();
        retData.put("x", axisData.get("x"));
        retData.put("y", this.analogInputSources.get(channel).cal12(axisData.get("y")));
        return retData;
    }

    private Map<String, double[]> retrieveBufferData(String channel, int samples, double timeGap) {
        ArrayList<Integer> listData = new ArrayList<>();
        try {
            for (int i = 0; i < samples / this.dataSplitting; i++) {
                mPacketHandler.sendByte(mCommandsProto.ADC);
                mPacketHandler.sendByte(mCommandsProto.GET_CAPTURE_CHANNEL);
                mPacketHandler.sendByte(0);
                mPacketHandler.sendInt(this.dataSplitting);
                mPacketHandler.sendInt(i * this.dataSplitting);
                byte[] data = new byte[this.dataSplitting * 2 + 1];
                mPacketHandler.read(data, this.dataSplitting * 2 + 1);
                for (int j = 0; j < data.length - 1; j++)
                    listData.add((int) data[j] & 0xff);
            }

            if ((samples % this.dataSplitting) != 0) {
                mPacketHandler.sendByte(mCommandsProto.ADC);
                mPacketHandler.sendByte(mCommandsProto.GET_CAPTURE_CHANNEL);
                mPacketHandler.sendByte(0);
                mPacketHandler.sendInt(samples * this.dataSplitting);
                mPacketHandler.sendInt(samples - samples % this.dataSplitting);
                byte[] data = new byte[2 * (samples % this.dataSplitting)];
                mPacketHandler.read(data, 2 * (samples % this.dataSplitting));
                for (int j = 0; j < data.length - 1; j++)
                    listData.add((int) data[j] & 0xff);
            }

            for (int i = 0; i < samples; i++) {
                this.buffer[i] = (listData.get(i * 2) | (listData.get(i * 2 + 1) << 8));
            }

            double[] timeAxis = linSpace(0, timeGap * (samples - 1), samples);
            Map<String, double[]> retData = new HashMap<>();
            retData.put("x", timeAxis);
            retData.put("y", Arrays.copyOfRange(buffer, 0, samples));
            return retData;
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        return null;
    }

    /**
     * Instruct the ADC to start sampling. use fetchTrace to retrieve the data
     *
     * @param number          Channels to acquire. 1/2/4
     * @param samples         Total points to store per channel. Maximum 3200 total
     * @param timeGap         Timegap between two successive samples (in uSec)
     * @param channelOneInput Map channel 1 to 'CH1'
     * @param trigger         Whether or not to trigger the oscilloscope based on the voltage level set
     * @param CH123SA
     */
    public void captureTraces(int number, int samples, double timeGap, String channelOneInput, Boolean trigger, Integer CH123SA) {
        if (CH123SA == null) CH123SA = 0;
        if (channelOneInput == null) channelOneInput = "CH1";
        this.timebase = timeGap;
        this.timebase = (int) (this.timebase * 8) / 8;
        if (!this.analogInputSources.containsKey(channelOneInput)) {
            Log.e(TAG, "Invalid input channel");
            return;
        }
        int CHOSA = this.analogInputSources.get(channelOneInput).CHOSA;
        this.aChannels.get(0).setParams(channelOneInput, samples, 0, this.timebase, 10, this.analogInputSources.get(channelOneInput), null);
        try {
            mPacketHandler.sendByte(mCommandsProto.ADC);
            if (number == 1) {
                if (timeGap < 0.5)
                    this.timebase = (int) (0.5 * 8) / 8;
                if (samples > this.MAX_SAMPLES)
                    samples = this.MAX_SAMPLES;
                if (trigger) {
                    if (timeGap < 0.75)
                        this.timebase = (int) (0.75 * 8) / 8;
                    mPacketHandler.sendByte(mCommandsProto.CAPTURE_ONE);
                    mPacketHandler.sendByte(CHOSA | 0x80);
                } else if (timeGap > 1) {
                    this.aChannels.get(0).setParams(channelOneInput, samples, 0, this.timebase, 12, this.analogInputSources.get(channelOneInput), null);
                    mPacketHandler.sendByte(mCommandsProto.CAPTURE_DMASPEED);
                    mPacketHandler.sendByte(CHOSA | 0x80);
                } else {
                    mPacketHandler.sendByte(mCommandsProto.CAPTURE_DMASPEED);
                    mPacketHandler.sendByte(CHOSA);
                }
            } else if (number == 2) {
                if (timeGap < 0.875)
                    this.timebase = (int) (0.875 * 8) / 8;
                if (samples > this.MAX_SAMPLES / 2)
                    samples = this.MAX_SAMPLES / 2;
                this.aChannels.get(1).setParams("CH2", samples, samples, this.timebase, 10, this.analogInputSources.get("CH2"), null);
                mPacketHandler.sendByte(mCommandsProto.CAPTURE_TWO);
                mPacketHandler.sendByte(CHOSA | (0x80 * (trigger ? 1 : 0)));
            } else {
                if (timeGap < 1.75)
                    this.timebase = (int) (1.75 * 8) / 8;
                if (samples > this.MAX_SAMPLES / 4)
                    samples = this.MAX_SAMPLES / 4;
                int i = 1;
                for (String temp : new String[]{"CH2", "CH3", "MIC"}) {
                    this.aChannels.get(i).setParams(temp, samples, i * samples, this.timebase, 10, this.analogInputSources.get(temp), null);
                    i++;
                }
                mPacketHandler.sendByte(mCommandsProto.CAPTURE_FOUR);
                mPacketHandler.sendByte(CHOSA | (CH123SA << 4) | (0x80 * (trigger ? 1 : 0)));
            }
            this.samples = samples;
            mPacketHandler.sendInt(samples);
            mPacketHandler.sendInt((int) this.timebase * 8);
            mPacketHandler.getAcknowledgement();
            this.channelsInBuffer = number;
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }

    }

    /**
     * Fetches a channel(1-4) captured by :func:captureTraces called prior to this, and returns xAxis,yAxis
     *
     * @param channelNumber Any of the maximum of four channels that the oscilloscope captured. 1/2/3/4
     * @return time array,voltage array
     */
    public HashMap<String, double[]> fetchTrace(int channelNumber) {
        this.fetchData(channelNumber);
        HashMap<String, double[]> retData = new HashMap<>();
        retData.put("x", this.aChannels.get(channelNumber - 1).getXAxis());
        retData.put("y", this.aChannels.get(channelNumber - 1).getYAxis());
        return retData;
    }

    /**
     * Returns the number of samples acquired by the capture routines, and the conversion_done status
     *
     * @return conversion done(bool) ,samples acquired (number)
     */
    public int[] oscilloscopeProgress() {
        /*
         * returns the number of samples acquired by the capture routines, and the conversion_done status
         *
         * return structure int[]{conversionDone, samples}
         */

        int conversionDone = 0;
        int samples = 0;
        try {
            mPacketHandler.sendByte(mCommandsProto.ADC);
            mPacketHandler.sendByte(mCommandsProto.GET_CAPTURE_STATUS);
            conversionDone = (int) mPacketHandler.getByte() & 0xff;
            samples = mPacketHandler.getInt();
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        return new int[]{conversionDone, samples};
    }

    private boolean fetchData(int channelNumber) {
        int samples = this.aChannels.get(channelNumber - 1).length;
        if (channelNumber > this.channelsInBuffer) {
            Log.v(TAG, "Channel Unavailable");
            return false;
        }
        Log.v("Samples", "" + samples);
        Log.v("Data Splitting", "" + this.dataSplitting);
        ArrayList<Integer> listData = new ArrayList<>();
        try {
            for (int i = 0; i < samples / this.dataSplitting; i++) {
                mPacketHandler.sendByte(mCommandsProto.COMMON);
                mPacketHandler.sendByte(mCommandsProto.RETRIEVE_BUFFER);
                mPacketHandler.sendInt(this.aChannels.get(channelNumber - 1).bufferIndex + (i * this.dataSplitting));
                mPacketHandler.sendInt(this.dataSplitting);
                byte[] data = new byte[this.dataSplitting * 2 + 1];
                mPacketHandler.read(data, this.dataSplitting * 2 + 1);
                for (int j = 0; j < data.length - 1; j++)
                    listData.add((int) data[j] & 0xff);
            }

            if ((samples % this.dataSplitting) != 0) {
                mPacketHandler.sendByte(mCommandsProto.COMMON);
                mPacketHandler.sendByte(mCommandsProto.RETRIEVE_BUFFER);
                mPacketHandler.sendInt(this.aChannels.get(channelNumber - 1).bufferIndex + samples - samples % this.dataSplitting);
                mPacketHandler.sendInt(samples % this.dataSplitting);
                byte[] data = new byte[2 * (samples % this.dataSplitting) + 1];
                mPacketHandler.read(data, 2 * (samples % this.dataSplitting) + 1);
                for (int j = 0; j < data.length - 1; j++)
                    listData.add((int) data[j] & 0xff);
            }

        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
            return false;
        }

        for (int i = 0; i < listData.size() / 2; i++) {
            this.buffer[i] = (listData.get(i * 2)) | (listData.get(i * 2 + 1) << 8);
            while (this.buffer[i] > 1023) this.buffer[i] -= 1023;
        }

        Log.v("RAW DATA:", Arrays.toString(Arrays.copyOfRange(buffer, 0, samples)));

        this.aChannels.get(channelNumber - 1).yAxis = this.aChannels.get(channelNumber - 1).fixValue(Arrays.copyOfRange(this.buffer, 0, samples));
        return true;
    }

    /**
     * Configure trigger parameters for 10-bit capture commands
     * The capture routines will wait till a rising edge of the input signal crosses the specified level.
     * The trigger will timeout within 8mS, and capture routines will start regardless.
     * These settings will not be used if the trigger option in the capture routines are set to False
     *
     * @param channel     Channel 0,1,2,3. Corresponding to the channels being recorded by the capture routine(not the analog inputs)
     * @param channelName Name of the channel. 'CH1','CH2','CH3','MIC','V+'
     * @param voltage     The voltage level that should trigger the capture sequence(in Volts)
     * @param resolution
     * @param prescalar
     */
    public void configureTrigger(int channel, String channelName, double voltage, Integer resolution, Integer prescalar) {
        if (resolution == null) resolution = 10;
        if (prescalar == null) prescalar = 0;
        try {
            mPacketHandler.sendByte(mCommandsProto.ADC);
            mPacketHandler.sendByte(mCommandsProto.CONFIGURE_TRIGGER);
            mPacketHandler.sendByte((prescalar << 4) | (1 << channel));
            double level;
            if (resolution == 12) {
                level = this.analogInputSources.get(channelName).voltToCode12.value(voltage);
                if (level < 0) level = 0;
                else if (level > 4095) level = 4095;
            } else {
                level = this.analogInputSources.get(channelName).voltToCode10.value(voltage);
                if (level < 0) level = 0;
                else if (level > 1023) level = 1023;
            }
            if (level > pow(2, resolution - 1))
                level = pow(2, resolution - 1);
            else if (level < 0)
                level = 0;
            mPacketHandler.sendInt((int) level);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
    }

    /**
     * Set the gain of the selected PGA
     *
     * @param channel 'CH1','CH2'
     * @param gain    (0-8) -> (1x,2x,4x,5x,8x,10x,16x,32x,1/11x)
     * @param force   If True, the amplifier gain will be set even if it was previously set to the same value.
     * @return
     */
    public double setGain(String channel, int gain, Boolean force) {
        if (force == null) force = false;
        if (gain < 0 || gain > 8) {
            Log.v(TAG, "Invalid gain parameter. 0-7 only.");
            return 0;
        }
        if (this.analogInputSources.get(channel).gainPGA == -1) {
            Log.v(TAG, "No amplifier exists on this channel : " + channel);
            return 0;
        }
        boolean refresh = false;
        if (this.gains.get(channel) != gain) {
            this.gains.put(channel, gain);
            refresh = true;
        }
        if (refresh || force) {
            analogInputSources.get(channel).setGain(gain); // giving index of gainValues
            if (gain > 7) gain = 0;
            try {
                mPacketHandler.sendByte(mCommandsProto.ADC);
                mPacketHandler.sendByte(mCommandsProto.SET_PGA_GAIN);
                mPacketHandler.sendByte(analogInputSources.get(channel).gainPGA);
                mPacketHandler.sendByte(gain);
                mPacketHandler.getAcknowledgement();
                return this.gainValues[gain];
            } catch (IOException e) {
                Log.e(TAG, "Error sending data", e);
            }
        }
        return 0;
    }

    /**
     * set the gain of the selected PGA
     *
     * @param channel      'CH1','CH2'
     * @param voltageRange Choose from [16,8,4,3,2,1.5,1,.5,160]
     * @return
     */
    public Double selectRange(String channel, double voltageRange) {
        double[] ranges = new double[]{16, 8, 4, 3, 2, 1.5, 1, .5, 160};
        if (Arrays.asList(ArrayUtils.toObject(ranges)).contains(voltageRange)) {
            return this.setGain(channel, Arrays.asList(ArrayUtils.toObject(ranges)).indexOf(voltageRange), null);
        } else
            Log.e(TAG, "Not a valid Range");
        return null;
    }

    private int calcCHOSA(String channelName) {
        channelName = channelName.toUpperCase();
        AnalogInputSource source = analogInputSources.get(channelName);
        boolean found = false;
        for (String temp : allAnalogChannels) {
            if (temp.equals(channelName)) {
                found = true;
                break;
            }
        }
        if (!found) {
            Log.e(TAG, "Not a valid channel name. selecting CH1");
            return calcCHOSA("CH1");
        }

        return source.CHOSA;
    }

    public double getVoltage(String channelName, Integer sample) {
        this.voltmeterAutoRange(channelName);
        double Voltage = this.getAverageVoltage(channelName, sample);
        if (channelName.equals("CH2") || channelName.equals("CH1")) {
            return 2 * Voltage;
        } else {
            return Voltage;
        }
    }

    private void voltmeterAutoRange(String channelName) {
        if (this.analogInputSources.get(channelName).gainPGA != 0) {
            this.setGain(channelName, 0, true);
        }
    }

    /**
     * Return the voltage on the selected channel
     *
     * @param channelName : 'CH1','CH2','CH3','MIC','IN1','RES','V+'
     * @param sample      Samples to average
     * @return Voltage on the selected channel
     */
    private double getAverageVoltage(String channelName, Integer sample) {
        if (sample == null) sample = 1;
        PolynomialFunction poly;
        double sum = 0;
        poly = analogInputSources.get(channelName).calPoly12;
        ArrayList<Double> vals = new ArrayList<>();
        for (int i = 0; i < sample; i++) {
            vals.add(getRawAverageVoltage(channelName));
        }
        for (int j = 0; j < vals.size(); j++) {
            sum = sum + poly.value(vals.get(j));
        }
        return sum / 2 * vals.size();
    }

    private double getRawAverageVoltage(String channelName) {
        try {
            int chosa = this.calcCHOSA(channelName);
            mPacketHandler.sendByte(mCommandsProto.ADC);
            mPacketHandler.sendByte(mCommandsProto.GET_VOLTAGE_SUMMED);
            mPacketHandler.sendByte(chosa);
            int vSum = mPacketHandler.getVoltageSummation();
            return vSum / 16.0;
        } catch (IOException | NullPointerException e) {
            Log.e(TAG, "Error in getRawAverageVoltage", e);
        }
        return 0;
    }

    /**
     * Fetches a section of the ADC hardware buffer
     *
     * @param startingPosition Starting index
     * @param totalPoints      Total points to fetch
     */
    private void fetchBuffer(int startingPosition, int totalPoints) {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.RETRIEVE_BUFFER);
            mPacketHandler.sendInt(startingPosition);
            mPacketHandler.sendInt(totalPoints);
            for (int i = 0; i < totalPoints; i++) {
                byte[] data = new byte[2];
                mPacketHandler.read(data, 2);
                this.buffer[i] = (data[0] & 0xff) | ((data[1] << 8) & 0xff00);
            }
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error in fetching buffer", e);
        }
    }

    /**
     * Clears a section of the ADC hardware buffer
     *
     * @param startingPosition Starting index
     * @param totalPoints      Total points to fetch
     */
    private void clearBuffer(int startingPosition, int totalPoints) {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.CLEAR_BUFFER);
            mPacketHandler.sendInt(startingPosition);
            mPacketHandler.sendInt(totalPoints);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error in clearing buffer", e);
        }
    }

    /**
     * Fill a section of the ADC hardware buffer with data
     *
     * @param startingPosition Starting index
     * @param pointArray       Total points to fetch
     */
    private void fillBuffer(int startingPosition, int[] pointArray) {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.FILL_BUFFER);
            mPacketHandler.sendInt(startingPosition);
            mPacketHandler.sendInt(pointArray.length);
            for (int aPointArray : pointArray) {
                mPacketHandler.sendInt(aPointArray);
            }
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error in filling Buffer", e);
        }

    }

    public void setDataSplitting(int dataSplitting) {
        this.dataSplitting = dataSplitting;
    }

    /**
     * Checks if PSLab device is found
     *
     * @return true is device found; false otherwise
     */
    public boolean isDeviceFound() {
        if (mCommunicationHandler == null) {
            return false;
        }
        return mCommunicationHandler.isDeviceFound();
    }

    /**
     * Checks if PSLab device is connected
     *
     * @return true is device is connected; false otherwise
     */
    public boolean isConnected() {
        return ScienceLabCommon.isWifiConnected ||
                (mCommunicationHandler != null && mCommunicationHandler.isConnected());
    }

    /* DIGITAL SECTION */

    public Integer calculateDigitalChannel(String name) {
        if (Arrays.asList(DigitalChannel.digitalChannelNames).contains(name))
            return Arrays.asList(DigitalChannel.digitalChannelNames).indexOf(name);
        else {
            Log.v(TAG, "Invalid channel " + name + " , selecting LA1 instead ");
            return null;
        }
    }

    private Double getHighFrequencyBackup(String pin) {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.GET_HIGH_FREQUENCY);
            mPacketHandler.sendByte(this.calculateDigitalChannel(pin));
            int scale = mPacketHandler.getByte();
            long value = mPacketHandler.getLong();
            mPacketHandler.getAcknowledgement();
            return scale * value / 1.0e-1;
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        return null;
    }

    /**
     * Retrieves the frequency of the signal connected to LA1. For frequencies > 1MHz
     * Also good for lower frequencies, but avoid using it since the oscilloscope cannot be used simultaneously due to hardware limitations.
     * The input frequency is fed to a 32 bit counter for a period of 100mS.
     * The value of the counter at the end of 100mS is used to calculate the frequency.
     *
     * @param pin The input pin to measure frequency from : ['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @return frequency
     */
    public Double getHighFrequency(String pin) {
        /*
        Retrieves the frequency of the signal connected to LA1. for frequencies > 1MHz
		also good for lower frequencies, but avoid using it since
		the oscilloscope cannot be used simultaneously due to hardware limitations.
		The input frequency is fed to a 32 bit counter for a period of 100mS.
		The value of the counter at the end of 100mS is used to calculate the frequency.
        */
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.GET_ALTERNATE_HIGH_FREQUENCY);
            mPacketHandler.sendByte(this.calculateDigitalChannel(pin));
            int scale = mPacketHandler.getByte();
            long value = mPacketHandler.getLong();
            mPacketHandler.getAcknowledgement();
            return scale * value / 1.0e-1;
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        return null;
    }

    /**
     * Frequency measurement on IDx.
     * Measures time taken for 16 rising edges of input signal.
     * Returns the frequency in Hertz
     *
     * @param channel The input to measure frequency from. ['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @return frequency
     */
    public Double getFrequency(String channel) {
        /*
        Frequency measurement on IDx.
		Measures time taken for 16 rising edges of input signal.
		returns the frequency in Hertz
        */
        if (channel == null) channel = "LA1";
        LinkedHashMap<String, Integer> data;
        try {
            startOneChannelLA(channel, 1, channel, 3);
            Thread.sleep(250);
            data = getLAInitialStates();
            Thread.sleep(250);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        }
        return fetchLAChannelFrequency(calculateDigitalChannel(channel), data);
    }

    /**
     * Stores a list of rising edges that occurred within the timeout period.
     *
     * @param channel   The input to measure time between two rising edges.['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @param skipCycle Number of points to skip. eg. Pendulums pass through light barriers twice every cycle. SO 1 must be skipped
     * @param timeout   Number of seconds to wait for datapoints. (Maximum 60 seconds)
     * @return
     */
    public Double r2rTime(String channel, Integer skipCycle, Integer timeout) {
        /*
        Return a list of rising edges that occured within the timeout period.
        */
        if (skipCycle == null) skipCycle = 0;
        if (timeout == null) timeout = 5;
        if (timeout > 60) timeout = 60;
        this.startOneChannelLA(channel, 3, null, 0);
        long startTime = System.currentTimeMillis();
        while (System.currentTimeMillis() - startTime < timeout) {
            LinkedHashMap<String, Integer> initialStates = this.getLAInitialStates();
            if (initialStates.get("A") == this.MAX_SAMPLES / 4)
                initialStates.put("A", 0);
            if (initialStates.get("A") >= skipCycle + 2) {
                long[] data = this.fetchLongDataFromLA(initialStates.get("A"), 1);
                LinkedHashMap<String, Integer> tempMap = new LinkedHashMap<>();
                tempMap.put("LA1", initialStates.get("LA1"));
                tempMap.put("LA2", initialStates.get("LA2"));
                tempMap.put("LA3", initialStates.get("LA3"));
                tempMap.put("LA4", initialStates.get("LA4"));
                tempMap.put("RES", initialStates.get("RES"));
                double[] doubleData = new double[data.length];
                for (int i = 0; i < data.length; i++) {
                    doubleData[i] = data[i];
                }
                this.dChannels.get(0).loadData(tempMap, doubleData);
                return 1e-6 * (this.dChannels.get(0).timestamps[skipCycle + 1] - this.dChannels.get(0).timestamps[0]);
            }
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        return null;
    }

    /**
     * Stores a list of falling edges that occured within the timeout period.
     *
     * @param channel   The input to measure time between two falling edges.['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @param skipCycle Number of points to skip. eg. Pendulums pass through light barriers twice every cycle. SO 1 must be skipped
     * @param timeout   Number of seconds to wait for datapoints. (Maximum 60 seconds)
     * @return
     */
    public Double f2fTime(String channel, Integer skipCycle, Integer timeout) {
        /*
        Return a list of falling edges that occured within the timeout period.
        */
        if (skipCycle == null) skipCycle = 0;
        if (timeout == null) timeout = 5;
        if (timeout > 60) timeout = 60;
        this.startOneChannelLA(channel, 2, null, 0);
        long startTime = System.currentTimeMillis();
        while (System.currentTimeMillis() - startTime < timeout) {
            LinkedHashMap<String, Integer> initialStates = this.getLAInitialStates();
            if (initialStates.get("A") == this.MAX_SAMPLES / 4)
                initialStates.put("A", 0);
            if (initialStates.get("A") >= skipCycle + 2) {
                long[] data = this.fetchLongDataFromLA(initialStates.get("A"), 1);
                LinkedHashMap<String, Integer> tempMap = new LinkedHashMap<>();
                tempMap.put("LA1", initialStates.get("LA1"));
                tempMap.put("LA2", initialStates.get("LA2"));
                tempMap.put("LA3", initialStates.get("LA3"));
                tempMap.put("LA4", initialStates.get("LA4"));
                tempMap.put("RES", initialStates.get("RES"));
                double[] doubleData = new double[data.length];
                for (int i = 0; i < data.length; i++) {
                    doubleData[i] = data[i];
                }
                this.dChannels.get(0).loadData(tempMap, doubleData);
                return 1e-6 * (this.dChannels.get(0).timestamps[skipCycle + 1] - this.dChannels.get(0).timestamps[0]);
            }
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        return null;
    }

    /**
     * Measures time intervals between two logic level changes on any two digital inputs(both can be the same) and returns the calculated time.
     * For example, one can measure the time interval between the occurrence of a rising edge on LA1, and a falling edge on LA3.
     * If the returned time is negative, it simply means that the event corresponding to channel2 occurred first.
     *
     * @param channel1 The input pin to measure first logic level change
     * @param channel2 The input pin to measure second logic level change -['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @param edge1    The type of level change to detect in order to start the timer - ['rising', 'falling', 'four rising edges']
     * @param edge2    The type of level change to detect in order to stop the timer - ['rising', 'falling', 'four rising edges']
     * @param timeout  Use the timeout option if you're unsure of the input signal time period. Returns -1 if timed out
     * @return time
     */
    public Double measureInterval(String channel1, String channel2, String edge1, String edge2, Float timeout) {
        /*
        Measures time intervals between two logic level changes on any two digital inputs(both can be the same)
		For example, one can measure the time interval between the occurence of a rising edge on LA1, and a falling edge on LA3.
		If the returned time is negative, it simply means that the event corresponding to channel2 occurred first.
		Returns the calculated time
        */

        if (timeout == null) timeout = 0.1f;
        try {
            mPacketHandler.sendByte(mCommandsProto.TIMING);
            mPacketHandler.sendByte(mCommandsProto.INTERVAL_MEASUREMENTS);
            int timeoutMSB = ((int) (timeout * 64e6)) >> 16;
            mPacketHandler.sendInt(timeoutMSB);
            mPacketHandler.sendByte(this.calculateDigitalChannel(channel1) | (this.calculateDigitalChannel(channel2) << 4));
            int params = 0;
            if ("rising".equals(edge1))
                params |= 3;
            else if ("falling".equals(edge1))
                params |= 2;
            else
                params |= 4;

            if ("rising".equals(edge2))
                params |= 3 << 3;
            else if ("falling".equals(edge2))
                params |= 2 << 3;
            else
                params |= 4 << 3;

            mPacketHandler.sendByte(params);
            long A = mPacketHandler.getLong();
            long B = mPacketHandler.getLong();
            int tmt = mPacketHandler.getInt();
            mPacketHandler.getAcknowledgement();
            if (tmt > timeoutMSB || B == 0) return null;

            return (B - A + 20) / 64e6;
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        return null;
    }

    /**
     * Duty cycle measurement on channel. Returns wavelength(seconds), and length of first half of pulse(high time)
     * Low time = (wavelength - high time)
     *
     * @param channel The input pin to measure wavelength and high time.['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @param timeout Use the timeout option if you're unsure of the input signal time period. Returns 0 if timed out
     * @return Wavelength, Duty cycle
     */
    public double[] dutyCycle(String channel, Double timeout) {
        /*
        duty cycle measurement on channel
		returns wavelength(seconds), and length of first half of pulse(high time)
		low time = (wavelength - high time)
        */
        if (channel == null) channel = "LA1";
        if (timeout == null) timeout = 1.;
        Map<String, double[]> data = this.measureMultipleDigitalEdges(channel, channel, "rising", "falling", 2, 2, timeout, null, true);
        double[] retData = new double[2];
        if (data != null) {
            double[] x = data.get("CHANNEL1");
            double[] y = data.get("CHANNEL2");
            if (x != null && y != null) {  // Both timers registered something. did not timeout
                if (y[0] > 0) {
                    retData[0] = y[0];
                    retData[1] = x[1];
                } else {
                    if (y[1] > x[1]) {
                        retData[0] = -1;
                        retData[1] = -1;
                        return retData;
                    }
                    retData[0] = y[1];
                    retData[1] = x[1];
                }
                double[] params = new double[2];
                params[0] = retData[1];
                params[1] = retData[0] / retData[1];
                if (params[1] > 0.5) {
                    Log.v(TAG, Arrays.toString(x) + "\n" + Arrays.toString(y) + "\n" + Arrays.toString(retData));
                }
                return params;
            }
        }
        retData[0] = -1;
        retData[1] = -1;
        return retData;
    }

    /**
     * Duty cycle measurement on channel. Returns wavelength(seconds), and length of first half of pulse(high time)
     * Low time = (wavelength - high time)
     *
     * @param channel   The input pin to measure wavelength and high time.['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @param pulseType Type of pulse to detect. May be 'HIGH' or 'LOW'
     * @param timeout   Use the timeout option if you're unsure of the input signal time period. Returns 0 if timed out
     * @return Pulse width
     */
    public Double pulseTime(String channel, String pulseType, Double timeout) {
        if (channel == null) channel = "LA1";
        if (pulseType == null) pulseType = "LOW";
        if (timeout == null) timeout = 0.1;

        Map<String, double[]> data = this.measureMultipleDigitalEdges(channel, channel, "rising", "falling", 2, 2, timeout, null, true);
        if (data != null) {
            double[] x = data.get("CHANNEL1");
            double[] y = data.get("CHANNEL2");
            if (x != null && y != null) { // Both timers registered something. did not timeout
                if (y[0] > 0) {
                    if ("HIGH".equals(pulseType))
                        return y[0];
                    else if ("LOW".equals(pulseType)) {
                        return x[1] - y[0];
                    }
                } else {
                    if ("HIGH".equals(pulseType))
                        return y[1];
                    else if ("LOW".equals(pulseType)) {
                        return Math.abs(y[0]);
                    }
                }
            }
        }
        return null;
    }

    /**
     * Measures a set of timestamped logic level changes(Type can be selected) from two different digital inputs.
     *
     * @param channel1  The input pin to measure first logic level change
     * @param channel2  The input pin to measure second logic level change -['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @param edgeType1 The type of level change that should be recorded - ['rising', 'falling', 'four rising edges(default)']
     * @param edgeType2 The type of level change that should be recorded - ['rising', 'falling', 'four rising edges(default)']
     * @param points1   Number of data points to obtain for input 1 (Max 4)
     * @param points2   Number of data points to obtain for input 2 (Max 4)
     * @param timeout   Use the timeout option if you're unsure of the input signal time period. returns -1 if timed out
     * @param SQR1      Set the state of SQR1 output(LOW or HIGH) and then start the timer. eg. SQR1 = 'LOW'
     * @param zero      subtract the timestamp of the first point from all the others before returning. Default: True
     * @return time
     */
    private Map<String, double[]> measureMultipleDigitalEdges(String channel1, String channel2, String edgeType1, String edgeType2, int points1, int points2, Double timeout, String SQR1, Boolean zero) {

        if (timeout == null) timeout = 0.1;
        try {
            mPacketHandler.sendByte(mCommandsProto.TIMING);
            mPacketHandler.sendByte(mCommandsProto.TIMING_MEASUREMENTS);
            int timeoutMSB = ((int) (timeout * 64e6)) >> 16;
            mPacketHandler.sendInt(timeoutMSB);
            mPacketHandler.sendByte(this.calculateDigitalChannel(channel1) | (this.calculateDigitalChannel(channel2) << 4));
            int params = 0;
            if ("rising".equals(edgeType1))
                params |= 3;
            else if ("falling".equals(edgeType1))
                params |= 2;
            else
                params |= 4;

            if ("rising".equals(edgeType2))
                params |= 3 << 3;
            else if ("falling".equals(edgeType2))
                params |= 2 << 3;
            else
                params |= 4 << 3;
            if (SQR1 != null) {
                params |= (1 << 6);
                if ("HIGH".equals(SQR1))
                    params |= (1 << 7);
            }
            mPacketHandler.sendByte(params);
            if (points1 > 4) points1 = 4;
            if (points2 > 4) points2 = 4;
            mPacketHandler.sendByte(points1 | (points2 << 4));

            //mPacketHandler.waitForData(timeout); todo : complete waitForData in PacketHandler.java
            long[] A = new long[points1];
            long[] B = new long[points2];
            for (int i = 0; i < points1; i++)
                A[i] = mPacketHandler.getLong();
            for (int i = 0; i < points2; i++)
                B[i] = mPacketHandler.getLong();
            int tmt = mPacketHandler.getInt();
            mPacketHandler.getAcknowledgement();
            Map<String, double[]> retData = new HashMap<>();
            if (tmt > timeoutMSB) {
                retData.put("CHANNEL1", null);
                retData.put("CHANNEL2", null);
                return retData;
            }
            if (zero == null) zero = true;
            double[] A1 = new double[A.length];
            double[] B1 = new double[B.length];
            if (zero) {
                for (int i = 0; i < A.length; i++) {
                    A[i] -= A[0];
                    A1[i] = A[i] / 64e6;
                }
                for (int i = 0; i < B.length; i++) {
                    B[i] -= B[0];
                    B1[i] = B[i] / 64e6;
                }
            } else {
                for (int i = 0; i < A.length; i++) {
                    A1[i] = A[i] / 64e6;
                }
                for (int i = 0; i < B.length; i++) {
                    B1[i] = B[i] / 64e6;
                }
            }
            retData.put("CHANNEL1", A1);
            retData.put("CHANNEL2", B1);
            return retData;
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        return null;
    }

    /**
     * Log timestamps of rising/falling edges on one digital input
     *
     * @param waitingTime    Total time to allow the logic analyzer to collect data. This is implemented using a simple sleep routine, so if large delays will be involved, refer to startOneChannelLA() to start the acquisition, and fetchLAChannels() to retrieve data from the hardware after adequate time. The retrieved data is stored in the array self.dchans[0].timestamps.
     * @param aquireChannel  LA1',...,'LA4'
     * @param triggerChannel LA1',...,'LA4'
     * @param aquireMode     EVERY_SIXTEENTH_RISING_EDGE = 5
     *                       EVERY_FOURTH_RISING_EDGE = 4
     *                       EVERY_RISING_EDGE = 3
     *                       EVERY_FALLING_EDGE = 2
     *                       EVERY_EDGE = 1
     *                       DISABLED = 0
     *                       default = 3
     * @param triggerMode    same as aquireMode. default_value : 3
     * @return
     */
    public double[] captureEdgesOne(Integer waitingTime, String aquireChannel, String triggerChannel, Integer aquireMode, Integer triggerMode) {
        /*
        Log timestamps of rising/falling edges on one digital input
        */
        if (waitingTime == null) waitingTime = 1;
        if (aquireChannel == null) aquireChannel = "LA1";
        if (triggerChannel == null) triggerChannel = aquireChannel;
        if (aquireMode == null) aquireMode = 3;
        if (triggerMode == null) triggerMode = 3;
        this.startOneChannelLA(aquireChannel, aquireMode, triggerChannel, triggerMode);
        try {
            Thread.sleep(waitingTime * 1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        LinkedHashMap<String, Integer> data = this.getLAInitialStates();
        long[] temp = this.fetchLongDataFromLA(data.get("A"), 1);
        double[] retData = new double[temp.length];
        for (int i = 0; i < temp.length; i++) {
            retData[i] = temp[i] / 64e6;
        }
        return retData;
    }

    /**
     * Start logging timestamps of rising/falling edges on LA1
     *
     * @param trigger         Bool . Enable edge trigger on LA1. use keyword argument edge = 'rising' or 'falling'
     * @param channel         ['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @param maximumTime     Total time to sample. If total time exceeds 67 seconds, a prescaler will be used in the reference clock.
     * @param triggerChannels array of digital input names that can trigger the acquisition. Eg, trigger = ['LA1','LA2','LA3'] will triggger when a logic change specified by the keyword argument 'edge' occurs on either or the three specified trigger inputs.
     * @param edge            'rising' or 'falling' . trigger edge type for trigger_channels.
     */
    public void startOneChannelLABackup(Integer trigger, String channel, Integer maximumTime, ArrayList<String> triggerChannels, String edge) {
        /*
        start logging timestamps of rising/falling edges on LA1
        */
        try {
            this.clearBuffer(0, this.MAX_SAMPLES / 2);
            mPacketHandler.sendByte(mCommandsProto.TIMING);
            mPacketHandler.sendByte(mCommandsProto.START_ONE_CHAN_LA);
            mPacketHandler.sendInt(this.MAX_SAMPLES / 4);
            if (triggerChannels != null & (trigger & 1) != 0) {
                if (triggerChannels.contains("LA1")) trigger |= (1 << 4);
                if (triggerChannels.contains("LA2")) trigger |= (1 << 5);
                if (triggerChannels.contains("LA3")) trigger |= (1 << 6);
            } else {
                trigger |= 1 << (this.calculateDigitalChannel(channel) + 4);
            }
            if ("rising".equals(edge)) trigger |= 2;
            trigger |= (this.calculateDigitalChannel(channel) << 2);

            mPacketHandler.sendByte(trigger);
            mPacketHandler.getAcknowledgement();
            this.digitalChannelsInBuffer = 1;
            for (DigitalChannel dChan : this.dChannels) {
                dChan.prescalar = 0;
                dChan.dataType = "long";
                dChan.length = this.MAX_SAMPLES / 4;
                dChan.maxTime = (int) (maximumTime * 1e6);
                dChan.mode = DigitalChannel.EVERY_EDGE;
            }
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
    }

    /**
     * Start logging timestamps of rising/falling edges on LA1.
     *
     * @param channel        ['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @param channelMode    acquisition mode default value: 1(EVERY_EDGE)
     *                       - EVERY_SIXTEENTH_RISING_EDGE = 5
     *                       - EVERY_FOURTH_RISING_EDGE    = 4
     *                       - EVERY_RISING_EDGE           = 3
     *                       - EVERY_FALLING_EDGE          = 2
     *                       - EVERY_EDGE                  = 1
     *                       - DISABLED                    = 0
     * @param triggerChannel ['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @param triggerMode    1=Falling edge, 0=Rising Edge, -1=Disable Trigger
     */
    public void startOneChannelLA(String channel, Integer channelMode, String triggerChannel, Integer triggerMode) {
        if (channel == null) channel = "LA1";
        if (channelMode == null) channelMode = 1;
        if (triggerChannel == null) triggerChannel = "LA1";
        if (triggerMode == null) triggerMode = 3;
        try {
            this.clearBuffer(0, this.MAX_SAMPLES);
            mPacketHandler.sendByte(mCommandsProto.TIMING);
            mPacketHandler.sendByte(mCommandsProto.START_ALTERNATE_ONE_CHAN_LA);
            mPacketHandler.sendInt(this.MAX_SAMPLES / 4);
            int aqChannel = this.calculateDigitalChannel(channel);
            int aqMode = channelMode;
            int trChannel = this.calculateDigitalChannel(triggerChannel);
            int trMode = triggerMode;
            mPacketHandler.sendByte((aqChannel << 4) | aqMode);
            mPacketHandler.sendByte((trChannel << 4) | trMode);
            mPacketHandler.getAcknowledgement();
            this.digitalChannelsInBuffer = 1;
            this.dChannels.get(aqChannel).prescalar = 0;
            this.dChannels.get(aqChannel).dataType = "long";
            this.dChannels.get(aqChannel).length = this.MAX_SAMPLES / 4;
            this.dChannels.get(aqChannel).maxTime = (int) (67 * 1e6);
            this.dChannels.get(aqChannel).mode = channelMode;
            this.dChannels.get(aqChannel).channelName = channel;
            if (trMode == 3 || trMode == 4 || trMode == 5)
                this.dChannels.get(aqChannel).initialStateOverride = 2;
            else if (trMode == 2)
                this.dChannels.get(0).initialStateOverride = 1;

        } catch (IOException e) {
            Log.e(TAG, "Error starting logic analyzer", e);
        }
    }

    /**
     * Start logging timestamps of rising/falling edges on LA1,LA2
     *
     * @param channels       Channels to acquire data from . default ['LA1','LA2']
     * @param modes          modes for each channel. Array . default value: [1,1]
     *                       - EVERY_SIXTEENTH_RISING_EDGE = 5
     *                       - EVERY_FOURTH_RISING_EDGE    = 4
     *                       - EVERY_RISING_EDGE           = 3
     *                       - EVERY_FALLING_EDGE          = 2
     *                       - EVERY_EDGE                  = 1
     *                       - DISABLED                    = 0
     * @param maximumTime    Total time to sample. If total time exceeds 67 seconds, a prescaler will be used in the reference clock
     * @param trigger        Bool . Enable rising edge trigger on LA1
     * @param edge           'rising' or 'falling' . trigger edge type for trigger_channels.
     * @param triggerChannel channel to trigger on . Any digital input. default CH1
     */
    public void startTwoChannelLA(ArrayList<String> channels, ArrayList<Integer> modes, Integer maximumTime, Integer trigger, String edge, String triggerChannel) {
        if (maximumTime == null) maximumTime = 67;
        if (trigger == null) trigger = 0;
        if (edge == null) edge = "rising";
        if (channels == null) {
            channels = new ArrayList<>();
            channels.add("LA1");
            channels.add("LA2");
        }
        if (modes == null) {
            modes = new ArrayList<>();
            modes.add(1);
            modes.add(1);
        }
        int[] chans = new int[]{this.calculateDigitalChannel(channels.get(0)), this.calculateDigitalChannel(channels.get(1))};
        if (triggerChannel == null) triggerChannel = channels.get(0);
        if (trigger != 0) {
            trigger = 1;
            if ("falling".equals(edge)) trigger |= 2;
            trigger |= (this.calculateDigitalChannel(triggerChannel) << 4);
        }
        try {
            this.clearBuffer(0, this.MAX_SAMPLES);
            mPacketHandler.sendByte(mCommandsProto.TIMING);
            mPacketHandler.sendByte(mCommandsProto.START_TWO_CHAN_LA);
            mPacketHandler.sendInt(this.MAX_SAMPLES / 4);
            mPacketHandler.sendByte(trigger);
            mPacketHandler.sendByte(modes.get(0) | (modes.get(1) << 4));
            mPacketHandler.sendByte(chans[0] | (chans[1] << 4));
            mPacketHandler.getAcknowledgement();
            for (int i = 0; i < 2; i++) {
                DigitalChannel temp = this.dChannels.get(i);
                temp.prescalar = 0;
                temp.length = this.MAX_SAMPLES / 4;
                temp.dataType = "long";
                temp.maxTime = (int) (maximumTime * 1e6);
                temp.mode = modes.get(i);
                temp.channelNumber = chans[i];
                temp.channelName = channels.get(i);
            }
            this.digitalChannelsInBuffer = 2;
        } catch (IOException e) {
            Log.e(TAG, "Error starting logic analyzer", e);
        }
    }

    /**
     * Start logging timestamps of rising/falling edges on LA1,LA2,LA3
     *
     * @param modes          modes for each channel. Array. default value: [1,1,1]
     *                       - EVERY_SIXTEENTH_RISING_EDGE = 5
     *                       - EVERY_FOURTH_RISING_EDGE    = 4
     *                       - EVERY_RISING_EDGE           = 3
     *                       - EVERY_FALLING_EDGE          = 2
     *                       - EVERY_EDGE                  = 1
     *                       - DISABLED                    = 0
     * @param triggerChannel ['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     * @param triggerMode    same as modes(previously documented keyword argument)
     *                       default_value : 3
     */
    public void startThreeChannelLA(ArrayList<Integer> modes, String triggerChannel, Integer triggerMode) {
        if (modes == null) {
            modes = new ArrayList<>();
            modes.add(1);
            modes.add(1);
            modes.add(1);
        }
        if (triggerChannel == null) {
            triggerChannel = "LA1";
        }
        if (triggerMode == null) {
            triggerMode = 3;
        }
        try {
            this.clearBuffer(0, this.MAX_SAMPLES);
            mPacketHandler.sendByte(mCommandsProto.TIMING);
            mPacketHandler.sendByte(mCommandsProto.START_THREE_CHAN_LA);
            mPacketHandler.sendInt(this.MAX_SAMPLES / 4);
            int trChan = this.calculateDigitalChannel(triggerChannel);
            int trMode = triggerMode;

            mPacketHandler.sendInt(modes.get(0) | (modes.get(1) << 4) | (modes.get(2) << 8));
            mPacketHandler.sendByte((trChan << 4) | trMode);
            mPacketHandler.getAcknowledgement();
            this.digitalChannelsInBuffer = 3;

            for (int i = 0; i < 3; i++) {
                DigitalChannel temp = this.dChannels.get(i);
                temp.prescalar = 0;
                temp.length = this.MAX_SAMPLES / 4;
                temp.dataType = "int";
                temp.maxTime = (int) (1e3);
                temp.mode = modes.get(i);
                temp.channelName = DigitalChannel.digitalChannelNames[i];
                if (trMode == 3 || trMode == 4 || trMode == 5) {
                    temp.initialStateOverride = 2;
                } else if (trMode == 2) {
                    temp.initialStateOverride = 1;
                }
            }

        } catch (IOException e) {
            Log.e(TAG, "Error starting logic analyzer", e);
        }
    }

    /**
     * Four channel Logic Analyzer.
     * Start logging timestamps from a 64MHz counter to record level changes on LA1,LA2,LA3,LA4.
     * triggerChannel[0] -> LA1
     * triggerChannel[1] -> LA2
     * triggerChannel[2] -> LA3
     *
     * @param trigger        Bool. Enable rising edge trigger on LA1.
     * @param maximumTime    Maximum delay expected between two logic level changes.
     *                       If total time exceeds 1 mS, a prescaler will be used in the reference clock.
     *                       However, this only refers to the maximum time between two successive level changes. If a delay larger
     *                       than .26 S occurs, it will be truncated by modulo .26 S.
     *                       If you need to record large intervals, try single channel/two channel modes which use 32 bit counters
     *                       capable of time interval up to 67 seconds.
     * @param modes          modes for each channel. List with four elements\n
     *                       default values: [1,1,1,1]
     *                       - EVERY_SIXTEENTH_RISING_EDGE = 5
     *                       - EVERY_FOURTH_RISING_EDGE    = 4
     *                       - EVERY_RISING_EDGE           = 3
     *                       - EVERY_FALLING_EDGE          = 2
     *                       - EVERY_EDGE                  = 1
     *                       - DISABLED                    = 0
     * @param edge           'rising' or 'falling'. Trigger edge type for trigger_channels.
     * @param triggerChannel ['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     */
    public void startFourChannelLA(Integer trigger, Double maximumTime, ArrayList<Integer> modes, String edge, ArrayList<Boolean> triggerChannel) {
        if (trigger == null) trigger = 1;
        if (maximumTime == null) maximumTime = 0.001;
        if (modes == null) {
            modes = new ArrayList<>();
            modes.add(1);
            modes.add(1);
            modes.add(1);
        }
        if (edge == null) edge = "0";
        this.clearBuffer(0, this.MAX_SAMPLES);
        int prescale = 0;
        try {
            mPacketHandler.sendByte(mCommandsProto.TIMING);
            mPacketHandler.sendByte(mCommandsProto.START_FOUR_CHAN_LA);
            mPacketHandler.sendInt(this.MAX_SAMPLES / 4);
            mPacketHandler.sendInt(modes.get(0) | (modes.get(1) << 4) | (modes.get(2) << 8) | (modes.get(3) << 12));
            mPacketHandler.sendByte(prescale);
            int triggerOptions = 0;
            if (triggerChannel.get(0)) triggerOptions |= 4;
            if (triggerChannel.get(1)) triggerOptions |= 8;
            if (triggerChannel.get(2)) triggerOptions |= 16;
            if (triggerOptions == 0)
                triggerOptions |= 4;  // Select one trigger channel(LA1) if none selected
            if ("rising".equals(edge)) triggerOptions |= 2;
            trigger |= triggerOptions;
            mPacketHandler.sendByte(trigger);
            mPacketHandler.getAcknowledgement();
            this.digitalChannelsInBuffer = 4;
            int i = 0;
            for (DigitalChannel dChan : this.dChannels) {
                dChan.prescalar = prescale;
                dChan.dataType = "int";
                dChan.length = this.MAX_SAMPLES / 4;
                dChan.maxTime = (int) (maximumTime * 1e6);
                dChan.mode = modes.get(i);
                dChan.channelName = DigitalChannel.digitalChannelNames[i];
                i++;
            }
        } catch (IOException e) {
            Log.e(TAG, "Error starting logic analyzer", e);
        }
    }

    /**
     * Fetches the initial states of digital inputs that were recorded right before the Logic analyzer was started,
     * and the total points each channel recorded.
     *
     * @return CH1 progress,CH2 progress,CH3 progress,CH4 progress,[LA1,LA2,LA3,LA4]. eg. [1,0,1,1]
     */
    public LinkedHashMap<String, Integer> getLAInitialStates() {
        try {
            mPacketHandler.sendByte(mCommandsProto.TIMING);
            mPacketHandler.sendByte(mCommandsProto.GET_INITIAL_DIGITAL_STATES);
            byte[] initialStatesBytes = new byte[13];
            mPacketHandler.read(initialStatesBytes, 13);
            int initial = (initialStatesBytes[0] & 0xFF) | ((initialStatesBytes[1] << 8) & 0xFF00);
            int A = (((initialStatesBytes[2] & 0xFF) | ((initialStatesBytes[3] << 8) & 0xFF00)) - initial) / 2;
            int B = (((initialStatesBytes[4] & 0xFF) | ((initialStatesBytes[5] << 8) & 0xFF00)) - initial) / 2 - MAX_SAMPLES / 4;
            int C = (((initialStatesBytes[6] & 0xFF) | ((initialStatesBytes[7] << 8) & 0xFF00)) - initial) / 2 - 2 * MAX_SAMPLES / 4;
            int D = (((initialStatesBytes[8] & 0xFF) | ((initialStatesBytes[9] << 8) & 0xFF00)) - initial) / 2 - 3 * MAX_SAMPLES / 4;
            int s = initialStatesBytes[10] & 0xFF;
            int sError = initialStatesBytes[11] & 0xFF;
            //mPacketHandler.getAcknowledgement();

            if (A == 0) A = this.MAX_SAMPLES / 4;
            if (B == 0) B = this.MAX_SAMPLES / 4;
            if (C == 0) C = this.MAX_SAMPLES / 4;
            if (D == 0) D = this.MAX_SAMPLES / 4;

            if (A < 0) A = 0;
            if (B < 0) B = 0;
            if (C < 0) C = 0;
            if (D < 0) D = 0;

            LinkedHashMap<String, Integer> retData = new LinkedHashMap<>();
            retData.put("A", A);
            retData.put("B", B);
            retData.put("C", C);
            retData.put("D", D);

            // putting 1 -> true & 0 -> false
            if ((s & 1) != 0)
                retData.put("LA1", 1);
            else
                retData.put("LA1", 0);

            if ((s & 2) != 0)
                retData.put("LA2", 1);
            else
                retData.put("LA2", 0);

            if ((s & 4) != 0)
                retData.put("LA3", 1);
            else
                retData.put("LA3", 0);

            if ((s & 8) != 0)
                retData.put("LA4", 1);
            else
                retData.put("LA4", 0);

            if ((s & 16) != 0)
                retData.put("RES", 1);
            else
                retData.put("RES", 0);

            return retData;
        } catch (IOException e) {
            Log.e(TAG, "Error getting logic analyzer initial state", e);
        }
        return null;
    }

    /**
     * Stop any running logic analyzer function.
     */
    public void stopLA() {
        try {
            mPacketHandler.sendByte(mCommandsProto.TIMING);
            mPacketHandler.sendByte(mCommandsProto.STOP_LA);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error stopping logic analyzer", e);
        }
    }

    private int calculateBufferPosition(int channel, int offset, int channels, int bytes) {
        int multiplier = (channels < 3) ? 2 : 1;
        return (channel - 1) * bytes * multiplier + offset;
    }

    /**
     * Fetches the data stored by DMA. integer address increments
     *
     * @param bytes   number of readings(integer) to fetch
     * @param channel channel number (1-4)
     * @return array of integer data fetched from Logic Analyser.
     */
    public long[] fetchIntDataFromLA(Integer bytes, Integer channel, Integer channels) {
        if (channel == null) channel = 1;
        try {
            ArrayList<Integer> l = new ArrayList<>();
            for (int i = 0; i < bytes / this.dataSplitting; i++) {
                mPacketHandler.sendByte(mCommandsProto.COMMON);
                mPacketHandler.sendByte(mCommandsProto.RETRIEVE_BUFFER);
                mPacketHandler.sendInt(calculateBufferPosition(channel, i * this.dataSplitting, channels, bytes));
                mPacketHandler.sendInt(this.dataSplitting);
                byte[] data = new byte[this.dataSplitting * 2 + 1];
                mPacketHandler.read(data, this.dataSplitting * 2 + 1);
                for (int j = 0; j < data.length - 1; j++)
                    l.add((int) data[j] & 0xff);
            }

            if ((bytes % this.dataSplitting) != 0) {
                mPacketHandler.sendByte(mCommandsProto.COMMON);
                mPacketHandler.sendByte(mCommandsProto.RETRIEVE_BUFFER);
                mPacketHandler.sendInt(calculateBufferPosition(channel, bytes - bytes % this.dataSplitting, channels, bytes));
                mPacketHandler.sendInt(bytes % this.dataSplitting);
                byte[] data = new byte[2 * (bytes % this.dataSplitting) + 1];
                mPacketHandler.read(data, 2 * (bytes % this.dataSplitting) + 1);
                for (int j = 0; j < data.length - 1; j++)
                    l.add((int) data[j] & 0xff);
            }
            if (!l.isEmpty()) {
                StringBuilder stringBuilder = new StringBuilder();
                long[] timeStamps = new long[bytes + 1];
                for (int i = 0; i < bytes; i++) {
                    int t = (l.get(i * 2) | (l.get(i * 2 + 1) << 8));
                    timeStamps[i + 1] = t;
                    stringBuilder.append(t);
                    stringBuilder.append(" ");
                }
                Log.v("Fetched points : ", stringBuilder.toString());
                //mPacketHandler.getAcknowledgement();
                timeStamps[0] = 1;
                return timeStamps;
            } else {
                Log.e("Error : ", "Obtained bytes = 0");
                long[] temp = new long[2501];
                Arrays.fill(temp, 0);
                return temp;
            }
        } catch (IOException e) {
            Log.e(TAG, "Error reading data from logic analyzer", e);
        }
        return null;
    }

    /**
     * Fetches the data stored by DMA. long address increments.
     *
     * @param bytes   number of readings(long integers) to fetch
     * @param channel channel number (1-2)
     * @return array of long integers data fetched from Logic Analyser.
     */
    public long[] fetchLongDataFromLA(Integer bytes, Integer channel) {
        if (channel == null) channel = 1;
        try {
            mPacketHandler.sendByte(mCommandsProto.TIMING);
            mPacketHandler.sendByte(mCommandsProto.FETCH_LONG_DMA_DATA);
            mPacketHandler.sendInt(bytes);
            mPacketHandler.sendByte(channel - 1);
            byte[] readData = new byte[bytes * 4];
            mPacketHandler.read(readData, bytes * 4);
            mPacketHandler.getAcknowledgement();
            long[] data = new long[bytes];
            for (int i = 0; i < bytes; i++) {
                data[i] = ByteBuffer.wrap(Arrays.copyOfRange(readData, 4 * i, 4 * i + 4)).order(ByteOrder.LITTLE_ENDIAN).getLong();
            }
            // Trimming array data
            int markerA = 0;
            for (int i = 0; i < data.length; i++) {
                if (data[i] != 0) {
                    markerA = i;
                    break;
                }
            }
            int markerB = 0;
            for (int i = data.length - 1; i >= 0; i--) {
                if (data[i] != 0) {
                    markerB = i;
                    break;
                }
            }
            return Arrays.copyOfRange(data, markerA, markerB + 1);
        } catch (IOException e) {
            Log.e(TAG, "Error reading data from logic analyzer", e);
        }
        return null;
    }

    /**
     * @param channelNumber Channel number being used e.g. CH1, CH2, CH3, CH4.
     * @param initialStates State of the digital inputs. returns dictionary with keys 'LA1','LA2','LA3','LA4','RES'
     * @return true if data fetched/loaded successfully.
     */
    public boolean fetchLAChannel(Integer channelNumber, LinkedHashMap<String, Integer> initialStates, Integer channels) {
        DigitalChannel dChan = this.dChannels.get(channelNumber);

        LinkedHashMap<String, Integer> tempMap = new LinkedHashMap<>();
        tempMap.put("LA1", initialStates.get("LA1"));
        tempMap.put("LA2", initialStates.get("LA2"));
        tempMap.put("LA3", initialStates.get("LA3"));
        tempMap.put("LA4", initialStates.get("LA4"));
        tempMap.put("RES", initialStates.get("RES"));

        //  Used LinkedHashMap above (initialStates) in which iteration is done sequentially as <key-value> were inserted
        int i = 0;
        for (Map.Entry<String, Integer> entry : initialStates.entrySet()) {
            if (dChan.channelNumber == i) {
                i = entry.getValue();
                break;
            }
            i++;
        }

        long[] temp = this.fetchIntDataFromLA(i, dChan.channelNumber + 1, channels);
        double[] data = new double[temp.length - 1];
        if (temp[0] == 1) {
            for (int j = 1; j < temp.length; j++) {
                data[j - 1] = temp[j];
            }
        } else {
            Log.e("Error : ", "Can't load data");
            return false;
        }
        dChan.loadData(tempMap, data);

        dChan.generateAxes();
        return true;
    }

    public double fetchLAChannelFrequency(Integer channelNumber, LinkedHashMap<String, Integer> initialStates) {
        DigitalChannel dChan = this.dChannels.get(channelNumber);

        LinkedHashMap<String, Integer> tempMap = new LinkedHashMap<>();
        tempMap.put("LA1", initialStates.get("LA1"));
        tempMap.put("LA2", initialStates.get("LA2"));
        tempMap.put("LA3", initialStates.get("LA3"));
        tempMap.put("LA4", initialStates.get("LA4"));
        tempMap.put("RES", initialStates.get("RES"));

        //  Used LinkedHashMap above (initialStates) in which iteration is done sequentially as <key-value> were inserted
        Integer i = initialStates.get("A");
        long[] temp = this.fetchIntDataFromLA(i, 1, 1);
        double[] data = new double[temp.length - 1];
        if (temp[0] == 1) {
            for (int j = 1; j < temp.length; j++) {
                data[j - 1] = temp[j];
            }
        } else {
            Log.e("Error : ", "Can't load data");
            return -1;
        }
        dChan.loadData(tempMap, data);

        dChan.generateAxes();
        int count = 0;
        double[] yAxis = dChan.getYAxis();
        if (count == this.MAX_SAMPLES / 2 - 1) {
            LAChannelFrequency = 0;
        } else if (yAxis.length != 0 && yAxis.length != this.MAX_SAMPLES / 2 - 1 && LAChannelFrequency != yAxis.length) {
            LAChannelFrequency = yAxis.length;
        }
        return LAChannelFrequency;
    }

    public DigitalChannel getDigitalChannel(int i) {
        return dChannels.get(i);
    }

    /**
     * Gets the state of the digital inputs.
     *
     * @return dictionary with keys 'LA1','LA2','LA3','LA4'.
     */
    public Map<String, Boolean> getStates() {
        try {
            mPacketHandler.sendByte(mCommandsProto.DIN);
            mPacketHandler.sendByte(mCommandsProto.GET_STATES);
            byte state = mPacketHandler.getByte();
            mPacketHandler.getAcknowledgement();
            Map<String, Boolean> states = new LinkedHashMap<>();
            states.put("LA1", ((state & 1) != 0));
            states.put("LA2", ((state & 2) != 0));
            states.put("LA3", ((state & 4) != 0));
            states.put("LA4", ((state & 8) != 0));
            return states;
        } catch (IOException e) {
            Log.e(TAG, "Error reading logic analyzer state", e);
        }
        return null;
    }

    /**
     * Fetch the state of given input ID.
     *
     * @param inputID the input channel
     *                'LA1' -> state of LA1
     *                'LA4' -> state of LA4
     * @return the logic level on the specified input (LA1,LA2,LA3, or LA4)
     */
    public Boolean getState(String inputID) {
        return this.getStates().get(inputID);
    }

    /**
     * set the logic level on digital outputs SQR1,SQR2,SQR3,SQR4.
     *
     * @param args SQR1,SQR2,SQR3,SQR4
     *             states(0 or 1)
     */
    public void setState(Map<String, Integer> args) {
        int data = 0;
        if (args.containsKey("SQR1")) {
            data |= (0x10 | args.get("SQR1"));
        }
        if (args.containsKey("SQR2")) {
            data |= (0x20 | (args.get("SQR2") << 1));
        }
        if (args.containsKey("SQR3")) {
            data |= (0x40 | (args.get("SQR3") << 2));
        }
        if (args.containsKey("SQR4")) {
            data |= (0x80 | (args.get("SQR4") << 3));
        }
        try {
            mPacketHandler.sendByte(mCommandsProto.DOUT);
            mPacketHandler.sendByte(mCommandsProto.SET_STATE);
            mPacketHandler.sendByte(data);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error reading digital output state", e);
        }

    }

    /**
     * Count pulses on a digital input. Retrieve total pulses using readPulseCount.
     *
     * @param channel The input pin to measure rising edges on : ['LA1','LA2','LA3','LA4','RES','EXT','FRQ']
     */
    public void countPulses(String channel) {
        if (channel == null) channel = "RES";
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.START_COUNTING);
            mPacketHandler.sendByte(this.calculateDigitalChannel(channel));
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
    }

    /**
     * Read pulses counted using a digital input. Call countPulses before using this.
     *
     * @return number of pulse.
     */
    public int readPulseCount() {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.FETCH_COUNT);
            int count = mPacketHandler.getVoltageSummation();
            return 10 * count;
        } catch (IOException e) {
            Log.e(TAG, "Error getting pulse count", e);
        }
        return -1;
    }

    public void setCapacitorState(int state, int t) {
        try {
            mPacketHandler.sendByte(mCommandsProto.ADC);
            mPacketHandler.sendByte(mCommandsProto.SET_CAP);
            mPacketHandler.sendByte(state);
            mPacketHandler.sendInt(t);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error getting capacitor state", e);
        }
    }

    public double[] captureCapacitance(int samples, int timeGap) {
        AnalyticsClass analyticsClass = new AnalyticsClass();
        this.setCapacitorState(1, 50000);
        Map<String, double[]> data = this.captureFullSpeedHr("CAP", samples, timeGap, List.of("READ_CAP"));
        double[] x = data.get("x");
        double[] y = data.get("y");
        for (int i = 0; i < x.length; i++) {
            x[i] = x[i] * 1e-6;
        }
        ArrayList<double[]> fitres = analyticsClass.fitExponential(x, y);
        if (fitres != null) {
            // Not return extra data as in python-communication library. Not required at this point.
            return fitres.get(0);
        }
        return null;
    }

    public Double capacitanceViaRCDischarge() {
        double cap = getCapacitorRange()[1];
        double time = 2 * cap * 20e3 * 1e6; // uSec
        int samples = 500;
        if (time > 5000 && time < 10e6) {
            if (time > 50e3) samples = 250;
            double RC = this.captureCapacitance(samples, (int) (time / samples))[1];
            return RC / 10e3;
        } else {
            Log.v(TAG, "cap out of range " + time + cap);
            return null;
        }
    }

    /**
     * Charges a capacitor connected to IN1 via a 20K resistor from a 3.3V source for a fixed interval.
     *
     * @param cTime range of time
     * @return the capacitance calculated using the formula Vc = Vs(1-exp(-t/RC))
     */
    public double[] getCapacitorRange(int cTime) {
        // returns values as a double array arr[0] = v,  arr[1] = c
        this.dischargeCap(30000, 1000);
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.GET_CAP_RANGE);
            mPacketHandler.sendInt(cTime);
            int vSum = mPacketHandler.getVoltageSummation();
            double v = vSum * 3.3 / 16 / 4095;
            double c = -cTime * 1e-6 / 1e4 / Math.log(1 - v / 3.3);
            return new double[]{v, c};
        } catch (IOException e) {
            Log.e(TAG, "Error getting capacitor range", e);
        }
        return null;
    }

    /**
     * Charges a capacitor connected to IN1 via a 20K resistor from a 3.3V source for a fixed interval
     *
     * @return the capacitance calculated using the formula Vc = Vs(1-exp(-t/RC))
     */
    public double[] getCapacitorRange() {
        double[] range = new double[]{1.5, 50e-12};
        for (int i = 0; i < 4; i++) {
            range = getCapacitorRange(50 * (int) (pow(10, i)));
            if (range[0] > 1.5) {
                if (i == 0 && range[0] > 3.28) {
                    range[1] = 50e-12;
                }
                break;
            }
        }
        return range;
    }

    public void dischargeCap(int dischargeTime, double timeout) {
        Instant startTime = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startTime = Instant.now();
        }
        double voltage = getVoltage("CAP", 1);
        double previousVoltage = voltage;

        while (voltage > CAPACITOR_DISCHARGE_VOLTAGE) {
            setCapacitorState(0, dischargeTime);
            voltage = getVoltage("CAP", 1);

            if (Math.abs(previousVoltage - voltage) < CAPACITOR_DISCHARGE_VOLTAGE) {
                break;
            }

            previousVoltage = voltage;

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (Duration.between(startTime, Instant.now()).toMillis() > timeout) {
                    break;
                }
            }
        }
    }

    /**
     * Measures capacitance of component connected between CAP and ground
     *
     * @return Capacitance (F)
     */
    public Double getCapacitance() {
        double[] GOOD_VOLTS = new double[]{2.5, 3.3};
        int CT = 10;
        int CR = 1;
        int iterations = 0;
        long startTime = System.currentTimeMillis() / 1000;
        while (System.currentTimeMillis() / 1000 - startTime < 5) {
            if (CT > 65000) {
                Log.v(TAG, "CT too high");
                CT = (int) (CT / pow(10, 4 - CR));
                CR = 0;
            }
            double[] temp = getCapacitance(CR, 0, CT);
            double V = temp[0];
            double C = temp[1];
            if (CT > 30000 && V < 0.1) {
                Log.v(TAG, "Capacitance too high for this method");
                return null;
            } else if (V > GOOD_VOLTS[0] && V < GOOD_VOLTS[1])
                return C;
            else if (V < GOOD_VOLTS[0] && V > 0.01 && CT < 40000) {
                if (GOOD_VOLTS[0] / V > 1.1 && iterations < 10) {
                    CT = (int) (CT * GOOD_VOLTS[0] / V);
                    iterations += 1;
                    Log.v(TAG, "Increased CT " + CT);
                } else if (iterations == 10)
                    return null;
                else return C;
            } else if (V <= 0.1 && CR <= 3)
                if (CR == 3) {
                    CR = 0;
                } else {
                    CR += 1;
                }
            else if (CR == 0) {
                Log.v(TAG, "Capacitance too high!");
                return capacitanceViaRCDischarge();
            }
        }
        return null;
    }

    public double[] getCapacitance(int currentRange, double trim, int chargeTime) {  // time in uSec
        this.dischargeCap(30000, 1000);
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.GET_CAPACITANCE);
            mPacketHandler.sendByte(currentRange);
            if (trim < 0)
                mPacketHandler.sendByte((int) (31 - Math.abs(trim) / 2) | 32);
            else
                mPacketHandler.sendByte((int) trim / 2);
            mPacketHandler.sendInt(chargeTime);
            Thread.sleep((long) (chargeTime * 1e-6 + .02));
            int VCode;
            int i = 0;
            do VCode = mPacketHandler.getVoltageSummation();
            while (VCode == -1 & i++ < 10);
            double v = 3.3 * VCode / 4095;
            double chargeCurrent = this.currents[currentRange] * (100 + trim) / 100.0;
            double c = 0;
            if (v != 0) {
                c = (chargeCurrent * chargeTime * 1e-6 / v - this.SOCKET_CAPACITANCE);
            }
            return new double[]{v, c};
        } catch (IOException | InterruptedException e) {
            Log.e(TAG, "Error getting capacitance", e);
        }
        return null;
    }

    /**
     * Temperature of the MCU in degrees Celsius.
     *
     * @return temperature : double
     */
    public double getTemperature() {
        // TODO: Get rid of magic numbers
        int cs = 3;
        double V = getCTMUVoltage(CTMU_CHANNEL, cs, 0);
        if (cs == 1) {
            return (646 - V * 1000) / 1.92; // current source = 1
        } else if (cs == 2) {
            return (701.5 - V * 1000) / 1.74; // current source = 2
        } else {
            return (760 - V * 1000) / 1.56; // current source = 3
        }
    }

    /**
     * Control the Charge Time Measurement Unit (CTMU).
     * <p>get_ctmu_voltage(5,2)  will activate a constant current source of 5.5uA on CAP and then measure the voltage at the output.</p>
     * <p>If a diode is used to connect CAP to ground, the forward voltage drop of the diode will be returned, e.g. 0.6 V for a 4148 diode.</p>
     * <p>If a resistor is connected, Ohm's law will be followed within reasonable limits.</p>
     *
     * @param channel int
     *                <p>Pin number on which to generate a current and measure output
     *                voltage. Refer to the PIC24EP64GP204 datasheet for channel</p>
     *                numbering.
     * @param cRange  {0, 1, 2, 3}
     *                <p>0 -> 550 uA
     *                1 -> 550 nA
     *                2 -> 5.5 uA
     *                3 -> 55 uA</p>
     * @param tgen    int, optional
     *                <p>Use Time Delay mode instead of Measurement mode. The default value
     *                is True.</p>
     * @return voltage : double
     */
    public double getCTMUVoltage(int channel, int cRange, int tgen) {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.GET_CTMU_VOLTAGE);
            mPacketHandler.sendByte((channel) | (cRange << 5) | (tgen << 7));
            double raw_voltage = (double) mPacketHandler.getInt() / 16; // 16*voltage across the current source
            mPacketHandler.getAcknowledgement();
            double max_voltage = 3.3;
            double resolution = 12;
            return (max_voltage * raw_voltage / (pow(2, resolution) - 1));
        } catch (IOException e) {
            Log.e(TAG, "Error getting CTMU voltage", e);
        }
        return -1;
    }

    public double getCTMUVoltage(int channel, int cRange) {
        return getCTMUVoltage(channel, cRange, 1);
    }

    public void startCTMU(int cRange, int trim, int tgen) {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.START_CTMU);
            mPacketHandler.sendByte(cRange | (tgen << 7));
            mPacketHandler.sendByte(trim);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error getting CTMU voltage", e);
        }
    }

    public void startCTMU(int cRange, int trim) {
        startCTMU(cRange, trim, 1);
    }

    public void stopCTMU() {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.STOP_CTMU);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error getting CTMU voltage", e);
        }
    }

    public void resetDevice() {
        /*
        Reset the device. Standalone mode will be enabled if an OLED is connected to the I2C port.
        */
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.RESTORE_STANDALONE);
        } catch (IOException e) {
            Log.e(TAG, "Error resetting device", e);
        }
    }

    /**
     * Reboot and stay in bootloader mode.
     *
     * @throws IOException
     * @throws InterruptedException
     */
    public void enterBootloader() throws Exception {
        mCommunicationHandler.close();
        mCommunicationHandler.open(460800);
        mPacketHandler = new PacketHandler(50, mCommunicationHandler);
        // The PSLab's RGB LED flashes some colors on boot.
        int bootLightShowTime = 600;
        // Wait before sending magic number to make sure UART is initialized.
        Thread.sleep(bootLightShowTime / 2);
        // PIC24 UART RX buffer is four bytes deep; no need to time it perfectly.
        mPacketHandler.commonWrite(mCommandsProto.pack(0xDECAFBAD));
        // Wait until lightshow is done to prevent accidentally overwriting magic number.
        Thread.sleep(bootLightShowTime);
    }

    /**
     * Set shade of a WS2812 RGB LED.
     *
     * @param colors ArrayList
     *               <p>List of three values between 0-255, where each value is the
     *               intensity of red, green and blue, respectively. When daisy
     *               chaining several LEDs, colors should be a list of three-value
     *               lists.</p>
     * @param output {"RGB", "PGC", "SQ1"}, optional
     *               <p>Pin on which to output the pulse train setting the LED color. The
     *               default value, "RGB", sets the color of the built-in WS2812B
     *               (PSLav v6 only).</p>
     * @param order  String, optional
     *               <p>Color order of the connected LED as a three-letter string. The
     *               built-in LED has order "GRB", which is the default.</p>
     */
    public void RGBLED(ArrayList<ArrayList<Integer>> colors, String output, String order) {
        HashMap<String, Integer> pins = new HashMap<>();
        int pin;
        if (CommunicationHandler.PSLAB_VERSION == 6) {
            pins.put("ONBOARD", 0);
            pins.put("SQR1", 1);
            pins.put("SQR2", 2);
            pins.put("SQR3", 3);
            pins.put("SQR4", 4);
        } else {
            pins.put("RGB", mCommandsProto.SET_RGB1);
            pins.put("PGC", mCommandsProto.SET_RGB2);
            pins.put("SQ1", mCommandsProto.SET_RGB3);
        }

        if (!pins.containsKey(output)) {
            String outputPins = String.join(", ", pins.keySet());
            throw new IllegalArgumentException("Invalid output: " + output + ". output must be one of : " + outputPins);
        }
        pin = Objects.requireNonNull(pins.get(output));

        for (ArrayList<Integer> color : colors) {
            if (color.size() != 3) {
                throw new IllegalArgumentException("Invalid colo; each color list must have three values.");
            }
        }

        order = order.toUpperCase(Locale.ROOT);
        char[] orderChars = order.toCharArray();
        Arrays.sort(orderChars);
        if (!Arrays.equals(orderChars, new char[]{'B', 'G', 'R'})) {
            throw new IllegalArgumentException("Invalid order: " + order + ". order must contain 'R', 'G', and 'B'.");
        }

        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);

            if (CommunicationHandler.PSLAB_VERSION == 6) {
                mPacketHandler.sendByte(mCommandsProto.SET_RGB_COMMON);
            } else {
                mPacketHandler.sendByte(pin);
            }

            mPacketHandler.sendByte(colors.size() * 3);

            for (ArrayList<Integer> color : colors) {
                mPacketHandler.sendByte(color.get(order.indexOf('R')));
                mPacketHandler.sendByte(color.get(order.indexOf('G')));
                mPacketHandler.sendByte(color.get(order.indexOf('B')));
            }

            if (CommunicationHandler.PSLAB_VERSION == 6) {
                mPacketHandler.sendByte(pin);
            }

            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error using RGB LED", e);
        }
    }

    public void RGBLED(ArrayList<Integer> colors, String output) {
        RGBLED(new ArrayList<>(Collections.singletonList(colors)), output, "GRB");
    }

    /* WAVEGEN SECTION */

    public void setWave(String channel, double frequency) {
        if ("SI1".equals(channel))
            this.setSI1(frequency, null);
        else if ("SI2".equals(channel))
            this.setSI2(frequency, null);
    }

    public double setSine1(double frequency) {
        return this.setSI1(frequency, "sine");
    }

    public double setSine2(double frequency) {
        return this.setSI2(frequency, "sine");
    }

    public double setSI1(double frequency, String waveType) {
        int HIGHRES, tableSize;
        if (frequency < 0.1) {
            Log.v(TAG, "frequency too low");
            return -1;
        } else if (frequency < 1100) {
            HIGHRES = 1;
            tableSize = 512;
        } else {
            HIGHRES = 0;
            tableSize = 32;
        }
        if (waveType != null) {
            if ("sine".equals(waveType) | "tria".equals(waveType)) {
                if (!(this.waveType.get("SI1").equals(waveType))) {
                    this.loadEquation("SI1", waveType);
                }
            } else {
                Log.v(TAG, "Not a valid waveform. try sine or tria");
            }
        }
        int[] p = new int[]{1, 8, 64, 256};
        int prescalar = 0, wavelength = 0;
        while (prescalar <= 3) {
            wavelength = (int) (64e6 / frequency / p[prescalar] / tableSize);
            frequency = 64e6 / wavelength / p[prescalar] / tableSize;
            if (wavelength < 65525) break;
            prescalar++;
        }
        if (prescalar == 4) {
            Log.v(TAG, "Out of range");
            return -1;
        }
        try {
            mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
            mPacketHandler.sendByte(mCommandsProto.SET_SINE1);
            mPacketHandler.sendByte(HIGHRES | (prescalar << 1));
            mPacketHandler.sendInt(wavelength - 1);
            mPacketHandler.getAcknowledgement();
            this.sin1Frequency = frequency;
            return this.sin1Frequency;
        } catch (IOException e) {
            Log.e(TAG, "Error setting SI1", e);
        }
        return -1;
    }

    public double setSI2(double frequency, String waveType) {
        int HIGHRES;
        int tableSize;
        if (frequency < 0.1) {
            Log.v(TAG, "frequency too low");
            return -1;
        } else if (frequency < 1100) {
            HIGHRES = 1;
            tableSize = 512;
        } else {
            HIGHRES = 0;
            tableSize = 32;
        }
        if (waveType != null) {
            if ("sine".equals(waveType) | "tria".equals(waveType)) {
                if (!(this.waveType.get("SI2").equals(waveType))) {
                    this.loadEquation("SI2", waveType);
                }
            } else {
                Log.v(TAG, "Not a valid waveform. try sine or tria");
            }
        }
        int[] p = new int[]{1, 8, 64, 256};
        int prescalar = 0, wavelength = 0;
        while (prescalar <= 3) {
            wavelength = (int) (64e6 / frequency / p[prescalar] / tableSize);
            frequency = 64e6 / wavelength / p[prescalar] / tableSize;
            if (wavelength < 65525) break;
            prescalar++;
        }
        if (prescalar == 4) {
            Log.v(TAG, "Out of range");
            return -1;
        }
        try {
            mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
            mPacketHandler.sendByte(mCommandsProto.SET_SINE2);
            mPacketHandler.sendByte(HIGHRES | (prescalar << 1));
            mPacketHandler.sendInt(wavelength - 1);
            mPacketHandler.getAcknowledgement();
            this.sin2Frequency = frequency;
            return this.sin2Frequency;
        } catch (IOException e) {
            Log.e(TAG, "Error setting SI2", e);
        }
        return -1;
    }

    public double readBackWaveform(String channel) {
        if ("SI1".equals(channel))
            return this.sin1Frequency;
        else if ("SI2".equals(channel))
            return this.sin2Frequency;
        else if ("SQR".startsWith(channel))
            return this.squareWaveFrequency.get(channel);
        return -1;
    }

    public double setWaves(double frequency, double phase, double frequency2) {
        // used frequency as double ( python code demanded ), maybe its taken in KHz or something ( Clarify )
        int HIGHRES, tableSize, HIGHRES2, tableSize2, wavelength = 0, wavelength2 = 0;
        if (frequency2 == -1) frequency2 = frequency;
        if (frequency < 0.1) {
            Log.v(TAG, "frequency 1 too low");
            return -1;
        } else if (frequency < 1100) {
            HIGHRES = 1;
            tableSize = 512;
        } else {
            HIGHRES = 0;
            tableSize = 32;
        }
        if (frequency2 < 0.1) {
            Log.v(TAG, "frequency 2 too low");
            return -1;
        } else if (frequency2 < 1100) {
            HIGHRES2 = 1;
            tableSize2 = 512;
        } else {
            HIGHRES2 = 0;
            tableSize2 = 32;
        }
        if (frequency < 1 || frequency2 < 1)
            Log.v(TAG, "extremely low frequencies will have reduced amplitudes due to AC coupling restrictions");

        int[] p = new int[]{1, 8, 64, 256};
        int prescalar = 0;
        double retFrequency = 0;
        while (prescalar <= 3) {
            wavelength = (int) (64e6 / frequency / p[prescalar] / tableSize);
            retFrequency = 64e6 / wavelength / p[prescalar] / tableSize;
            if (wavelength < 65525) break;
            prescalar++;
        }
        if (prescalar == 4) {
            Log.v(TAG, "#1 out of range");
            return -1;
        }
        int prescalar2 = 0;
        double retFrequency2 = 0;
        while (prescalar2 <= 3) {
            wavelength2 = (int) (64e6 / frequency2 / p[prescalar2] / tableSize2);
            retFrequency2 = 64e6 / wavelength2 / p[prescalar2] / tableSize2;
            if (wavelength2 < 65525) break;
            prescalar2++;
        }
        if (prescalar2 == 4) {
            Log.v(TAG, "#2 out of range");
            return -1;
        }

        int phaseCoarse = (int) (tableSize2 * (phase) / 360.);
        int phaseFine = (int) (wavelength2 * (phase - (phaseCoarse) * 360. / tableSize2) / (360. / tableSize2));
        try {
            mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
            mPacketHandler.sendByte(mCommandsProto.SET_BOTH_WG);
            mPacketHandler.sendInt(wavelength - 1);
            mPacketHandler.sendInt(wavelength2 - 1);
            mPacketHandler.sendInt(phaseCoarse);
            mPacketHandler.sendInt(phaseFine);
            mPacketHandler.sendByte((prescalar2 << 4) | (prescalar << 2) | (HIGHRES2 << 1) | (HIGHRES));
            mPacketHandler.getAcknowledgement();
            this.sin1Frequency = retFrequency;
            this.sin2Frequency = retFrequency2;
            return retFrequency;
        } catch (IOException e) {
            Log.e(TAG, "Error setting waves", e);
        }
        return -1;
    }

    public void loadEquation(String channel, String function) {
        double[] span = new double[2];
        if ("sine".equals(function)) {
            span[0] = 0;
            span[1] = 2 * Math.PI;
            waveType.put(channel, "sine");
        } else if ("tria".equals(function)) {
            span[0] = 0;
            span[1] = 4;
            waveType.put(channel, "tria");
        } else {
            waveType.put(channel, "arbit");
        }
        double factor = (span[1] - span[0]) / 512;
        ArrayList<Double> x = new ArrayList<>();
        ArrayList<Double> y = new ArrayList<>();
        // for now using switch, proper way is to create an interface and pass it to loadEquation and call interface methods for calculation
        for (int i = 0; i < 512; i++) {
            x.add(span[0] + i * factor);
            switch (function) {
                case "sine":
                    y.add(Math.sin(x.get(i)));
                    break;
                case "tria":
                    y.add(Math.abs(x.get(i) % 4 - 2));
                    break;
            }
        }
        loadTable(channel, y, waveType.get(channel), -1);
    }

    private void loadTable(String channel, ArrayList<Double> y, String mode, double amp) {
        waveType.put(channel, mode);
        ArrayList<String> channels = new ArrayList<>();
        ArrayList<Double> points = y;
        channels.add("SI1");
        channels.add("SI2");
        int num;
        if (channels.contains(channel)) {
            num = channels.indexOf(channel) + 1;
        } else {
            Log.e(TAG, "Channel does not exist. Try SI1 or SI2");
            return;
        }

        if (amp == -1) amp = 0.95;
        double LARGE_MAX = 511 * amp, SMALL_MAX = 63 * amp;
        double min = Collections.min(y);
        for (int i = 0; i < y.size(); i++) {
            y.set(i, y.get(i) - min);
        }
        double max = Collections.max(y);
        ArrayList<Integer> yMod1 = new ArrayList<>();
        for (int i = 0; i < y.size(); i++) {
            double temp = 1 - (y.get(i) / max);
            yMod1.add((int) Math.round(LARGE_MAX - LARGE_MAX * temp));
        }
        y = new ArrayList<>();


        for (int i = 0; i < points.size(); i += 16) {
            y.add(points.get(i));
        }
        min = Collections.min(y);
        for (int i = 0; i < y.size(); i++) {
            y.set(i, y.get(i) - min);
        }
        max = Collections.max(y);
        ArrayList<Integer> yMod2 = new ArrayList<>();
        for (int i = 0; i < y.size(); i++) {
            double temp = 1 - (y.get(i) / max);
            yMod2.add((int) Math.round(SMALL_MAX - SMALL_MAX * temp));
        }

        try {
            mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
            switch (num) {
                case 1:
                    mPacketHandler.sendByte(mCommandsProto.LOAD_WAVEFORM1);
                    break;
                case 2:
                    mPacketHandler.sendByte(mCommandsProto.LOAD_WAVEFORM2);
                    break;
            }
            for (int a : yMod1)
                mPacketHandler.sendInt(a);

            for (int a : yMod2)
                mPacketHandler.sendByte(a);

            // sleep for 0.01
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error loading table", e);
        }
    }


    public double setSqr1(double frequency, double dutyCycle, boolean onlyPrepare) {
        if (dutyCycle == -1) dutyCycle = 50;
        if (frequency == 0 || dutyCycle == 0) return -1;
        if (frequency > 10e6) {
            Log.v(TAG, "Frequency is greater than 10MHz. Please use map_reference_clock for 16 & 32MHz outputs");
            return 0;
        }
        int[] p = new int[]{1, 8, 64, 256};
        int prescalar = 0;
        int wavelength = 0;
        while (prescalar <= 3) {
            wavelength = (int) (64e6 / frequency / p[prescalar]);
            if (wavelength < 65525) break;
            prescalar++;
        }
        if (prescalar == 4 || wavelength == 0) {
            Log.v(TAG, "Out of Range");
            return -1;
        }
        int highTime = (int) (wavelength * dutyCycle / 100);
        if (onlyPrepare) {
            Map<String, Integer> args = new LinkedHashMap<>();
            args.put("SQR1", 0);
            this.setState(args);
        }
        try {
            mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
            mPacketHandler.sendByte(mCommandsProto.SET_SQR1);
            mPacketHandler.sendInt(Math.round(wavelength));
            mPacketHandler.sendInt(Math.round(highTime));
            if (onlyPrepare) prescalar |= 0x4;
            mPacketHandler.sendByte(prescalar);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        this.squareWaveFrequency.put("SQR1", 64e6 / wavelength / p[prescalar & 0x3]);
        return this.squareWaveFrequency.get("SQR1");
    }

    public double setSqr2(double frequency, double dutyCycle) {
        int[] p = new int[]{1, 8, 64, 256};
        int prescalar = 0;
        int wavelength = 0;
        while (prescalar <= 3) {
            wavelength = (int) (64e6 / frequency / p[prescalar]);
            if (wavelength < 65525) break;
            prescalar++;
        }
        if (prescalar == 4 || wavelength == 0) {
            Log.v(TAG, "Out of Range");
            return -1;
        }
        int highTime = (int) (wavelength * dutyCycle / 100);
        try {
            mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
            mPacketHandler.sendByte(mCommandsProto.SET_SQR2);
            mPacketHandler.sendInt(Math.round(wavelength));
            mPacketHandler.sendInt(Math.round(highTime));
            mPacketHandler.sendByte(prescalar);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        this.squareWaveFrequency.put("SQR2", 64e6 / wavelength / p[prescalar & 0x3]);
        return this.squareWaveFrequency.get("SQR2");
    }

    public void setSqrs(int wavelength, int phase, int highTime1, int highTime2, int prescalar) {
        if (prescalar == -1) prescalar = 1;
        try {
            mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
            mPacketHandler.sendByte(mCommandsProto.SET_SQRS);
            mPacketHandler.sendInt(wavelength);
            mPacketHandler.sendInt(phase);
            mPacketHandler.sendInt(highTime1);
            mPacketHandler.sendInt(highTime2);
            mPacketHandler.sendByte(prescalar);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
    }

    public double sqrPWM(double frequency, double h0, double p1, double h1, double p2, double h2, double p3, double h3, boolean pulse) {
        if (frequency == 0) return -1;
        if (h0 == 0) {
            h0 = 0.1;
        }
        if (h1 == 0) {
            h1 = 0.1;
        }
        if (h2 == 0) {
            h2 = 0.1;
        }
        if (h3 == 0) {
            h3 = 0.1;
        }
        if (frequency > 10e6) {
            Log.v(TAG, "Frequency is greater than 10MHz. Please use map_reference_clock for 16 & 32MHz outputs");
            return -1;
        }
        int[] p = new int[]{1, 8, 64, 256};
        int prescalar = 0, wavelength = 0;
        while (prescalar <= 3) {
            wavelength = (int) (64e6 / frequency / p[prescalar]);
            if (wavelength < 65525) break;
            prescalar++;
        }
        if (prescalar == 4 || wavelength == 0) {
            Log.v(TAG, "Out of Range");
            return -1;
        }
        if (!pulse) prescalar |= (1 << 5);
        int a1 = (int) (p1 % 1 * wavelength), b1 = (int) ((h1 + p1) % 1 * wavelength);
        int a2 = (int) (p2 % 1 * wavelength), b2 = (int) ((h2 + p2) % 1 * wavelength);
        int a3 = (int) (p3 % 1 * wavelength), b3 = (int) ((h3 + p3) % 1 * wavelength);
        try {
            mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
            mPacketHandler.sendByte(mCommandsProto.SQR4);
            mPacketHandler.sendInt(wavelength - 1);
            mPacketHandler.sendInt((int) (wavelength * h0) - 1);
            mPacketHandler.sendInt(Math.max(0, a1 - 1));
            mPacketHandler.sendInt(Math.max(1, b1 - 1));
            mPacketHandler.sendInt(Math.max(0, a2 - 1));
            mPacketHandler.sendInt(Math.max(1, b2 - 1));
            mPacketHandler.sendInt(Math.max(0, a3 - 1));
            mPacketHandler.sendInt(Math.max(1, b3 - 1));
            mPacketHandler.sendByte(prescalar);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        for (String channel : new String[]{"SQR1", "SQR2", "SQR3", "SQR4"}) {
            this.squareWaveFrequency.put(channel, 64e6 / wavelength / p[prescalar & 0x3]);
        }
        return (int) (64e6 / wavelength / p[prescalar & 0x3]);
    }

    public void mapReferenceClock(ArrayList<String> args, int scalar) {
        try {
            mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
            mPacketHandler.sendByte(mCommandsProto.MAP_REFERENCE);
            int channel = 0;
            if (args.contains("SQR1")) channel |= 1;
            if (args.contains("SQR2")) channel |= 2;
            if (args.contains("SQR3")) channel |= 4;
            if (args.contains("SQR4")) channel |= 8;
            if (args.contains("WAVEGEN")) channel |= 16;
            mPacketHandler.sendByte(channel);
            mPacketHandler.sendByte(scalar);
            if (args.contains("WAVEGEN")) {
                this.DDS_CLOCK = (int) 128e6 / (1 << scalar);
            }
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
    }

    /*  ANALOG OUTPUTS  */

    public void setVoltage(String channel, float voltage) {
        DACChannel dacChannel = dacChannels.get(channel);
        int v = (int) (Math.round(dacChannel.VToCode.value(voltage)));
        try {
            mPacketHandler.sendByte(mCommandsProto.DAC);
            mPacketHandler.sendByte(mCommandsProto.SET_POWER);
            mPacketHandler.sendByte(dacChannel.channelCode);
            mPacketHandler.sendInt(v);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        values.put(channel, (double) voltage);
    }

    private void setCurrent(float current) {
        DACChannel dacChannel = dacChannels.get("PCS");
        int v = 3300 - (int) (Math.round(dacChannel.VToCode.value(current)));
        try {
            mPacketHandler.sendByte(mCommandsProto.DAC);
            mPacketHandler.sendByte(mCommandsProto.SET_POWER);
            mPacketHandler.sendByte(dacChannel.channelCode);
            mPacketHandler.sendInt(v);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        values.put("PCS", (double) current);
    }

    private double getVoltage(String channel) {
        return this.values.get(channel);
    }

    public void setPV1(float value) {
        this.setVoltage("PV1", value);
    }

    public void setPV2(float value) {
        this.setVoltage("PV2", value);
    }

    public void setPV3(float value) {
        this.setVoltage("PV3", value);
    }

    public void setPCS(float value) {
        this.setCurrent(value);
    }

    public double getPV1() {
        return this.getVoltage("PV1");
    }

    public double getPV2() {
        return this.getVoltage("PV2");
    }

    public double getPV3() {
        return this.getVoltage("PV3");
    }

    public double getPCS() {
        return this.getVoltage("PCS");
    }

    /* READ PROGRAM AND DATA ADDRESSES */

    public long deviceID() {
        long a = readProgramAddress(0x800FF8);
        long b = readProgramAddress(0x800FFA);
        long c = readProgramAddress(0x800FFC);
        long d = readProgramAddress(0x800FFE);
        long value = d | (c << 16) | (b << 32) | (a << 48);
        Log.v(TAG, "device ID : " + value);
        return value;
    }

    /**
     * Return the value stored at the specified address in program memory.
     *
     * @param address int
     *                <p>Address to read from. Refer to PIC24EP64GP204 programming manual.</p>
     * @return data : int <p>16-bit wide value read from program memory.</p>
     */
    public int readProgramAddress(int address) {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.READ_PROGRAM_ADDRESS);
            mPacketHandler.sendInt(address & 0xffff);
            mPacketHandler.sendInt((address >> 16) & 0xffff);
            int data = mPacketHandler.getInt();
            mPacketHandler.getAcknowledgement();
            return data;
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        return -1;
    }

    /**
     * Return the value stored at the specified address in RAM.
     *
     * @param address int
     *                <p>Address to read from. Refer to PIC24EP64GP204 programming manual.</p>
     * @return data : int <p>16-bit wide value read from RAM.</p>
     */
    public int readDataAddress(int address) {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.READ_DATA_ADDRESS);
            mPacketHandler.sendInt(address & 0xffff);
            int data = mPacketHandler.getInt();
            mPacketHandler.getAcknowledgement();
            return data;
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        return -1;
    }

    /**
     * Write a value to the specified address in RAM.
     *
     * @param address int
     *                <p>Address to write to. Refer to PIC24EP64GP204 programming manual.</p>
     * @param value   int
     *                <p>Value to write to RAM.</p>
     */
    public void writeDataAddress(int address, int value) {
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.WRITE_DATA_ADDRESS);
            mPacketHandler.sendInt(address & 0xffff);
            mPacketHandler.sendInt(value);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
    }

    /**
     * Relay all data received by the device to TXD/RXD.
     * <p>
     * If a period > 0.5 seconds elapses between two transmit/receive events,
     * the device resets and resumes normal mode. This timeout feature has
     * been implemented in lieu of a hard reset option.
     * </p>
     * <p>
     * Can be used to load programs into secondary microcontrollers with
     * bootloaders such as ATMEGA OR ESP8266.
     * </p>
     *
     * @param baudrate int
     *                 <p>Baudrate of the UART bus.</p>
     * @param persist  bool, optional
     *                 <p>If set to True, the device will stay in passthrough mode until the
     *                 next power cycle. Otherwise(default scenario), the device will
     *                 return to normal operation if no data is sent/received for a period
     *                 greater than one second at a time.</p>
     */
    public void enableUARTPassThrough(int baudrate, boolean persist) {
        try {
            mPacketHandler.sendByte(mCommandsProto.PASSTHROUGHS);
            mPacketHandler.sendByte(mCommandsProto.PASS_UART);
            if (persist)
                mPacketHandler.sendByte(1);
            else
                mPacketHandler.sendByte(0);
            mPacketHandler.sendInt((int) Math.round(((64e6 / baudrate) / 4) - 1));
            Log.v(TAG, "BRG2VAL: " + Math.round(((64e6 / baudrate) / 4) - 1));
            // sleep for 0.1 sec
            byte[] junk = new byte[100];
            mPacketHandler.read(junk, 100);
            // Log junk to see :D
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
    }

    /* MOTOR SIGNALLING */

    public void servo4(double angle1, double angle2, double angle3, double angle4) {
        int params = (1 << 5) | 2;
        try {
            mPacketHandler.sendByte(mCommandsProto.WAVEGEN);
            mPacketHandler.sendByte(mCommandsProto.SQR4);
            mPacketHandler.sendInt(10000);
            mPacketHandler.sendInt(750 + (int) (angle1 * 1900 / 180));
            mPacketHandler.sendInt(0);
            mPacketHandler.sendInt(750 + (int) (angle2 * 1900 / 180));
            mPacketHandler.sendInt(0);
            mPacketHandler.sendInt(750 + (int) (angle3 * 1900 / 180));
            mPacketHandler.sendInt(0);
            mPacketHandler.sendInt(750 + (int) (angle4 * 1900 / 180));
            mPacketHandler.sendByte(params);
            mPacketHandler.getAcknowledgement();
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
    }

    /**
     * Read hardware debug log.
     *
     * @return log : String <p>Bytes read from the hardware debug log.</p>
     */
    public String readLog() {
        String log = "";
        try {
            mPacketHandler.sendByte(mCommandsProto.COMMON);
            mPacketHandler.sendByte(mCommandsProto.READ_LOG);
        } catch (IOException e) {
            Log.e(TAG, "Error sending data", e);
        }
        return mPacketHandler.readLine();
    }

    public void disconnect() throws IOException {
        if (mCommunicationHandler != null) {
            mCommunicationHandler.close();
        }
        PacketHandler.version = "";
    }
}