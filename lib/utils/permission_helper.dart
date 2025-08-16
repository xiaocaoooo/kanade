import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 权限处理工具类
/// 处理应用所需的权限请求和管理
class PermissionHelper {
  /// 请求媒体权限
  static Future<bool> requestMediaPermissions() async {
    try {
      // 检查Android版本以确定需要请求的权限
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // Android 13及以上版本
        if (sdkInt >= 33) {
          Map<Permission, PermissionStatus> permissions =
              await [Permission.audio, Permission.photos].request();

          return permissions[Permission.audio]?.isGranted == true &&
              permissions[Permission.photos]?.isGranted == true;
        } else {
          // Android 12及以下版本
          PermissionStatus status = await Permission.storage.request();
          return status.isGranted;
        }
      }

      // iOS或其他平台
      return true;
    } catch (e) {
      debugPrint('请求权限时出错: $e');
      return false;
    }
  }

  /// 检查媒体权限状态
  static Future<bool> checkMediaPermissions() async {
    // 检查Android版本
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Android 13及以上版本
      if (sdkInt >= 33) {
        final audioStatus = await Permission.audio.status;
        final photosStatus = await Permission.photos.status;
        return audioStatus.isGranted && photosStatus.isGranted;
      } else {
        // Android 12及以下版本
        final storageStatus = await Permission.storage.status;
        return storageStatus.isGranted;
      }
    }
    return true;
  }

  /// 显示权限被拒绝的对话框
  static void showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('权限需要'),
            content: const Text('需要存储权限来访问您的本地音乐文件。请在设置中授予权限。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('前往设置'),
              ),
            ],
          ),
    );
  }
}
