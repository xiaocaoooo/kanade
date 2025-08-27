package com.hontouniyuki.kanada_lyric_sender

import android.content.Context
import cn.lyric.getter.api.API
import cn.lyric.getter.api.data.ExtraData
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class KanadaLyricSenderPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private val lga by lazy { API() }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kanada_lyric_sender")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "hasEnable" -> {
        result.success(lga.hasEnable)
      }
      "sendLyric" -> {
        val lyric = call.argument<String>("lyric") ?: ""
        lga.sendLyric(lyric, extra = ExtraData().apply {
          packageName = "com.hontouniyuki.kanada"
          useOwnMusicController = false
          delay = call.argument<Int>("delay") ?: 0
        })
        result.success(null)
      }
      "clearLyric" -> {
        lga.clearLyric()
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  // ... 保留原有未修改的 onDetachedFromEngine 方法 ...
  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}