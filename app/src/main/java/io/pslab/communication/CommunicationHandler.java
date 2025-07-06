package io.pslab.communication;

import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbManager;
import android.util.Log;

import com.hoho.android.usbserial.driver.CdcAcmSerialDriver;
import com.hoho.android.usbserial.driver.Cp21xxSerialDriver;
import com.hoho.android.usbserial.driver.ProbeTable;
import com.hoho.android.usbserial.driver.UsbSerialDriver;
import com.hoho.android.usbserial.driver.UsbSerialPort;
import com.hoho.android.usbserial.driver.UsbSerialProber;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

public class CommunicationHandler {
    private final String TAG = this.getClass().getSimpleName();
    private static final int PSLAB_VENDOR_ID_V5 = 1240;
    private static final int PSLAB_PRODUCT_ID_V5 = 223;
    private static final int PSLAB_VENDOR_ID_V6 = 0x10C4;
    private static final int PSLAB_PRODUCT_ID_V6 = 0xEA60;
    public static int PSLAB_VERSION;
    private boolean connected = false, device_found = false;
    private UsbManager mUsbManager;
    private UsbDeviceConnection mConnection;
    private UsbSerialDriver driver;
    private UsbSerialPort port;
    public UsbDevice mUsbDevice;

    public static final int DEFAULT_READ_BUFFER_SIZE = 32 * 1024;

    private byte[] mReadBuffer;

    public CommunicationHandler(UsbManager usbManager) {
        this.mUsbManager = usbManager;
        mUsbDevice = null;
        ProbeTable customTable = new ProbeTable();
        customTable.addProduct(PSLAB_VENDOR_ID_V5, PSLAB_PRODUCT_ID_V5, CdcAcmSerialDriver.class);
        customTable.addProduct(PSLAB_VENDOR_ID_V6, PSLAB_PRODUCT_ID_V6, Cp21xxSerialDriver.class);

        UsbSerialProber prober = new UsbSerialProber(customTable);
        List<UsbSerialDriver> drivers = prober.findAllDrivers(usbManager);

        if (drivers.isEmpty()) {
            Log.d(TAG, "No drivers found");
        } else {
            Log.d(TAG, "Found PSLab device");
            device_found = true;
            driver = drivers.get(0);
            mUsbDevice = driver.getDevice();
        }
        mReadBuffer = new byte[DEFAULT_READ_BUFFER_SIZE];
    }

    public void open(int baudRate) throws IOException {
        if (!device_found) {
            throw new IOException("Device not Connected");
        }
        mConnection = mUsbManager.openDevice(mUsbDevice);
        if (mConnection == null) {
            throw new IOException("Could not open device.");
        }
        if (mUsbDevice.getProductId() == PSLAB_PRODUCT_ID_V6 && mUsbDevice.getVendorId() == PSLAB_VENDOR_ID_V6) {
            PSLAB_VERSION = 6;
        } else {
            PSLAB_VERSION = 5;
        }
        connected = true;
        port = driver.getPorts().get(0);
        port.open(mConnection);
        port.setParameters(baudRate, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE);
        clear();
    }

    public boolean isDeviceFound() {
        return device_found;
    }

    public boolean isConnected() {
        return connected;
    }

    public void close() throws IOException {
        if (mConnection == null) {
            return;
        }
        port.close();
        connected = false;
    }

    public int read(byte[] dest, int bytesToBeRead, int timeoutMillis) throws IOException {
        if (PSLAB_VERSION == 5) {
            return readCdcAcm(dest, bytesToBeRead, timeoutMillis);
        }
        int numBytesRead = 0;
        int readNow;
        Log.v(TAG, "To read : " + bytesToBeRead);
        int bytesToBeReadTemp = bytesToBeRead;
        while (numBytesRead < bytesToBeRead) {
            readNow = port.read(mReadBuffer, bytesToBeReadTemp, timeoutMillis);
            if (readNow == 0) {
                Log.e(TAG, Arrays.toString(Thread.currentThread().getStackTrace()));
                Log.e(TAG, "Read Error: " + bytesToBeReadTemp);
                return numBytesRead;
            } else {
                System.arraycopy(mReadBuffer, 0, dest, numBytesRead, readNow);
                numBytesRead += readNow;
                bytesToBeReadTemp -= readNow;
            }
        }
        Log.v(TAG, "Bytes Read: " + numBytesRead);
        return numBytesRead;
    }

    public int readCdcAcm(byte[] dest, int bytesToBeRead, int timeoutMillis) throws IOException {
        int numBytesRead = 0;
        int readNow;
        Log.v(TAG, "To read : " + bytesToBeRead);
        int bytesToBeReadTemp = bytesToBeRead;
        while (numBytesRead < bytesToBeRead) {
            readNow = mConnection.bulkTransfer(mUsbDevice.getInterface(1).getEndpoint(1), mReadBuffer, bytesToBeReadTemp, timeoutMillis);
            if (readNow < 0) {
                Log.e(TAG, "Read Error: " + bytesToBeReadTemp);
                return numBytesRead;
            } else {
                System.arraycopy(mReadBuffer, 0, dest, numBytesRead, readNow);
                numBytesRead += readNow;
                bytesToBeReadTemp -= readNow;
            }
        }
        Log.v(TAG, "Bytes Read: " + numBytesRead);
        return numBytesRead;
    }

    public void write(byte[] src, int timeoutMillis) throws IOException {
        int writeLength;
        writeLength = src.length;
        port.write(src, writeLength, timeoutMillis);
    }

    private void clear() throws IOException {
        port.read(mReadBuffer, 100, 50);
    }
}
