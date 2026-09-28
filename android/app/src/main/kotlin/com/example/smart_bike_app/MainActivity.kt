package com.example.smart_bike_app

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.smart_bike_app/bluetooth"
    private val REQUEST_ENABLE_BT = 101
    private val REQUEST_PERMISSIONS = 102
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                            val devMap = mapOf(
                                "name" to (device.name ?: "Unknown Device"),
                                "address" to (device.address ?: "00:00:00:00:00:00"),
                                "type" to device.type,
                                "isBonded" to true
                            )
                            bonded.add(devMap)
                        }
                    } catch (e: SecurityException) {
                        // Permission not granted
                    }
                    result.success(bonded)
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
}
