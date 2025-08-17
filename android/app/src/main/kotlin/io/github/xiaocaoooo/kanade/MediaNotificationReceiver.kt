package io.github.xiaocaoooo.kanade

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.EventChannel

class MediaNotificationReceiver : BroadcastReceiver() {
    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "media_action") {
            val action = intent.getStringExtra("action")
            action?.let {
                eventSink?.success(mapOf("action" to it))
            }
        }
    }
}