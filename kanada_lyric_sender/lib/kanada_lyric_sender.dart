import 'package:flutter/services.dart';

import 'kanada_lyric_sender_platform_interface.dart';

class KanadaLyricSender {
  Future<String?> getPlatformVersion() {
    return KanadaLyricSenderPlatform.instance.getPlatformVersion();
  }
}

/// 用于与原生端进行歌词发送相关功能交互的插件类。
class KanadaLyricSenderPlugin {
  // 定义与 Android 端一致的 MethodChannel 名称
  static const MethodChannel _channel = MethodChannel('kanada_lyric_sender');

  /// 检查原生端歌词发送功能是否已启用。
  ///
  /// 返回一个 [Future]，其结果为布尔值，表示功能是否启用。
  /// 若调用原生方法时发生错误，将返回 `false`。
  static Future<bool> hasEnable() async {
    try {
      // 通过 MethodChannel 调用原生方法'sendLyric'
      final result = await _channel.invokeMethod<bool>('hasEnable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 将提供的歌词发送到原生端，并可指定可选的延迟时间。
  ///
  /// [lyric] 是要发送的歌词内容。
  /// [duration] 是可选的歌词持续时间（秒），若未提供则默认为 0。
  /// 若调用原生方法时发生错误，方法将静默返回。
  static Future<void> sendLyric(String lyric, [int? duration]) async {
    /// 发送歌词
    try {
      // 通过 MethodChannel 调用原生方法 'sendLyric'
      await _channel.invokeMethod<void>('sendLyric', {
        'lyric': lyric,
        'delay': duration ?? 0,
      });
    } catch (e) {
      return;
    }
  }

  /// 清除原生端的歌词。
  ///
  /// 若调用原生方法时发生错误，方法将静默返回。
  static Future<void> clearLyric() async {
    /// 清除歌词
    try {
      // 通过 MethodChannel 调用原生方法'sendLyric'
      await _channel.invokeMethod<void>('clearLyric');
    } catch (e) {
      return;
    }
  }
}
