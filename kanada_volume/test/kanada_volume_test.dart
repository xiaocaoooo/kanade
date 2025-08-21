import 'package:flutter_test/flutter_test.dart';
import 'package:kanada_volume/kanada_volume.dart';
import 'package:kanada_volume/kanada_volume_platform_interface.dart';
import 'package:kanada_volume/kanada_volume_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKanadaVolumePlatform
    with MockPlatformInterfaceMixin
    implements KanadaVolumePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final KanadaVolumePlatform initialPlatform = KanadaVolumePlatform.instance;

  test('$MethodChannelKanadaVolume is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKanadaVolume>());
  });

  test('getPlatformVersion', () async {
    KanadaVolume kanadaVolumePlugin = KanadaVolume();
    MockKanadaVolumePlatform fakePlatform = MockKanadaVolumePlatform();
    KanadaVolumePlatform.instance = fakePlatform;

    expect(await kanadaVolumePlugin.getPlatformVersion(), '42');
  });
}
