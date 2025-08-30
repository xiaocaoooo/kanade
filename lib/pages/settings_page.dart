import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'folder_whitelist_page.dart';
import 'debug_lyric_sender_page.dart';
import 'artist_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSectionTitle('媒体库'),
          // ListTile(
          //   title: const Text('扫描媒体库'),
          //   subtitle: const Text('重新扫描设备中的音乐文件'),
          //   trailing: const Icon(Icons.refresh),
          //   onTap: () {
          //     TODO 添加扫描音乐库的逻辑
          //     ScaffoldMessenger.of(
          //       context,
          //     ).showSnackBar(const SnackBar(content: Text('正在扫描媒体库...')));
          //   },
          // ),
          ListTile(
            title: const Text('文件夹白名单'),
            subtitle: const Text('设置需要扫描的音乐文件夹'),
            trailing: const Icon(Icons.folder),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FolderWhitelistPage(),
                ),
              );
            },
          ),
          _buildSectionTitle('艺术家'),
          ListTile(
            title: const Text('艺术家设置'),
            subtitle: const Text('设置艺术家分隔符和白名单'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ArtistSettingsPage(),
                ),
              );
            },
          ),
          _buildSectionTitle('调试'),
          ListTile(
            title: const Text('歌词发送调试'),
            subtitle: const Text('测试KanadaLyricSender插件功能'),
            trailing: const Icon(Icons.bug_report),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugLyricSenderPage(),
                ),
              );
            },
          ),
          
          _buildSectionTitle('关于'),
          ListTile(
            title: const Text('版本信息'),
            subtitle: const Text('当前版本: 1.0.0'),
            onTap: () {
              // 这里可以添加版本信息详情
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
