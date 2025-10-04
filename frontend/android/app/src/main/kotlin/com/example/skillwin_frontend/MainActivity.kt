package com.example.skillwin_frontend

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UNITY_METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchUnity" -> {
                        launchUnity(call.argument<String>("scene"))
                        result.success(null)
                    }
                    "sendMessage" -> {
                        val gameObject = call.argument<String>("gameObject")
                        val method = call.argument<String>("method")
                        val message = call.argument<String>("message") ?: ""
                        if (gameObject.isNullOrBlank() || method.isNullOrBlank()) {
                            result.error("invalid_args", "Both gameObject and method are required.", null)
                        } else {
                            UnityBridge.sendMessage(gameObject, method, message)
                            result.success(null)
                        }
                    }
                    "closeUnity" -> {
                        UnityBridge.requestUnload()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, UNITY_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    UnityBridge.attach(events)
                }

                override fun onCancel(arguments: Any?) {
                    UnityBridge.detach()
                }
            })
    }

    private fun launchUnity(targetScene: String?) {
        runOnUiThread {
            UnityBridge.setPendingScene(targetScene)
            val intent = Intent(this, TanksUnityActivity::class.java)
            intent.putExtra(TanksUnityActivity.EXTRA_TARGET_SCENE, targetScene)
            startActivity(intent)
        }
    }

    companion object {
        private const val UNITY_METHOD_CHANNEL = "tickup/unity/methods"
        private const val UNITY_EVENT_CHANNEL = "tickup/unity/events"
    }
}
