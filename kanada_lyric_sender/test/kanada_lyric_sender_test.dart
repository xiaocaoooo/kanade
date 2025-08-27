import 'package:flutter_test/flutter_test.dart';
import 'package:kanada_lyric_sender/kanada_lyric_sender.dart';
import 'package:kanada_lyric_sender/kanada_lyric_sender_platform_interface.dart';
import 'package:kanada_lyric_sender/kanada_lyric_sender_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKanadaLyricSenderPlatform
    with MockPlatformInterfaceMixin
    implements KanadaLyricSenderPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final KanadaLyricSenderPlatform initialPlatform = KanadaLyricSenderPlatform.instance;

  test('$MethodChannelKanadaLyricSender is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKanadaLyricSender>());
  });

  test('getPlatformVersion', () async {
    KanadaLyricSender kanadaLyricSenderPlugin = KanadaLyricSender();
    MockKanadaLyricSenderPlatform fakePlatform = MockKanadaLyricSenderPlatform();
    KanadaLyricSenderPlatform.instance = fakePlatform;

    expect(await kanadaLyricSenderPlugin.getPlatformVersion(), '42');
  });
}
