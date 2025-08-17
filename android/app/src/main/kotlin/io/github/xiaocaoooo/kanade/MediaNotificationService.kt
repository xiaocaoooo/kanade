package io.github.xiaocaoooo.kanade

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MediaNotificationService : FlutterPlugin, MethodCallHandler {
    private lateinit var context: Context
    private lateinit var notificationManager: NotificationManagerCompat
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    
    companion object {
        private const val CHANNEL_ID = "media_notification_channel"
        private const val NOTIFICATION_ID = 1
        private const val REQUEST_CODE = 100
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        notificationManager = NotificationManagerCompat.from(context)
        
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "media_notification")
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "media_notification_events")
        eventChannel.setStreamHandler(MediaNotificationStreamHandler())
        
        createNotificationChannel()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "showNotification" -> showNotification(call, result)
            "updatePlaybackState" -> updatePlaybackState(call, result)
            "hideNotification" -> hideNotification(result)
            else -> result.notImplemented()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Media Playback"
            val descriptionText = "Controls for media playback"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(call: MethodCall, result: Result) {
        try {
            val title = call.argument<String>("title") ?: "Unknown Title"
            val artist = call.argument<String>("artist") ?: "Unknown Artist"
            val album = call.argument<String>("album") ?: "Unknown Album"
            val isPlaying = call.argument<Boolean>("isPlaying") ?: false
            val position = call.argument<Int>("position") ?: 0
            val duration = call.argument<Int>("duration") ?: 0
            val albumArtBytes = call.argument<ByteArray>("albumArt")

            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val playPauseAction = createAction(
                if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                if (isPlaying) "Pause" else "Play",
                if (isPlaying) "pause" else "play"
            )

            val nextAction = createAction(
                android.R.drawable.ic_media_next,
                "Next",
                "next"
            )

            val prevAction = createAction(
                android.R.drawable.ic_media_previous,
                "Previous",
                "previous"
            )

            val stopAction = createAction(
                android.R.drawable.ic_media_pause,
                "Stop",
                "stop"
            )

            val bitmap = albumArtBytes?.let { bytes ->
                BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            }

            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentTitle(title)
                .setContentText("$artist - $album")
                .setLargeIcon(bitmap)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(isPlaying)
                .addAction(prevAction)
                .addAction(playPauseAction)
                .addAction(nextAction)
                .addAction(stopAction)
                .build()

            notificationManager.notify(NOTIFICATION_ID, notification)
            result.success(null)
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", "Failed to show notification: ${e.message}", null)
        }
    }

    private fun updatePlaybackState(call: MethodCall, result: Result) {
        try {
            val isPlaying = call.argument<Boolean>("isPlaying") ?: false
            val position = call.argument<Int>("position") ?: 0
            val duration = call.argument<Int>("duration") ?: 0

            // 更新现有通知的播放状态
            result.success(null)
        } catch (e: Exception) {
            result.error("UPDATE_ERROR", "Failed to update playback state: ${e.message}", null)
        }
    }

    private fun hideNotification(result: Result) {
        try {
            notificationManager.cancel(NOTIFICATION_ID)
            result.success(null)
        } catch (e: Exception) {
            result.error("HIDE_ERROR", "Failed to hide notification: ${e.message}", null)
        }
    }

    private fun createAction(icon: Int, title: String, actionName: String): NotificationCompat.Action {
        val intent = Intent(context, MediaNotificationReceiver::class.java).apply {
            action = "media_action"
            putExtra("action", actionName)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Action(icon, title, pendingIntent)
    }
}

class MediaNotificationStreamHandler : EventChannel.StreamHandler {
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        MediaNotificationReceiver.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        MediaNotificationReceiver.eventSink = null
    }
}