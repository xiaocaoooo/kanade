import 'package:flutter/material.dart';

class FolderPage extends StatelessWidget {
  const FolderPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟文件夹数据
    final folders = [
      {'name': '音乐/流行', 'count': 42, 'path': '/storage/music/pop'},
      {'name': '音乐/摇滚', 'count': 28, 'path': '/storage/music/rock'},
      {'name': '音乐/古典', 'count': 15, 'path': '/storage/music/classical'},
      {'name': '下载/音乐', 'count': 67, 'path': '/storage/downloads/music'},
      {'name': 'SD卡/Music', 'count': 156, 'path': '/sdcard/Music'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('文件夹'),
      ),
      body: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return ListTile(
            leading: const Icon(Icons.folder, size: 40, color: Colors.amber),
            title: Text(
              folder['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${folder['count']} 首歌曲'),
            trailing: Text(
              folder['path'] as String,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              // 这里可以添加进入文件夹的操作
            },
          );
        },
      ),
    );
  }
}
