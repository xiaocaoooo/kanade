import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'kanada_lyric_sender_platform_interface.dart';

/// An implementation of [KanadaLyricSenderPlatform] that uses method channels.
class MethodChannelKanadaLyricSender extends KanadaLyricSenderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('kanada_lyric_sender');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
