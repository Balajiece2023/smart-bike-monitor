package com.example.smart_bike_app

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.smart_bike_app/bluetooth"
    private val REQUEST_ENABLE_BT = 101
    private val REQUEST_PERMISSIONS = 102
    private var pendingResult: MethodChannel.Result? = null

    // Standard SPP (Serial Port Profile) UUID used by HC-05 / HC-06 / Bluetooth v2.0 modules
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private var sppSocket: BluetoothSocket? = null
    private var sppInputStream: InputStream? = null
    private var sppOutputStream: OutputStream? = null
    private var isSppConnected = false
    private val bgExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var flutterChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        flutterChannel = channel

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
            val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter

            when (call.method) {
                "checkPermissions" -> {
                    val hasPerms = checkAllPermissions()
                    result.success(hasPerms)
                }
                "requestPermissions" -> {
                    pendingResult = result
                    requestAllPermissions()
                }
                "isBluetoothEnabled" -> {
                    val isEnabled = bluetoothAdapter?.isEnabled ?: false
                    result.success(isEnabled)
                }
                "requestEnableBluetooth" -> {
                    if (bluetoothAdapter == null) {
                        result.success(false)
                    } else if (bluetoothAdapter.isEnabled) {
                        result.success(true)
                    } else {
                        val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                        try {
                            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT)
                            pendingResult = result
                        } catch (e: Exception) {
                            result.error("INTENT_ERROR", e.localizedMessage, null)
                        }
                    }
                }
                "getBondedDevices" -> {
                    if (bluetoothAdapter == null || !checkAllPermissions()) {
                        result.success(emptyList<Map<String, Any>>())
                        return@setMethodCallHandler
                    }
                    val bonded = mutableListOf<Map<String, Any>>()
                    try {
                        val pairedDevices = bluetoothAdapter.bondedDevices
                        for (device in pairedDevices) {
                            val name = device.name ?: "Unknown Device"
                            val address = device.address ?: "00:00:00:00:00:00"
                            val devMap = mapOf(
                                "name" to name,
                                "address" to address,
                                "type" to device.type,
                                "isBonded" to true,
                                "isClassic" to (device.type == android.bluetooth.BluetoothDevice.DEVICE_TYPE_CLASSIC || device.type == android.bluetooth.BluetoothDevice.DEVICE_TYPE_DUAL || name.contains("HC-05", ignoreCase = true) || name.contains("HC-06", ignoreCase = true))
                            )
                            bonded.add(devMap)
                        }
                    } catch (e: SecurityException) {
                        // Permission not granted
                    }
                    result.success(bonded)
                }
                "classicConnect" -> {
                    val address = call.argument<String>("address")
                    if (address == null || bluetoothAdapter == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    connectClassicSpp(bluetoothAdapter, address, result)
                }
                "classicDisconnect" -> {
                    disconnectClassicSpp()
                    result.success(true)
                }
                "classicSend" -> {
                    val data = call.argument<ByteArray>("data")
                    val text = call.argument<String>("text")
                    val bytesToSend = data ?: text?.toByteArray(Charsets.UTF_8)
                    if (bytesToSend != null) {
                        val success = sendClassicBytes(bytesToSend)
                        result.success(success)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAllPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val scan = ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
            val connect = ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
            val fineLoc = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            return scan && connect && fineLoc
        } else {
            val loc = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            return loc
        }
    }

    private fun requestAllPermissions() {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
            permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
        } else {
            permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
            permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        ActivityCompat.requestPermissions(this, permissions.toTypedArray(), REQUEST_PERMISSIONS)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_PERMISSIONS) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingResult?.success(allGranted)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_ENABLE_BT) {
            val isEnabled = (resultCode == RESULT_OK)
            pendingResult?.success(isEnabled)
            pendingResult = null
        }
    }

    private fun connectClassicSpp(adapter: BluetoothAdapter, address: String, result: MethodChannel.Result) {
        bgExecutor.execute {
            try {
                disconnectClassicSpp()

                // Cancel discovery before connecting as it slows down connection
                try {
                    adapter.cancelDiscovery()
                } catch (_: SecurityException) {}

                val device = adapter.getRemoteDevice(address)
                // Use standard SPP RFCOMM socket for HC-05
                val socket = try {
                    device.createRfcommSocketToServiceRecord(SPP_UUID)
                } catch (e: Exception) {
                    // Fallback using reflection for older Bluetooth 2.0 / HC-05 chipsets
                    val m = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                    m.invoke(device, 1) as BluetoothSocket
                }

                socket.connect()

                sppSocket = socket
                sppInputStream = socket.inputStream
                sppOutputStream = socket.outputStream
                isSppConnected = true

                mainHandler.post {
                    result.success(true)
                    notifyClassicStatus("connected", address)
                }

                // Start listening loop on background thread
                startClassicReaderLoop()

            } catch (e: Exception) {
                disconnectClassicSpp()
                mainHandler.post {
                    result.success(false)
                    notifyClassicStatus("disconnected", address)
                }
            }
        }
    }

    private fun startClassicReaderLoop() {
        val stream = sppInputStream ?: return
        val buffer = ByteArray(1024)

        while (isSppConnected) {
            try {
                val bytesRead = stream.read(buffer)
                if (bytesRead > 0) {
                    val readData = buffer.copyOf(bytesRead)
                    mainHandler.post {
                        flutterChannel?.invokeMethod("onClassicDataReceived", mapOf("data" to readData))
                    }
                } else if (bytesRead == -1) {
                    break
                }
            } catch (e: Exception) {
                break
            }
        }

        if (isSppConnected) {
            disconnectClassicSpp()
            mainHandler.post {
                notifyClassicStatus("disconnected", null)
            }
        }
    }

    private fun sendClassicBytes(bytes: ByteArray): Boolean {
        return try {
            val out = sppOutputStream
            if (out != null && isSppConnected) {
                out.write(bytes)
                out.flush()
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun disconnectClassicSpp() {
        isSppConnected = false
        try {
            sppInputStream?.close()
        } catch (_: Exception) {}
        try {
            sppOutputStream?.close()
        } catch (_: Exception) {}
        try {
            sppSocket?.close()
        } catch (_: Exception) {}
        sppInputStream = null
        sppOutputStream = null
        sppSocket = null
    }

    private fun notifyClassicStatus(status: String, address: String?) {
        val args = mutableMapOf<String, Any>("status" to status)
        if (address != null) args["address"] = address
        flutterChannel?.invokeMethod("onClassicStatusChanged", args)
    }

    override fun onDestroy() {
        disconnectClassicSpp()
        super.onDestroy()
    }
}
