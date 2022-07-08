package id.flutter.plugins;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.UUID;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FlutterBluetoothDevice implements MethodChannel.MethodCallHandler {
    public final String address;
    private final BluetoothAdapter adapter;

    private BluetoothSocket bluetoothSocket;
    private OutputStream writeStream;

    private final MethodChannel deviceChannel;
    private final OnDisconnectCallback disconnectCallback;

    public static interface OnDisconnectCallback {
        void onDisconnected();
    }

    public FlutterBluetoothDevice(BinaryMessenger binaryMessenger, BluetoothAdapter adapter, String address, OnDisconnectCallback disconnectCallback){
        this.disconnectCallback = disconnectCallback;
        this.adapter = adapter;
        this.address = address;

        this.deviceChannel = new MethodChannel(binaryMessenger, "maseka.dev/bluetooth_printer/"+address);
        this.deviceChannel.setMethodCallHandler(this);
    }

    public void connect() throws IOException {
        final BluetoothDevice device = adapter.getRemoteDevice(address);
        UUID uuid = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb");
        bluetoothSocket = device.createRfcommSocketToServiceRecord(uuid);
        bluetoothSocket.connect();
        writeStream = bluetoothSocket.getOutputStream();

        new Handler(Looper.getMainLooper()).post(()->{
            deviceChannel.invokeMethod("onConnected", true);
        });
    }

    public void disconnect() throws IOException {
        synchronized (writeStream) {
            try {
                if (!bluetoothSocket.isConnected()) {
                    return;
                }

                bluetoothSocket.close();

                new Handler(Looper.getMainLooper()).post(() -> {
                    deviceChannel.invokeMethod("onDisconnected", true);
                });
            } finally {
                this.disconnectCallback.onDisconnected();
            }
        }
    }

    public void write(byte[] bytes) throws IOException{
        synchronized (writeStream) {
            if (writeStream == null) return;
            updatePrintingProgress(bytes.length, 0);

            writeStream.write(bytes);
            writeStream.flush();

            updatePrintingProgress(bytes.length, bytes.length);
        }
    }

    private void updatePrintingProgress(long total, long progress){
        new Handler(Looper.getMainLooper()).post(() -> {
            final HashMap<String, Object> map = new HashMap<>();
            map.put("total", total);
            map.put("progress", progress);
            deviceChannel.invokeMethod("onPrintingProgress", map);
        });
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        final String method = call.method;
        switch (method){
            case "write" : {
                AsyncTask.execute(() -> {
                    synchronized (writeStream) {
                        try {
                            final byte[] bytes = (byte[]) call.arguments;
                            write(bytes);
                        } catch (Exception e) {
                            new Handler(Looper.getMainLooper()).post(() -> {
                                result.error("error", e.getMessage(), null);
                            });
                        }
                    }
                });
            }

            case "disconnect": {
                AsyncTask.execute(() -> {
                    synchronized (writeStream) {
                        try {
                            disconnect();
                            result.success(true);
                        } catch (Exception e) {
                            result.error("error", e.getMessage(), null);
                        }
                    }
                });
            }
        }
    }
}
