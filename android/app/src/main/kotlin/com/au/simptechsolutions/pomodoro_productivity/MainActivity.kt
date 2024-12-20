package com.au.simptechsolutions.pomodoro_productivity

import android.os.Bundle
import android.os.PowerManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.au.simptechsolutions.pomodoro_productivity/wakelock"
    private var wakeLock: PowerManager.WakeLock? = null
    private val TAG = "WakeLock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquireWakeLock" -> {
                    acquireWakeLock()
                    result.success(null)
                }
                "releaseWakeLock" -> {
                    releaseWakeLock()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "com.au.simptechsolutions.pomodoro_productivity::WakeLockTag")
            wakeLock?.acquire()
            Log.d(TAG, "Wake lock acquired")
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
                Log.d(TAG, "Wake lock released")
            }
            wakeLock = null
        }
    }
}