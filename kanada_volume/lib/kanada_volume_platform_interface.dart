import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kanada_volume_method_channel.dart';

abstract class KanadaVolumePlatform extends PlatformInterface {
  /// Constructs a KanadaVolumePlatform.
  KanadaVolumePlatform() : super(token: _token);

  static final Object _token = Object();

  static KanadaVolumePlatform _instance = MethodChannelKanadaVolume();

  /// The default instance of [KanadaVolumePlatform] to use.
  ///
  /// Defaults to [MethodChannelKanadaVolume].
  static KanadaVolumePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KanadaVolumePlatform] when
  /// they register themselves.
  static set instance(KanadaVolumePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
