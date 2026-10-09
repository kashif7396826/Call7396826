package com.calldrag.calldrag_mobile

import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import androidx.localbroadcastmanager.content.LocalBroadcastManager

/**
 * Brings CallDrag to the foreground the moment a call is connected.
 *
 * When an incoming call is answered from the system call screen with the app closed, the
 * twilio_voice plugin can only start its call service as "phoneCall" (Android blocks a
 * microphone-typed service from the background), and it adds microphone access later, when
 * the app's activity resumes. Nothing opens the app by itself, so the caller hears silence
 * until the user opens CallDrag manually. This listens for the plugin's own in-process
 * "call connected" broadcast and opens the main screen so that step happens automatically.
 *
 * Runs in Application.onCreate so it is also live when the process was started by an FCM push
 * with no activity open.
 */
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        LocalBroadcastManager.getInstance(this).registerReceiver(
            object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    Log.d(TAG, "call connected - bringing CallDrag to the foreground")
                    val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
                    launch.addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                    )
                    try {
                        context.startActivity(launch)
                    } catch (e: Exception) {
                        Log.w(TAG, "could not bring CallDrag to the foreground: $e")
                    }
                }
            },
            IntentFilter("com.twilio.EVENT_CONNECTED")
        )
    }

    companion object {
        private const val TAG = "CallDragApp"
    }
}
