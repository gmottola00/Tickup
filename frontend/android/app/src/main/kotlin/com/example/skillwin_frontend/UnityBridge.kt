package com.example.skillwin_frontend

import android.os.Handler
import android.os.Looper
import com.unity3d.player.UnityPlayer
import io.flutter.plugin.common.EventChannel

object UnityBridge {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var pendingScene: String? = null

    fun attach(sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun detach() {
        eventSink = null
    }

    fun setPendingScene(sceneName: String?) {
        pendingScene = sceneName
    }

    fun consumePendingScene(): String? = pendingScene.also { pendingScene = null }

    fun sendMessage(gameObject: String, method: String, message: String) {
        UnityPlayer.UnitySendMessage(gameObject, method, message)
    }

    fun requestUnload() {
        val current = UnityPlayer.currentActivity
        if (current is TanksUnityActivity) {
            current.finishUnityFromFlutter()
        }
    }

    @JvmStatic
    fun dispatch(type: String, payload: Map<String, Any?> = emptyMap()) {
        val envelope = mutableMapOf<String, Any?>("type" to type)
        envelope.putAll(payload)
        mainHandler.post { eventSink?.success(envelope) }
    }

    @JvmStatic
    fun dispatchMessage(message: String) {
        dispatch("message", mapOf("value" to message))
    }

    @JvmStatic
    fun notifySceneLoaded(sceneName: String) {
        dispatch("scene_loaded", mapOf("scene" to sceneName))
    }

    @JvmStatic
    fun notifyGameEvent(event: String, payload: String? = null) {
        val data = mutableMapOf<String, Any?>("event" to event)
        if (!payload.isNullOrEmpty()) {
            data["payload"] = payload
        }
        dispatch("game_event", data)
    }
}
