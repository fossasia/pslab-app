package io.pslab.communication.sensors;

import android.util.Log;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.TimeUnit;

import io.pslab.communication.ScienceLab;
import io.pslab.communication.peripherals.I2C;

/**
 * Implementation of communication with SHT21 temperature / humidity sensor.
 * <p>
 * See <a href="https://sensirion.com/media/documents/120BBE4C/63500094/Sensirion_Datasheet_Humidity_Sensor_SHT21.pdf">
 * Datasheet SHT21</a> for the calculations for temperature and humidity.
 * <p>
 * Example code for CRC calculation can be found in the ZIP file
 * <a href="https://sensirion.com/resource/software/code/sht21">Sample code SHT21</a>
 */
public class SHT21 {

    public enum Mode {
        TEMPERATURE(TEMP_ADDRESS), HUMIDITY(HUMIDITY_ADDRESS);

        final int registerAddress;

        Mode(int registerAddress) {
            this.registerAddress = registerAddress;
        }
    }

    private static final String TAG = SHT21.class.getSimpleName();
    private static final int RESET = 0XFE;
    private static final int TEMP_ADDRESS = 0xE3;
    private static final int HUMIDITY_ADDRESS = 0xE5;
    private static final int ADDRESS = 0x40;

    private Mode selected = Mode.TEMPERATURE;

    private final I2C i2c;

    public SHT21(I2C i2c, ScienceLab scienceLab) throws IOException, InterruptedException {
        this.i2c = i2c;
        if (scienceLab.isConnected()) {
            init();
        }
    }

    private void init() throws IOException, InterruptedException {
        i2c.writeBulk(ADDRESS, new int[]{RESET});   //soft reset
        TimeUnit.MILLISECONDS.sleep(100);
    }

    private static Double rawToTemp(List<Integer> vals) {
        if (vals.size() >= 2) {
            double v = ((vals.get(0) & 0xFF) << 8) | (vals.get(1) & 0xFC);
            return -46.85 + 175.72 * (v / (1 << 16));
        } else return null;
    }

    private static Double rawToRH(List<Integer> vals) {
        if (vals.size() >= 2) {
            double v = ((vals.get(0) & 0xFF) << 8) | (vals.get(1) & 0xFC);
            return -6 + 125 * (v / (1 << 16));
        } else return null;
    }

    private static int calculateChecksum(List<Integer> data, int numberOfBytes) {

        //CRC
        final int POLYNOMIAL = 0x31;
        int crc = 0;
        //calculates 8-Bit checksum with given polynomial
        for (int byteCtr = 0; byteCtr < numberOfBytes; byteCtr++) {
            crc ^= data.get(byteCtr);
            for (int bit = 8; bit > 0; bit--) {
                if ((crc & 0X80) != 0)
                    crc = (crc << 1) ^ POLYNOMIAL;
                else
                    crc = crc << 1;
            }
        }
        return crc;
    }

    public void setMode(Mode mode) {
        selected = mode;
    }

    public Double getRaw() throws IOException, InterruptedException {
        List<Integer> vals;
        i2c.writeBulk(ADDRESS, new int[]{selected.registerAddress});
        if (selected == Mode.TEMPERATURE)
            TimeUnit.MILLISECONDS.sleep(100);
        else if (selected == Mode.HUMIDITY)
            TimeUnit.MILLISECONDS.sleep(50);
        vals = i2c.readBulk(ADDRESS, selected.registerAddress, 3);
        if (vals.isEmpty()) {
            Log.v(TAG, "No data received.");
            return null;
        } else if ((calculateChecksum(vals, 2) & 0xFF) != (vals.get(2) & 0xFF)) {
            Log.v(TAG, "Error in checksum.");
            return null;
        }

        if (selected == Mode.TEMPERATURE)
            return rawToTemp(vals);
        else if (selected == Mode.HUMIDITY)
            return rawToRH(vals);
        else
            return null;
    }

}
