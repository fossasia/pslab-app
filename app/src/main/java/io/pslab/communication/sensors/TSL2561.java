package io.pslab.communication.sensors;

import android.util.Log;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.TimeUnit;

import io.pslab.communication.ScienceLab;
import io.pslab.communication.peripherals.I2C;

/*
 * See https://www.digikey.in/htmldatasheets/production/1640693/0/0/1/tsl2560-tsl2561-datasheet.html
 */
public class TSL2561 {
    private static final String TAG = TSL2561.class.getSimpleName();

    /* See https://github.com/adafruit/TSL2561-Arduino-Library/blob/master/TSL2561.h for all constants. */

    private static final byte COMMAND_BIT = (byte) 0x80; // Must be 1
    private static final byte WORD_BIT = (0x20);         // 1 = read/write word (rather than byte)

    private static final byte CONTROL_POWERON = 0x03;
    private static final byte CONTROL_POWEROFF = 0x00;

    private static final byte REGISTER_CONTROL = 0x00;
    private static final byte REGISTER_TIMING = 0x01;
    private static final byte REGISTER_ID = 0x0A;
    private static final byte REGISTER_CHAN0_LOW = 0x0C;
    private static final byte REGISTER_CHAN1_LOW = 0x0E;

    private static final byte INTEGRATIONTIME_13MS = 0x00;  // 13.7ms
    private static final byte INTEGRATIONTIME_101MS = 0x01;  // 101ms
    private static final byte INTEGRATIONTIME_402MS = 0x02;  // 402ms

    private static final byte GAIN_0X = 0x00;     // No gain
    private static final byte GAIN_16X = 0x10;    // 16x gain

    /**
     * Normal address is 0x39, but it may also be configured to 0x29 or 0x49.
     * We use the normal address first before querying the alternatives.
     */
    private static final byte[] ADDRESSES = new byte[]{0x39, 0x29, 0x49};
    private byte address;
    private byte timing = INTEGRATIONTIME_13MS;
    private byte gain = GAIN_16X;

    private final I2C i2c;

    public TSL2561(I2C i2c, ScienceLab scienceLab) throws IOException, InterruptedException {
        this.i2c = i2c;
        // set timing 101ms & 16x gain
        if (scienceLab.isConnected()) {

            /* Here we probe if any of the expected I2C addresses has an ID in the expected format.
             * If no sensor is available with the given ID, the value 0xFFFFFFFF will be returned.
             * If a different value is returned, we can check for the expected value (see data sheet
             * for details).
             */
            for (byte addr : ADDRESSES) {
                address = addr;
                /* We disable the sensor before probing since it will not return the expected value
                 * if it is still active due to a previous data capture.
                 */
                disable();
                Log.d(TAG, "Checking address 0x" + Integer.toHexString(address));
                int id = i2c.readByte(address, REGISTER_ID);
                if (id != 0xffffffff && (id & 0x0A) == 0x0A) {
                    Log.d(TAG, "TSL2561 found!");
                    break;
                } else {
                    Log.d(TAG, "TSL2561 not found.");
                }
            }

            enable();
            _wait();
            i2c.writeBulk(address, new int[]{COMMAND_BIT | REGISTER_TIMING, timing | gain});
        }
    }

    public int getID() throws IOException {
        List<Integer> _ID_ = i2c.readBulk(address, REGISTER_ID, 1);
        int ID = Integer.parseInt(Character.getNumericValue(_ID_.get(0)) + "", 16);
        Log.d(TAG, "ID: " + ID);
        return ID;
    }

    public int[] getRaw() throws IOException {
        List<Integer> infraList = i2c.readBulk(address, COMMAND_BIT | WORD_BIT | REGISTER_CHAN1_LOW, 2);
        List<Integer> fullList = i2c.readBulk(address, COMMAND_BIT | WORD_BIT | REGISTER_CHAN0_LOW, 2);
        if (!infraList.isEmpty()) {
            int full = ((fullList.get(1) & 0xff) << 8) | fullList.get(0) & 0xff;
            int infra = ((infraList.get(1) & 0xff) << 8) | infraList.get(0) & 0xff;
            return (new int[]{full, infra, full - infra});
        } else
            return null;
    }

    public void setGain(String gain) throws IOException {
        if (gain.equals("1x"))
            this.gain = GAIN_0X;

        else if (gain.equals("16x"))
            this.gain = GAIN_16X;

        i2c.writeBulk(address, new int[]{COMMAND_BIT | REGISTER_TIMING, this.gain | timing});
    }

    private void enable() throws IOException {
        i2c.writeBulk(address, new int[]{COMMAND_BIT | REGISTER_CONTROL, CONTROL_POWERON});
    }

    public void disable() throws IOException {
        i2c.writeBulk(address, new int[]{COMMAND_BIT | REGISTER_CONTROL, CONTROL_POWEROFF});
    }

    private void _wait() throws InterruptedException {
        switch (timing) {
            case INTEGRATIONTIME_13MS: {
                TimeUnit.MILLISECONDS.sleep(14);
                break;
            }
            case INTEGRATIONTIME_101MS: {
                TimeUnit.MILLISECONDS.sleep(102);
                break;
            }
            case INTEGRATIONTIME_402MS:
            default: {
                TimeUnit.MILLISECONDS.sleep(403);
            }
        }
    }

}
