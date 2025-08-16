import 'package:flutter/material.dart';

class ArtistPage extends StatelessWidget {
  const ArtistPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟歌手数据
    final artists = [
      {'name': '周杰伦', 'albums': 12, 'songs': 156},
      {'name': '林俊杰', 'albums': 8, 'songs': 98},
      {'name': 'Taylor Swift', 'albums': 10, 'songs': 134},
      {'name': '陈奕迅', 'albums': 15, 'songs': 203},
      {'name': '邓紫棋', 'albums': 6, 'songs': 72},
      {'name': 'Ed Sheeran', 'albums': 5, 'songs': 67},
      {'name': '张学友', 'albums': 20, 'songs': 289},
      {'name': 'Adele', 'albums': 4, 'songs': 45},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('歌手')),
      body: ListView.builder(
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (artist['name'] as String).substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              artist['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${artist['albums']} 张专辑 · ${artist['songs']} 首歌曲'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 这里可以添加进入歌手详情页的操作
            },
          );
        },
      ),
    );
  }
}
