package io.pslab.communication.sensors;

import org.apache.commons.math3.stat.StatUtils;
import org.apache.commons.math3.util.FastMath;
import io.pslab.communication.ScienceLab;
import io.pslab.communication.peripherals.I2C;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;

/**
 * Created by akarshan on 4/21/17.
 * <p>
 * ScienceLab instance of I2C need to be passed to the MPU6050 constructor.
 * </p>
 */

public class MPU6050 {
    private int GYRO_CONFIG = 0x1B;
    private int ACCEL_CONFIG = 0x1C;
    private double[] GYRO_SCALING = {131, 65.5, 32.8, 16.4};
    private double[] ACCEL_SCALING = {16384, 8192, 4096, 2048};
    private int AR = 3;
    private int GR = 3;
    private int NUMPLOTS = 7;
    public String[] PLOTNAMES = {"Ax", "Ay", "Az,'Temp", "Gx", "Gy", "Gz"};
    private int ADDRESS = 0x69;
    private String name = "Accel/gyro";
    private ArrayList<KalmanFilter> K = new ArrayList<>();          //K is the list of KalmanFilter object
    private I2C i2c;
    private ArrayList<Integer> setGyroRange = new ArrayList<>(Arrays.asList(250, 500, 1000, 2000));
    private ArrayList<Integer> setAccelRange = new ArrayList<>(Arrays.asList(2, 4, 8, 16));
    private ArrayList<Double> kalmanFilter = new ArrayList<>(Arrays.asList(0.01, 0.1, 1.0, 10.0, 100.0, 1000.0, 10000.0, 0.0));

    public MPU6050(I2C i2c, ScienceLab scienceLab) throws IOException {
        this.i2c = i2c;
        if (scienceLab.isConnected()) {
            setGyroRange(2000);
            setAccelerationRange(16);
            powerUp();
        }
    }

    public void kalmanFilter(Double opt) throws IOException, NullPointerException {
        ArrayList<double[]> noise = new ArrayList<>();
        double[] innerNoiseArray = new double[NUMPLOTS];
        ArrayList<Double> vals;
        double standardDeviation;
        if (opt == null) {        //Replaced "OFF" with null.
            K = null;
        }
        for (int a = 0; a < 500; a++) {
            vals = getRaw();
            for (int b = 0; b < NUMPLOTS; b++) {
                innerNoiseArray[b] = vals.get(b);
                noise.set(b, innerNoiseArray);
            }
        }

        for (int a = 0; a < NUMPLOTS; a++) {
            standardDeviation = FastMath.sqrt(StatUtils.variance(noise.get(a)));        //Apachae Commons Maths used to calculate standard deviation
            K.set(a, new KalmanFilter(1. / opt, Math.pow(standardDeviation, 2)));
        }

    }

    private ArrayList<Integer> getVals(int addr, int bytesToRead) throws IOException {
        return i2c.readBulk(ADDRESS, addr, bytesToRead);
    }

    private void powerUp() throws IOException {
        i2c.writeBulk(ADDRESS, new int[]{0x6B, 0});
    }

    public void setGyroRange(int rs) throws IOException {
        GR = setGyroRange.indexOf(rs);
        i2c.writeBulk(ADDRESS, new int[]{GYRO_CONFIG, GR << 3});
    }

    public void setAccelerationRange(int rs) throws IOException {
        AR = setAccelRange.indexOf(rs);
        i2c.writeBulk(ADDRESS, new int[]{ACCEL_CONFIG, AR << 3});
    }

    public ArrayList<Double> getRaw() throws IOException, NullPointerException {
        ArrayList<Integer> vals = getVals(0x3B, 14);
        ArrayList<Double> raw = new ArrayList<>();
        if (vals.size() == 14) {
            int a;
            for (a = 0; a < 3; a++)
                raw.add(a, 1. * (vals.get(a * 2) << 8 | vals.get(a * 2 + 1)) / ACCEL_SCALING[AR]);
            raw.add(a, 1. * (vals.get(6) << 8 | vals.get(7)) / 340. + 36.53);
            for (a = 4; a < 7; a++)
                raw.add(a, (vals.get(a * 2) << 8 | vals.get(a * 2 + 1)) / GYRO_SCALING[GR]);
            if (K.isEmpty())
                return raw;
            else {
                for (int b = 0; b < NUMPLOTS; b++) {
                    K.get(b).inputLatestNoisyMeasurement(raw.get(b));
                    raw.set(b, K.get(b).getLatestEstimatedMeasurement());
                }
                return raw;
            }
        }
        return null;
    }

    public double[] getAcceleration() throws IOException {
        ArrayList<Integer> vals = getVals(0x3B, 6);
        int ax = vals.get(0) << 8 | vals.get(1);
        int ay = vals.get(2) << 8 | vals.get(3);
        int az = vals.get(4) << 8 | vals.get(5);
        return new double[]{ax / 65535., ay / 65535., az / 65535.};

    }

    public double getTemperature() throws IOException {
        ArrayList<Integer> vals = getVals(0x41, 6);
        int t = vals.get(0) << 8 | vals.get(1);
        return t / 65535.;
    }

    public double[] getGyroscope() throws IOException {
        ArrayList<Integer> vals = getVals(0x43, 6);
        int ax = vals.get(0) << 8 | vals.get(1);
        int ay = vals.get(2) << 8 | vals.get(3);
        int az = vals.get(4) << 8 | vals.get(5);
        return new double[]{ax / 65535., ay / 65535., az / 65535.};

    }

}
