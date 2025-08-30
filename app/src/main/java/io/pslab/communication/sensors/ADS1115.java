package io.pslab.communication.sensors;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import io.pslab.communication.peripherals.I2C;

public class ADS1115 {
    private static final int ADDRESS = 0x48;
    private final I2C i2c;

    private static final int REG_POINTER_MASK = 0x3;
    private static final int REG_POINTER_CONVERT = 0;
    private static final int REG_POINTER_CONFIG = 1;
    private static final int REG_POINTER_LOWTHRESH = 2;
    private static final int REG_POINTER_HITHRESH = 3;

    private static final int REG_CONFIG_OS_MASK = 0x8000;
    private static final int REG_CONFIG_OS_SINGLE = 0x8000;
    private static final int REG_CONFIG_OS_BUSY = 0x0000;
    private static final int REG_CONFIG_OS_NOTBUSY = 0x8000;

    private static final int REG_CONFIG_MUX_MASK = 0x7000;
    private static final int REG_CONFIG_MUX_DIFF_0_1 = 0x0000;
    private static final int REG_CONFIG_MUX_DIFF_0_3 = 0x1000;
    private static final int REG_CONFIG_MUX_DIFF_1_3 = 0x2000;
    private static final int REG_CONFIG_MUX_DIFF_2_3 = 0x3000;
    private static final int REG_CONFIG_MUX_SINGLE_0 = 0x4000;
    private static final int REG_CONFIG_MUX_SINGLE_1 = 0x5000;
    private static final int REG_CONFIG_MUX_SINGLE_2 = 0x6000;
    private static final int REG_CONFIG_MUX_SINGLE_3 = 0x7000;

    private static final int REG_CONFIG_PGA_MASK = 0x0E00;
    private static final int REG_CONFIG_PGA_6_144V = 0 << 9;
    private static final int REG_CONFIG_PGA_4_096V = 1 << 9;
    private static final int REG_CONFIG_PGA_2_048V = 2 << 9;
    private static final int REG_CONFIG_PGA_1_024V = 3 << 9;
    private static final int REG_CONFIG_PGA_0_512V = 4 << 9;
    private static final int REG_CONFIG_PGA_0_256V = 5 << 9;

    private static final int REG_CONFIG_MODE_MASK = 0x0100;
    private static final int REG_CONFIG_MODE_CONTIN = 0 << 8;
    private static final int REG_CONFIG_MODE_SINGLE = 1 << 8;

    private static final int REG_CONFIG_DR_MASK = 0x00E0;
    private static final int REG_CONFIG_DR_8SPS = 0 << 5;
    private static final int REG_CONFIG_DR_16SPS = 1 << 5;
    private static final int REG_CONFIG_DR_32SPS = 2 << 5;
    private static final int REG_CONFIG_DR_64SPS = 3 << 5;
    private static final int REG_CONFIG_DR_128SPS = 4 << 5;
    private static final int REG_CONFIG_DR_250SPS = 5 << 5;
    private static final int REG_CONFIG_DR_475SPS = 6 << 5;
    private static final int REG_CONFIG_DR_860SPS = 7 << 5;

    private static final int REG_CONFIG_CMODE_MASK = 0x0010;
    private static final int REG_CONFIG_CMODE_TRAD = 0x0000;
    private static final int REG_CONFIG_CMODE_WINDOW = 0x0010;

    private static final int REG_CONFIG_CPOL_MASK = 0x0008;
    private static final int REG_CONFIG_CPOL_ACTVLOW = 0x0000;
    private static final int REG_CONFIG_CPOL_ACTVHI = 0x0008;

    private static final int REG_CONFIG_CLAT_MASK = 0x0004;
    private static final int REG_CONFIG_CLAT_NONLAT = 0x0000;
    private static final int REG_CONFIG_CLAT_LATCH = 0x0004;

    private static final int REG_CONFIG_CQUE_MASK = 0x0003;
    private static final int REG_CONFIG_CQUE_1CONV = 0x0000;
    private static final int REG_CONFIG_CQUE_2CONV = 0x0001;
    private static final int REG_CONFIG_CQUE_4CONV = 0x0002;
    private static final int REG_CONFIG_CQUE_NONE = 0x0003;

    private static final Map<String, Integer> GAINS = new HashMap<>() {{
        put("GAIN_TWOTHIRDS", REG_CONFIG_PGA_6_144V);
        put("GAIN_ONE", REG_CONFIG_PGA_4_096V);
        put("GAIN_TWO", REG_CONFIG_PGA_2_048V);
        put("GAIN_FOUR", REG_CONFIG_PGA_1_024V);
        put("GAIN_EIGHT", REG_CONFIG_PGA_0_512V);
        put("GAIN_SIXTEEN", REG_CONFIG_PGA_0_256V);
    }};

    private static final Map<String, Double> GAIN_SCALING = new HashMap<>() {{
        put("GAIN_TWOTHIRDS", 0.1875);
        put("GAIN_ONE", 0.125);
        put("GAIN_TWO", 0.0625);
        put("GAIN_FOUR", 0.03125);
        put("GAIN_EIGHT", 0.015625);
        put("GAIN_SIXTEEN", 0.0078125);
    }};

    private static final Map<String, String> TYPE_SELECTION = new HashMap<>() {{
        put("UNI_0", "0");
        put("UNI_1", "1");
        put("UNI_2", "2");
        put("UNI_3", "3");
        put("DIFF_01", "01");
        put("DIFF_23", "23");
    }};

    private static final Map<Integer, Integer> SDR_SELECTION = new HashMap<>() {{
        put(8, REG_CONFIG_DR_8SPS);
        put(16, REG_CONFIG_DR_16SPS);
        put(32, REG_CONFIG_DR_32SPS);
        put(64, REG_CONFIG_DR_64SPS);
        put(128, REG_CONFIG_DR_128SPS);
        put(250, REG_CONFIG_DR_250SPS);
        put(475, REG_CONFIG_DR_475SPS);
        put(860, REG_CONFIG_DR_860SPS);
    }};

    private String channel;
    private String gain;
    private int rate;

    public ADS1115(I2C i2c) throws IOException, InterruptedException {
        this.i2c = i2c;
        channel = "UNI_0";
        gain = "GAIN_ONE";
        rate = 128;
    }

    private int readRegister(int register) throws IOException {
        List<Integer> vals = i2c.readBulk(ADDRESS, register, 2);
        return ((vals.get(0) & 0xFF) << 8) | (vals.get(1) & 0xFF);
    }

    private void writeRegister(int register, int value) throws IOException {
        i2c.writeBulk(ADDRESS, new int[]{register, (value >> 8) & 0xFF, value & 0xFF});
    }

    public void setGain(String gain) {
        /*options : 'GAIN_TWOTHIRDS','GAIN_ONE','GAIN_TWO','GAIN_FOUR','GAIN_EIGHT','GAIN_SIXTEEN'*/
        this.gain = gain;
    }

    public void setChannel(String channel) {
        /*options 'UNI_0','UNI_1','UNI_2','UNI_3','DIFF_01','DIFF_23'*/
        this.channel = channel;
    }

    public void setDataRate(int rate) {
        /*data rate options 8,16,32,64,128,250,475,860 SPS*/
        this.rate = rate;
    }

    private double readADCSingleEnded(int chan) throws IOException, InterruptedException {
        if (chan > 3) {
            return -1;
        }
        //start with default values
        int config = REG_CONFIG_CQUE_NONE             //Disable the comparator (default val)
                | REG_CONFIG_CLAT_NONLAT              //Non-latching (default val)
                | REG_CONFIG_CPOL_ACTVLOW             //Alert/Rdy active low   (default val)
                | REG_CONFIG_CMODE_TRAD               // Traditional comparator (default val)
                | REG_CONFIG_MODE_SINGLE              // Single-shot mode (default)
                | SDR_SELECTION.get(rate);            //1600 samples per second (default)

        //Set PGA/voltage range
        config = config | GAINS.get(gain);

        if (chan == 0)
            config = config | REG_CONFIG_MUX_SINGLE_0;
        else if (chan == 1)
            config = config | REG_CONFIG_MUX_SINGLE_1;
        else if (chan == 2)
            config = config | REG_CONFIG_MUX_SINGLE_2;
        else if (chan == 3)
            config = config | REG_CONFIG_MUX_SINGLE_3;

        //Set 'start single-conversion' bit
        config = config | REG_CONFIG_OS_SINGLE;
        writeRegister(REG_POINTER_CONFIG, config);
        TimeUnit.MILLISECONDS.sleep((long) ((1. / rate + 0.002) * 1000));       //convert to mS to S
        return readRegister(REG_POINTER_CONVERT) * GAIN_SCALING.get(gain);
    }

    private short readADCDifferential(String chan) throws IOException, InterruptedException {
        //start with default values
        int config = REG_CONFIG_CQUE_NONE              //Disable the comparator (default val)
                | REG_CONFIG_CLAT_NONLAT               //Non-latching (default val)
                | REG_CONFIG_CPOL_ACTVLOW              //Alert/Rdy active low   (default val)
                | REG_CONFIG_CMODE_TRAD                // Traditional comparator (default val)
                | REG_CONFIG_MODE_SINGLE               // Single-shot mode (default)
                | SDR_SELECTION.get(rate);             //1600 samples per second (default)

        //Set PGA/voltage range
        config = config | GAINS.get(gain);

        if (chan.equals("01"))
            config = config | REG_CONFIG_MUX_DIFF_0_1;
        else if (chan.equals("23"))
            config = config | REG_CONFIG_MUX_DIFF_2_3;

        //Set 'start single-conversion' bit
        config = config | REG_CONFIG_OS_SINGLE;
        writeRegister(REG_POINTER_CONFIG, config);
        TimeUnit.MILLISECONDS.sleep((long) ((1. / rate + 0.002) * 1000));       //convert to mS to S

        return (short) (readRegister(REG_POINTER_CONVERT) * GAIN_SCALING.get(gain));
    }

    public int getRaw() throws IOException, InterruptedException {
        //return values in mV
        String chan = TYPE_SELECTION.get(channel);
        if (channel.contains("UNI"))
            return (int) readADCSingleEnded(Integer.parseInt(chan));
        else if (channel.contains("DIF"))
            return readADCDifferential(chan);
        return 0;
    }
}
