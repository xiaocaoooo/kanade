import 'dart:async';
import 'package:flutter/services.dart';
import '../models/song.dart';

/// 媒体通知服务类
/// 负责管理Android媒体通知和播放控制
class MediaNotificationService {
  static const MethodChannel _channel = MethodChannel('media_notification');
  static const EventChannel _eventChannel = EventChannel('media_notification_events');
  
  // 通知事件监听
  StreamSubscription? _eventSubscription;
  
  /// 通知回调
  Function()? onPlay;
  Function()? onPause;
  Function()? onNext;
  Function()? onPrevious;
  Function()? onStop;
  
  /// 初始化媒体通知
  void initialize() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(event);
      final action = data['action'] as String;
      
      switch (action) {
        case 'play':
          onPlay?.call();
          break;
        case 'pause':
          onPause?.call();
          break;
        case 'next':
          onNext?.call();
          break;
        case 'previous':
          onPrevious?.call();
          break;
        case 'stop':
          onStop?.call();
          break;
      }
    });
  }
  
  /// 显示媒体通知
  Future<void> showNotification({
    required Song song,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'isPlaying': isPlaying,
        'position': position.inMilliseconds,
        'duration': duration.inMilliseconds,
        'albumArt': song.albumArt,
      });
    } catch (e) {
      print('显示通知失败: $e');
    }
  }
  
  /// 更新播放状态
  Future<void> updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
  }) async {
    try {
      await _channel.invokeMethod('updatePlaybackState', {
        'isPlaying': isPlaying,
        'position': position.inMilliseconds,
        'duration': duration.inMilliseconds,
      });
    } catch (e) {
      print('更新播放状态失败: $e');
    }
  }
  
  /// 隐藏媒体通知
  Future<void> hideNotification() async {
    try {
      await _channel.invokeMethod('hideNotification');
    } catch (e) {
      print('隐藏通知失败: $e');
    }
  }
  
  /// 释放资源
  void dispose() {
    _eventSubscription?.cancel();
    hideNotification();
  }
}