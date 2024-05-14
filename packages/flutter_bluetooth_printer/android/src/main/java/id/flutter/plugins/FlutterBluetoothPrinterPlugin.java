package id.flutter.plugins;

import static android.os.Build.VERSION.SDK_INT;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

public class FlutterBluetoothPrinterPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.RequestPermissionsResultListener, EventChannel.StreamHandler {
    private final Map<Object, EventChannel.EventSink> sinkList = new HashMap<>();
    private final BroadcastReceiver discoveryReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                final Map<String, Object> map = deviceToMap(device);

                for (EventChannel.EventSink sink : sinkList.values()) {
                    sink.success(map);
                }
            }
        }
    };
    private MethodChannel channel;
    private Activity activity;
    private BluetoothAdapter bluetoothAdapter;
    private final BroadcastReceiver stateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
                final int value = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.STATE_OFF);
                if (value == BluetoothAdapter.STATE_OFF) {
                    Map<String, Object> data = new HashMap<>();
                    data.put("code", 1);
                    for (EventChannel.EventSink sink : sinkList.values()) {
                        sink.success(data);
                    }
                } else if (value == BluetoothAdapter.STATE_ON) {
                    startDiscovery(false);
                }
            }
        }
    };
    private FlutterPluginBinding flutterPluginBinding;
    private final Map<String, BluetoothSocket> connectedDevices = new HashMap<>();
    private Handler mainThread;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding;
        this.mainThread = new Handler(Looper.getMainLooper());

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            BluetoothManager bluetoothManager = flutterPluginBinding.getApplicationContext().getSystemService(BluetoothManager.class);
            bluetoothAdapter = bluetoothManager.getAdapter();
        } else {
            bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        }


        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "maseka.dev/flutter_bluetooth_printer");
        channel.setMethodCallHandler(this);

        EventChannel discoveryChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "maseka.dev/flutter_bluetooth_printer/discovery");
        discoveryChannel.setStreamHandler(this);

        IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
        flutterPluginBinding.getApplicationContext().registerReceiver(discoveryReceiver, filter);

        IntentFilter stateFilter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
        flutterPluginBinding.getApplicationContext().registerReceiver(stateReceiver, stateFilter);
    }

    private Map<String, Object> deviceToMap(BluetoothDevice device) {
        final HashMap<String, Object> map = new HashMap<>();
        map.put("code", 4);
        map.put("name", device.getName());
        map.put("address", device.getAddress());
        map.put("type", device.getType());
        return map;
    }

    private boolean ensurePermission(boolean request) {
        if (SDK_INT >= Build.VERSION_CODES.M) {
            if (SDK_INT >= 31) {
                final boolean bluetooth = activity.checkSelfPermission(Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED;
                final boolean bluetoothScan = activity.checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED;
                final boolean bluetoothConnect = activity.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED;

                if (bluetooth && bluetoothScan && bluetoothConnect) {
                    return true;
                }

                if (!request) return false;
                activity.requestPermissions(new String[]{Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN, Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT}, 919191);
            } else {
                if(activity == null){
                    return false;
                }

                boolean bluetooth = activity.checkSelfPermission(Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED;
                boolean fineLocation = activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
                boolean coarseLocation = activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;

                if (bluetooth && (fineLocation || coarseLocation)) {
                    return true;
                }

                if (!request) return false;
                activity.requestPermissions(new String[]{Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN, Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION}, 919191);
            }

            return false;
        }

        return true;
    }

    private void startDiscovery(boolean requestPermission) {
        if (!ensurePermission(requestPermission)) {
            return;
        }

        // immediately return bonded devices
        Set<BluetoothDevice> bonded = bluetoothAdapter.getBondedDevices();
        for (BluetoothDevice device : bonded) {
            final Map<String, Object> map = deviceToMap(device);
            for (EventChannel.EventSink sink : sinkList.values()) {
                sink.success(map);
            }
        }


        if (bluetoothAdapter.isDiscovering()) {
            bluetoothAdapter.cancelDiscovery();
        }

        bluetoothAdapter.startDiscovery();
    }

    private void stopDiscovery() {
        if (bluetoothAdapter.isDiscovering()) {
            bluetoothAdapter.cancelDiscovery();
        }
    }

    private void updatePrintingProgress(int total, int progress) {
        mainThread.post(() -> {
            Map<String, Object> data = new HashMap<>();
            data.put("total", total);
            data.put("progress", progress);

            channel.invokeMethod("onPrintingProgress", data);
        });
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        final String method = call.method;
        switch (method) {
            case "connect": {
                new Thread(() -> {
                    synchronized (FlutterBluetoothPrinterPlugin.this) {
                        try {
                            String address = call.argument("address");
                            BluetoothSocket bluetoothSocket = connectedDevices.get(address);
                            if (bluetoothSocket == null) {
                                final BluetoothDevice device = bluetoothAdapter.getRemoteDevice(address);
                                UUID uuid = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb");
                                bluetoothSocket = device.createRfcommSocketToServiceRecord(uuid);
                                bluetoothSocket.connect();
                                connectedDevices.put(address, bluetoothSocket);
                            }

                            mainThread.post(() -> {
                                // DONE
                                result.success(true);
                            });
                        } catch (Exception e) {
                            mainThread.post(() -> {
                                result.error("error", e.getMessage(), null);
                            });
                        }
                    }
                }).start();
                return;
            }
            case "getState": {
                if (!ensurePermission(false)) {
                    result.success(3);
                    return;
                }

                if (!bluetoothAdapter.isEnabled()) {
                    result.success(1);
                    return;
                }

                final int state = bluetoothAdapter.getState();
                if (state == BluetoothAdapter.STATE_OFF) {
                    result.success(1);
                    return;
                }

                if (state == BluetoothAdapter.STATE_ON) {
                    result.success(2);
                    return;
                }
                return;
            }

            case "disconnect": {
                new Thread(() -> {
                    synchronized (FlutterBluetoothPrinterPlugin.this) {
                        try {
                            String address = call.argument("address");
                            BluetoothSocket socket = connectedDevices.remove(address);
                            if (socket != null) {
                                OutputStream out = socket.getOutputStream();
                                out.flush();
                                out.close();
                                socket.close();
                            }

                            mainThread.post(() -> {
                                result.success(true);
                            });
                        } catch (Exception e) {
                            mainThread.post(() -> {
                                result.error("error", e.getMessage(), null);
                            });
                        }
                    }
                }).start();
                return;
            }

            case "write": {
                // CONNECTING
                channel.invokeMethod("didUpdateState", 1);
                new Thread(() -> {
                    synchronized (FlutterBluetoothPrinterPlugin.this) {
                        try {
                            String address = call.argument("address");
                            boolean keepConnected = call.argument("keep_connected");
                            byte[] data = call.argument("data");

                            BluetoothSocket bluetoothSocket = connectedDevices.get(address);
                            if (bluetoothSocket == null) {
                                final BluetoothDevice device = bluetoothAdapter.getRemoteDevice(address);
                                UUID uuid = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb");
                                bluetoothSocket = device.createRfcommSocketToServiceRecord(uuid);
                                bluetoothSocket.connect();
                            }

                            try {
                                if (keepConnected && !connectedDevices.containsKey(address)) {
                                    connectedDevices.put(address, bluetoothSocket);
                                }

                                InputStream inputStream = bluetoothSocket.getInputStream();
                                OutputStream writeStream = bluetoothSocket.getOutputStream();

                                // PRINTING
                                mainThread.post(() -> channel.invokeMethod("didUpdateState", 2));
                                assert data != null;

                                updatePrintingProgress(data.length, 0);

                                // req get printer status
                                writeStream.write(data);
                                writeStream.flush();

                                updatePrintingProgress(data.length, data.length);

                                if (!keepConnected) {
                                    inputStream.close();
                                    writeStream.close();
                                }

                                mainThread.post(() -> {
                                    // COMPLETED
                                    channel.invokeMethod("didUpdateState", 3);

                                    // DONE
                                    result.success(true);
                                });
                            } finally {
                                if (!keepConnected) {
                                    bluetoothSocket.close();
                                    connectedDevices.remove(address);
                                }
                            }
                        } catch (Exception e) {
                            mainThread.post(() -> {
                                result.error("error", e.getMessage(), null);
                            });
                        }
                    }
                }).start();
                return;
            }

            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        flutterPluginBinding.getApplicationContext().unregisterReceiver(discoveryReceiver);
        flutterPluginBinding.getApplicationContext().unregisterReceiver(stateReceiver);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addRequestPermissionsResultListener(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == 919191) {
            for (final int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    Map<String, Object> data = new HashMap<>();
                    data.put("code", 3);

                    for (EventChannel.EventSink sink : sinkList.values()) {
                        sink.success(data);
                    }

                    return true;
                }
            }

            if (!bluetoothAdapter.isEnabled()) {
                Map<String, Object> data = new HashMap<>();
                data.put("code", 1);

                for (EventChannel.EventSink sink : sinkList.values()) {
                    sink.success(data);
                }
                return true;
            }

            final int state = bluetoothAdapter.getState();
            if (state == BluetoothAdapter.STATE_OFF) {
                Map<String, Object> data = new HashMap<>();
                data.put("code", 1);

                for (EventChannel.EventSink sink : sinkList.values()) {
                    sink.success(data);
                }
                return true;
            }

            startDiscovery(false);
            return true;
        }

        return false;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        sinkList.put(arguments, events);
        startDiscovery(true);
    }

    @Override
    public void onCancel(Object arguments) {
        sinkList.remove(arguments);
        if (sinkList.isEmpty()) {
            stopDiscovery();
        }
    }
}
