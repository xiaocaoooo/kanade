import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanada_lyric_sender/kanada_lyric_sender_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelKanadaLyricSender platform = MethodChannelKanadaLyricSender();
  const MethodChannel channel = MethodChannel('kanada_lyric_sender');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
