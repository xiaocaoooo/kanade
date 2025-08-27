import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kanada_lyric_sender_method_channel.dart';

abstract class KanadaLyricSenderPlatform extends PlatformInterface {
  /// Constructs a KanadaLyricSenderPlatform.
  KanadaLyricSenderPlatform() : super(token: _token);

  static final Object _token = Object();

  static KanadaLyricSenderPlatform _instance = MethodChannelKanadaLyricSender();

  /// The default instance of [KanadaLyricSenderPlatform] to use.
  ///
  /// Defaults to [MethodChannelKanadaLyricSender].
  static KanadaLyricSenderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KanadaLyricSenderPlatform] when
  /// they register themselves.
  static set instance(KanadaLyricSenderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
