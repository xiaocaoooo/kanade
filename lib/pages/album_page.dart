import 'package:flutter/material.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟专辑数据
    final albums = [
      {'title': '范特西', 'artist': '周杰伦', 'year': 2001, 'songs': 10},
      {'title': '第二天堂', 'artist': '林俊杰', 'year': 2004, 'songs': 12},
      {'title': '1989', 'artist': 'Taylor Swift', 'year': 2014, 'songs': 13},
      {'title': 'U87', 'artist': '陈奕迅', 'year': 2005, 'songs': 11},
      {'title': '摩天动物园', 'artist': '邓紫棋', 'year': 2019, 'songs': 13},
      {
        'title': '÷ (Divide)',
        'artist': 'Ed Sheeran',
        'year': 2017,
        'songs': 12,
      },
      {'title': '吻别', 'artist': '张学友', 'year': 1993, 'songs': 10},
      {'title': '25', 'artist': 'Adele', 'year': 2015, 'songs': 11},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('专辑')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                // 这里可以添加进入专辑详情页的操作
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.album,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          album['artist'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${album['year']} · ${album['songs']} 首',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
