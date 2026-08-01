package com.rkuhonta.tindatrack

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var navigationChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        navigationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NAVIGATION_CHANNEL,
        )
        navigationChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                FINISH_APP_METHOD -> {
                    finish()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onBackPressed() {
        navigationChannel?.invokeMethod(SYSTEM_BACK_METHOD, null)
    }

    companion object {
        private const val NAVIGATION_CHANNEL = "tindatrack/navigation"
        private const val SYSTEM_BACK_METHOD = "systemBack"
        private const val FINISH_APP_METHOD = "finishApp"
    }
}
