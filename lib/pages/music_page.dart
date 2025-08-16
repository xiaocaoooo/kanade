import 'package:flutter/material.dart';
import 'package:kanade/pages/folder_page.dart';
import 'package:kanade/pages/artist_page.dart';
import 'package:kanade/pages/album_page.dart';

class MusicPage extends StatelessWidget {
  const MusicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('音乐')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '音乐分类',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildCategoryCard(
                    context: context,
                    icon: Icons.folder,
                    title: '文件夹',
                    subtitle: '按文件夹浏览音乐',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FolderPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryCard(
                    context: context,
                    icon: Icons.person,
                    title: '歌手',
                    subtitle: '按艺术家浏览音乐',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ArtistPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryCard(
                    context: context,
                    icon: Icons.album,
                    title: '专辑',
                    subtitle: '按专辑浏览音乐',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AlbumPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
