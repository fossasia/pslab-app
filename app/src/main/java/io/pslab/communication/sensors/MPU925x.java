package io.pslab.communication.sensors;

import org.apache.commons.math3.stat.StatUtils;
import org.apache.commons.math3.util.FastMath;
import io.pslab.communication.peripherals.I2C;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;

/**
 * Created by akarshan on 5/7/17.
 * <p>
 * ScienceLab instance of i2c is needed to be passed to MPU95x constructor.
 * </p>
 */


public class MPU925x {
    private static final String TAG = "MPU925x";
    private int INT_PIN_CFG = 0x37;
    private int GYRO_CONFIG = 0x1B;
    private int ACCEL_CONFIG = 0x1C;
    private double[] GYRO_SCALING = new double[]{131, 65.5, 32.8, 16.4};
    private int[] ACCEL_SCALING = new int[]{16384, 8192, 4096, 2048};
    private int AR = 3;
    private int GR = 3;
    private int NUMPLOTS = 7;
    public String[] PLOTNAMES = new String[]{"Ax", "Ay", "Az", "Temp", "Gx", "Gy", "Gz"};
    private int ADDRESS = 0x69;
    private int AK8963_ADDRESS = 0x0C;
    private int AK8963_CNTL = 0x0A;
    public String name = "Accel/gyro";

    private I2C i2c;
    private ArrayList<KalmanFilter> kalman = new ArrayList<>();
    private ArrayList<Integer> gyroRange = new ArrayList<>(Arrays.asList(250, 500, 1000, 2000));
    private ArrayList<Integer> accelRange = new ArrayList<>(Arrays.asList(2, 4, 8, 16));
    private double[] kalmanFilter = new double[]{.01, .1, 1, 10, 100, 1000, 10000, 0};       //Replaced "OFF" with 0.

    public MPU925x(I2C i2c) throws IOException {
        this.i2c = i2c;
        setGyroRange(2000);
        setAccelRange(16);
        powerUp();
        kalman = null;
    }

    public void KalmanFilter(Double opt) throws IOException, NullPointerException {
        ArrayList<double[]> noise = new ArrayList<>();
        double[] innerNoiseArray = new double[NUMPLOTS];
        ArrayList<Double> vals;
        double standardDeviation;
        if (opt == 0) {        //Replaced "OFF" with 0.
            kalman = null;
        }
        for (int a = 0; a < 500; a++) {
            vals = getRaw();
            for (int b = 0; b < NUMPLOTS; b++) {
                innerNoiseArray[b] = vals.get(b);
                noise.set(b, innerNoiseArray);
            }
        }
        for (int a = 0; a < NUMPLOTS; a++) {
            standardDeviation = FastMath.sqrt(StatUtils.variance(noise.get(a)));
            kalman.set(a, new KalmanFilter(1. / opt, Math.pow(standardDeviation, 2)));
        }
    }

    private ArrayList<Integer> getVals(int addr, int bytestoread) throws IOException {
        return i2c.readBulk(ADDRESS, addr, bytestoread);
    }

    private void powerUp() throws IOException {
        i2c.writeBulk(ADDRESS, new int[]{0x6B, 0});
    }

    public void setGyroRange(int rs) throws IOException {
        GR = gyroRange.indexOf(rs);
        i2c.writeBulk(ADDRESS, new int[]{GYRO_CONFIG, GR << 3});
    }

    public void setAccelRange(int rs) throws IOException {
        AR = accelRange.indexOf(rs);
        i2c.writeBulk(ADDRESS, new int[]{ACCEL_CONFIG, AR << 3});
    }

    public ArrayList<Double> getRaw() throws IOException, NullPointerException {
        ArrayList<Integer> vals = getVals(0x3B, 14);
        ArrayList<Double> raw = new ArrayList<>();
        if (vals.size() == 14) {
            for (int a = 0; a < 3; a++)
                raw.set(a, 1. * (vals.get(a * 2) << 8 | vals.get(a * 2 + 1)) / ACCEL_SCALING[AR]);
            for (int a = 4; a < 7; a++)
                raw.set(a, (vals.get(a * 2) << 8 | vals.get(a * 2 + 1)) / GYRO_SCALING[GR]);
            raw.set(3, 1. * (vals.get(6) << 8 | vals.get(7)) / 340. + 36.53);
            if (kalman.isEmpty())
                return raw;
            else {
                for (int b = 0; b < NUMPLOTS; b++) {
                    kalman.get(b).inputLatestNoisyMeasurement(raw.get(b));
                    raw.set(b, kalman.get(b).getLatestEstimatedMeasurement());
                }
                return raw;
            }
        }
        return null;
    }

    public double[] getAcceleration() throws IOException {
        //Return a list of 3 values for acceleration vector
        ArrayList<Integer> vals = getVals(0x3B, 6);
        int ax = vals.get(0) << 8 | vals.get(1);
        int ay = vals.get(2) << 8 | vals.get(3);
        int az = vals.get(4) << 8 | vals.get(5);
        return new double[]{ax / 65535., ay / 65535., az / 65535.};
    }

    public double getTemperature() throws IOException {
        //Return temperature
        ArrayList<Integer> vals = getVals(0x41, 6);
        int t = vals.get(0) << 8 | vals.get(1);
        return t / 65535.;
    }

    public double[] getGyroscope() throws IOException {
        //Return a list of 3 values for angular velocity vector
        ArrayList<Integer> vals = getVals(0x43, 6);
        int ax = vals.get(0) << 8 | vals.get(1);
        int ay = vals.get(2) << 8 | vals.get(3);
        int az = vals.get(4) << 8 | vals.get(5);
        return new double[]{ax / 65535., ay / 65535., az / 65535.};

    }

    public double[] getMagneticField() throws IOException {
        //Return a list of 3 values for magnetic field vector
        ArrayList<Integer> vals = i2c.readBulk(AK8963_ADDRESS, 0X03, 7);
        int ax = vals.get(0) << 8 | vals.get(1);
        int ay = vals.get(2) << 8 | vals.get(3);
        int az = vals.get(4) << 8 | vals.get(5);
        if ((vals.get(6) & 0x08) != 0) {
            return new double[]{ax / 65535., ay / 65535., az / 65535.};
        } else
            return null;
    }

    public String whoAmI() throws IOException {
        /*
            Returns the ID .
            It is 71 for MPU9250 .
        */
        int v = i2c.readBulk(ADDRESS, 0x75, 1).get(0);
        if (v != 0x71 && v != 0x73)
            return "Error " + Integer.toHexString(v);
        if (v == 0x73)
            return "MPU9255 " + Integer.toHexString(v);
        else if (v == 0x71)
            return "MPU9250 " + Integer.toHexString(v);
        else
            return null;
    }

    public String whoAmIAK8963() throws IOException {
        /*
            Returns the ID fo magnetometer AK8963 if found.
            It should be 0x48.
        */
        initMagnetometer();
        int v = i2c.readBulk(AK8963_ADDRESS, 0, 1).get(0);
        if (v == 0x48)
            return "AK8963 " + Integer.toHexString(v);
        else
            return "AK8963 not found. returned " + Integer.toHexString(v);
    }

    private void initMagnetometer() throws IOException {
        /*
            For MPU925x with integrated magnetometer.
            It's called a 10 DoF sensor, but technically speaking ,
            the 3-axis Accel , 3-Axis Gyro, temperature sensor are integrated in one IC,
            and the 3-axis magnetometer is implemented in a
            separate IC which can be accessed via an I2C passthrough.
            Therefore , in order to detect the magnetometer via an I2C scan,
            the passthrough must first be enabled on IC#1 (Accel,gyro,temp)
        */
        i2c.writeBulk(ADDRESS, new int[]{INT_PIN_CFG, 0x22});                   //I2C passthrough
        i2c.writeBulk(AK8963_ADDRESS, new int[]{AK8963_CNTL, 0});                //power down mag
        i2c.writeBulk(AK8963_ADDRESS, new int[]{AK8963_CNTL, (1 << 4) | 6});    //mode  (0 = 14bits, 1 = 16bits) << 4 | (2 = 8Hz, 6 = 100Hz)
    }

}


