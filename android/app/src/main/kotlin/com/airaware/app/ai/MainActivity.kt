package com.airaware.app.ai

import android.content.Context
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "airaware/battery_optimization"
        ).setMethodCallHandler { call, result ->
            if (call.method == "isBatteryOptimizationEnabled") {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                val ignoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                result.success(!ignoring)
            } else {
                result.notImplemented()
            }
        }
    }
}
