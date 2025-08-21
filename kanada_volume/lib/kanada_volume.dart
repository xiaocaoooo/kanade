
import 'package:flutter/services.dart';

import 'kanada_volume_platform_interface.dart';

class KanadaVolume {
  Future<String?> getPlatformVersion() {
    return KanadaVolumePlatform.instance.getPlatformVersion();
  }
}

class KanadaVolumePlugin {
  // 保持与 Android 端一致的 channel 名称
  static const MethodChannel _channel =
  MethodChannel('kanada_volume');

  /// 获取当前音量
  static Future<int?> getVolume() async {
    try {
      final result = await _channel.invokeMethod<int>('getVolume');
      return result ?? 0;
    } on PlatformException catch (_) {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取最大音量
  static Future<int?> getMaxVolume() async {
    try {
      final result = await _channel.invokeMethod<int>('getMaxVolume');
      return result ?? 0;
    } on PlatformException catch (_) {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 设置音量
  static Future<void> setVolume(int volume) async {
    try {
      await _channel.invokeMethod<void>(
          'setVolume',
          volume,
      );
    } on PlatformException catch (_) {
      return;
    } catch (e) {
      return;
    }
  }
}