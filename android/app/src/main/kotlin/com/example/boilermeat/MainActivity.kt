package com.example.boilermeat

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Bundle
import android.os.PersistableBundle
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    var res: MethodChannel.Result? = null

    lateinit var wifiManager: WifiManager;

    private val wifiReceiver = object: BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED
            ) {
                res?.error("PERMISSION_DENIED", "Permission was revoked", null)
            }

            var map: List<Map<String, Any>> = wifiManager.scanResults.map {
                mapOf(
                    "mac" to it.BSSID,
                    "level" to it.level,
                    "rtt" to it.is80211mcResponder
                )
            }

            res?.success(map)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)
    }

    fun start() {
//        res?.success(listOf(mapOf("mac" to "test", "level" to 0, "rtt" to false)))
        wifiManager.startScan();
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        when (requestCode) {
            69 -> {
                if (grantResults.all {it==PackageManager.PERMISSION_GRANTED}) {
                    start()
                } else {
                    res?.error("PERMISSION_DENIED", "Permission denied", null)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager;
        registerReceiver(wifiReceiver, IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION));

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "scanWifi").setMethodCallHandler { call, result ->
            res = result;

            if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED && checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            ) {
                start();
            } else {
                requestPermissions(
                    arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                    ), 69
                );
            }
        }
    }
}
