import 'package:flutter/services.dart';

import 'kanada_lyric_sender_platform_interface.dart';

class KanadaLyricSender {
  Future<String?> getPlatformVersion() {
    return KanadaLyricSenderPlatform.instance.getPlatformVersion();
  }
}

class KanadaLyricSenderPlugin {
  // 定义与 Android 端一致的 MethodChannel 名称
  static const MethodChannel _channel = MethodChannel('kanada_lyric_sender');

  static Future<bool> hasEnable() async {
    try {
      // 通过 MethodChannel 调用原生方法'sendLyric'
      final result = await _channel.invokeMethod<bool>('hasEnable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> sendLyric(String lyric, [int? delay]) async {
    try {
      // 通过 MethodChannel 调用原生方法 'sendLyric'
      await _channel.invokeMethod<void>('sendLyric', {
        'lyric': lyric,
        'delay': delay ?? 0,
      });
    } catch (e) {
      return;
    }
  }

  static Future<void> clearLyric() async {
    try {
      // 通过 MethodChannel 调用原生方法'sendLyric'
      await _channel.invokeMethod<void>('clearLyric');
    } catch (e) {
      return;
    }
  }
}
