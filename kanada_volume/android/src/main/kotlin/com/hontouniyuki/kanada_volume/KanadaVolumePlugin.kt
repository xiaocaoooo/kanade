package com.hontouniyuki.kanada_volume

import android.content.Context
import android.media.AudioManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.roundToInt

class KanadaVolumePlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var context: Context? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kanada_volume")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "getVolume" -> handleGetVolume(result)
      "getMaxVolume" -> handleGetMaxVolume(result)
      "setVolume" -> handleSetVolume(call, result)
      else -> result.notImplemented()
    }
  }

  private fun handleGetVolume(result: Result) {
    val audioManager = context?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
      ?: run {
        result.error("UNAVAILABLE", "Audio service not available", null)
        return
      }

    val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
    result.success(currentVolume)
  }

  private fun handleGetMaxVolume(result: Result) {
    val audioManager = context?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
      ?: run {
        result.error("UNAVAILABLE", "Audio service not available", null)
        return
      }

    val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
    result.success(maxVolume)
  }

  private fun handleSetVolume(call: MethodCall, result: Result) {
    val volume = call.arguments as? Int ?: run {
      result.error("INVALID_ARGUMENT", "Volume must be an integer", null)
      return
    }

    val audioManager = context?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
      ?: run {
        result.error("UNAVAILABLE", "Audio service not available", null)
        return
      }

    val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
    val targetVolume = volume.coerceIn(0, maxVolume)

    try {
      audioManager.setStreamVolume(
        AudioManager.STREAM_MUSIC,
        targetVolume,
        0  // Flag: 0表示静默调整，不显示系统UI
      )
      result.success(null)
    } catch (e: SecurityException) {
      result.error("PERMISSION_DENIED", "No permission to adjust volume", null)
    } catch (e: Exception) {
      result.error("ERROR", "Failed to set volume: ${e.message}", null)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
  }
}