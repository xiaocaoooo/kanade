import 'package:flutter/services.dart';

void testMediaService() async {
  const channel = MethodChannel('media_service');
  try {
    final result = await channel.invokeMethod('getAllSongs');
    print('Success: ${result.length} songs found');
  } catch (e) {
    print('Error: $e');
  }
}

void main() {
  testMediaService();
}
