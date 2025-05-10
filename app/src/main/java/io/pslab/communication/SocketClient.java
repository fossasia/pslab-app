package io.pslab.communication;

import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;

public class SocketClient {

    private static final String TAG = SocketClient.class.getSimpleName();
    private static SocketClient socketClient;
    private Socket socket;
    private OutputStream outputStream;
    private InputStream inputStream;
    private boolean isConnected = false;

    private byte[] receivedData;

    private SocketClient() {
    }

    public void openConnection(String ip, int port) throws IOException {
        socket = new Socket(ip, port);
        outputStream = socket.getOutputStream();
        inputStream = socket.getInputStream();
        if (!socket.isConnected()) {
            isConnected = false;
            return;
        }
        isConnected = true;
        socket.setTcpNoDelay(true);
        socket.setKeepAlive(true);
    }

    public static SocketClient getInstance() {
        if (socketClient == null) {
            socketClient = new SocketClient();
        }
        return socketClient;
    }

    public boolean isConnected() {
        return isConnected;
    }

    public synchronized void write(byte[] data) throws IOException {
        if (isConnected && socketClient.isConnected && outputStream != null) {
            outputStream.write(data);
        }
    }

    public synchronized int read(int bytesToBeRead) throws IOException {
        int numBytesRead = 0;
        int readNow;
        Log.v(TAG, "To read : " + bytesToBeRead);
        int bytesToBeReadTemp = bytesToBeRead;
        receivedData = new byte[bytesToBeRead];
        while (numBytesRead < bytesToBeRead) {
            readNow = inputStream.read(receivedData, numBytesRead, bytesToBeReadTemp);
            if (readNow <= 0) {
                Log.e(TAG, "Read Error: " + bytesToBeReadTemp);
                return numBytesRead;
            } else {
                numBytesRead += readNow;
                bytesToBeReadTemp -= readNow;
            }
        }
        Log.v("Bytes Read", "" + numBytesRead);
        return numBytesRead;
    }

    public byte[] getReceivedData() {
        return receivedData;
    }

    public void closeConnection() {
        try {
            if (isConnected) {
                inputStream.close();
                outputStream.close();
                socket.close();
                isConnected = false;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
