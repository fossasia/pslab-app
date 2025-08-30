package io.pslab.communication.sensors;


import android.util.Log;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import io.pslab.communication.peripherals.I2C;

public class MLX90614 {
    private static final String TAG = MLX90614.class.getSimpleName();

    private static final int ADDRESS = 0x5A;
    private static final int OBJ_TEMP_REGISTER = 0x07;
    private static final int AMB_TEMP_REGISTER = 0x06;

    private final I2C i2c;

    public MLX90614(I2C i2c) throws IOException {
        this.i2c = i2c;

        try {
            Log.d(TAG, "switching baud to 100k");
            i2c.config((int) 100e3);
        } catch (Exception e) {
            Log.d(TAG, "failed to change baud rate");
        }
    }

    private ArrayList<Integer> getVals(int register, int bytes) throws IOException {
        return i2c.readBulk(ADDRESS, register, bytes);
    }

    private Double getRaw(int register) throws IOException {
        List<Integer> vals = getVals(register, 3);
        if (vals.size() == 4)
            return ((((vals.get(1) & 0x007f) << 8) + vals.get(0)) * 0.02) - 0.01 - 273.15;
        else
            return null;
    }

    public Double getObjectTemperature() throws IOException {
        return getRaw(OBJ_TEMP_REGISTER);

    }

    public Double getAmbientTemperature() throws IOException {
        return getRaw(AMB_TEMP_REGISTER);

    }

}
