package com.example.skillwin_frontend

import android.content.Intent
import android.os.Bundle
import com.unity3d.player.UnityPlayer
import com.unity3d.player.UnityPlayerActivity

class TanksUnityActivity : UnityPlayerActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        UnityBridge.setPendingScene(intent?.getStringExtra(EXTRA_TARGET_SCENE))
        super.onCreate(savedInstanceState)
        UnityBridge.dispatch("unity_started")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        UnityBridge.setPendingScene(intent.getStringExtra(EXTRA_TARGET_SCENE))
    }

    override fun onUnityPlayerUnloaded() {
        super.onUnityPlayerUnloaded()
        UnityBridge.dispatch("unity_unloaded")
        finish()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        UnityBridge.dispatch("focus", mapOf("value" to hasFocus))
        if (hasFocus) {
            UnityBridge.consumePendingScene()?.let { scene ->
                UnityPlayer.UnitySendMessage("GameManager", "LoadScene", scene)
            }
        }
    }

    override fun onDestroy() {
        UnityBridge.dispatch("unity_closed")
        super.onDestroy()
    }

    fun finishUnityFromFlutter() {
        runOnUiThread { finish() }
    }

    companion object {
        const val EXTRA_TARGET_SCENE = "tickup_target_scene"
    }
}
