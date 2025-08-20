import 'package:flutter_test/flutter_test.dart';
import 'package:kanade_audio_plugin/kanade_audio_plugin.dart';
import 'package:kanade_audio_plugin/kanade_audio_plugin_platform_interface.dart';
import 'package:kanade_audio_plugin/kanade_audio_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKanadeAudioPluginPlatform
    with MockPlatformInterfaceMixin
    implements KanadeAudioPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final KanadeAudioPluginPlatform initialPlatform = KanadeAudioPluginPlatform.instance;

  test('$MethodChannelKanadeAudioPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKanadeAudioPlugin>());
  });

  test('getPlatformVersion', () async {
    KanadeAudioPlugin kanadeAudioPlugin = KanadeAudioPlugin();
    MockKanadeAudioPluginPlatform fakePlatform = MockKanadeAudioPluginPlatform();
    KanadeAudioPluginPlatform.instance = fakePlatform;

    expect(await kanadeAudioPlugin.getPlatformVersion(), '42');
  });
}
