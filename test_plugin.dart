import 'package:flutter/services.dart';
import 'dart:developer' as developer;

void testMediaService() async {
  const channel = MethodChannel('media_service');
  try {
    final result = await channel.invokeMethod('getAllSongs');
    developer.log('Success: ${result.length} songs found');
  } catch (e) {
    developer.log('Error: $e');
  }
}

void main() {
  testMediaService();
}
