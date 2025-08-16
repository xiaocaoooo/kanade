import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> searchResults = [];

  void _searchMusic() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // 模拟搜索本地音乐数据
    setState(() {
      searchResults = [
        '歌曲1 - 艺术家1',
        '歌曲2 - 艺术家2',
        '歌曲3 - 艺术家3',
        '专辑1 - 艺术家1',
        '专辑2 - 艺术家2',
      ].where((item) => item.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _searchAllMusic() {
    // 模拟搜索全部音乐
    setState(() {
      searchResults = [
        '全部歌曲1 - 艺术家A',
        '全部歌曲2 - 艺术家B',
        '全部歌曲3 - 艺术家C',
        '全部专辑1 - 艺术家A',
        '全部专辑2 - 艺术家B',
        '全部专辑3 - 艺术家C',
      ];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SearchBar(
              controller: _searchController,
              hintText: '搜索音乐、艺术家、专辑...',
              leading: const Icon(Icons.search),
              trailing: [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchResults.clear();
                    });
                  },
                ),
              ],
              onSubmitted: (_) => _searchMusic(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _searchAllMusic,
              icon: const Icon(Icons.library_music),
              label: const Text('搜索全部音乐'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(searchResults[index]),
                      onTap: () {
                        // 这里可以添加点击后的操作
                      },
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty)
              const Center(
                child: Text('未找到匹配的音乐'),
              )
            else
              const Center(
                child: Text('输入关键词开始搜索'),
              ),
          ],
        ),
      ),
    );
  }
}
