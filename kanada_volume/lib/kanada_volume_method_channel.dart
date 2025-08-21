import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'kanada_volume_platform_interface.dart';

/// An implementation of [KanadaVolumePlatform] that uses method channels.
class MethodChannelKanadaVolume extends KanadaVolumePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('kanada_volume');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
