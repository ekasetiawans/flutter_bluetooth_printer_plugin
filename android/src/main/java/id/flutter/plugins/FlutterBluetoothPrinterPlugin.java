package id.flutter.plugins;

import static android.os.Build.VERSION.SDK_INT;

import android.Manifest;
import android.app.Activity;
import android.app.AsyncNotedAppOp;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.List;
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
    private MethodChannel channel;
    private Activity activity;
    private BluetoothAdapter bluetoothAdapter;
    private final Map<String, FlutterBluetoothDevice> connectedDevices = new HashMap<>();
    private FlutterPluginBinding flutterPluginBinding;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding;
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "maseka.dev/bluetooth_printer");
        channel.setMethodCallHandler(this);

        EventChannel discoveryChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "maseka.dev/bluetooth_printer/discovery");
        discoveryChannel.setStreamHandler(this);

        IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
        flutterPluginBinding.getApplicationContext().registerReceiver(receiver, filter);
    }

    private final BroadcastReceiver receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                final Map<String, Object> map = deviceToMap(device);

                for (EventChannel.EventSink sink :  sinkList.values()) {
                    sink.success(map);
                }
            }
        }
    };

    private Map<String, Object> deviceToMap(BluetoothDevice device) {
        final HashMap<String, Object> map = new HashMap<>();
        map.put("name", device.getName());
        map.put("address", device.getAddress());
        map.put("type", device.getType());
        map.put("is_connected", connectedDevices.containsKey(device.getAddress()));
        return map;
    }

    private boolean ensurePermission(){
        if (SDK_INT >= Build.VERSION_CODES.M) {
            boolean bluetooth = activity.checkSelfPermission(Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED;
            boolean bluetoothScan = activity.checkSelfPermission("android.permission.BLUETOOTH_SCAN") == PackageManager.PERMISSION_GRANTED;
            boolean bluetoothConnect = activity.checkSelfPermission("android.permission.BLUETOOTH_CONNECT") == PackageManager.PERMISSION_GRANTED;
            if (bluetooth && bluetoothScan && bluetoothConnect){
                return true;
            }

            activity.requestPermissions(new String[]{Manifest.permission.BLUETOOTH, "android.permission.BLUETOOTH_SCAN", "android.permission.BLUETOOTH_CONNECT"}, 919191);
            return false;
        }

        return true;
    }

    private void startDiscovery(){
        if (!ensurePermission()){
            return;
        }

        if (!bluetoothAdapter.isDiscovering()){
            bluetoothAdapter.startDiscovery();
        }

        Set<BluetoothDevice> bonded = bluetoothAdapter.getBondedDevices();
        for (BluetoothDevice device : bonded) {
            final Map<String, Object> map = deviceToMap(device);
            for (EventChannel.EventSink sink :  sinkList.values()) {
                sink.success(map);
            }
        }
    }

    private void stopDiscovery(){
        if (bluetoothAdapter.isDiscovering()) {
            bluetoothAdapter.cancelDiscovery();
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        final String method = call.method;
        switch (method) {
            case "connect": {
                AsyncTask.execute(() -> {
                    synchronized (connectedDevices) {
                        try {
                            String address = (String) call.arguments;
                            if (connectedDevices.containsKey(address)){
                                new Handler(Looper.getMainLooper()).post(() -> {
                                    result.success(true);
                                });
                                return;
                            }

                            FlutterBluetoothDevice device = new FlutterBluetoothDevice(flutterPluginBinding.getBinaryMessenger(), bluetoothAdapter, address, () -> {
                                connectedDevices.remove(address);
                            });

                            device.connect();
                            connectedDevices.put(address, device);
                            new Handler(Looper.getMainLooper()).post(() -> {
                                result.success(true);
                            });
                        } catch (Exception e) {
                            new Handler(Looper.getMainLooper()).post(() -> {
                                result.error("error", e.getMessage(), null);
                            });
                        }
                    }
                });

                break;
            }

            case "dispose": {
                AsyncTask.execute(()->{
                    synchronized (connectedDevices) {
                        stopDiscovery();
                        Object[] addresses = connectedDevices.keySet().toArray();
                        for (Object address : addresses) {
                            final FlutterBluetoothDevice device = connectedDevices.get(address.toString());
                            if (device != null) {
                                try {
                                    device.disconnect();
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }
                            }
                        }

                        new Handler(Looper.getMainLooper()).post(() -> {
                            result.success(true);
                        });
                    }
                });
                break;
            }

            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        flutterPluginBinding.getApplicationContext().unregisterReceiver(receiver);
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
        if (requestCode == 919191 ){
            for (int i = 0; i < grantResults.length; i++) {
                final int result = grantResults[i];
                if (result != PackageManager.PERMISSION_GRANTED) {
                    for (EventChannel.EventSink sink :  sinkList.values()) {
                        sink.error("permissionDenied", permissions[i], "");
                    }
                    return true;
                }
            }

            startDiscovery();
            return true;
        }

        return false;
    }

    private final Map<Object, EventChannel.EventSink> sinkList = new HashMap<>();
    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        sinkList.put(arguments, events);
        startDiscovery();
    }

    @Override
    public void onCancel(Object arguments) {
        sinkList.remove(arguments);
        if (sinkList.isEmpty()){
            stopDiscovery();
        }
    }
}
