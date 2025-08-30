import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class ArtistSettingsPage extends StatefulWidget {
  const ArtistSettingsPage({super.key});

  @override
  State<ArtistSettingsPage> createState() => _ArtistSettingsPageState();
}

class _ArtistSettingsPageState extends State<ArtistSettingsPage> {
  List<String> _artistSeparators = [];
  List<String> _artistWhitelist = [];
  final TextEditingController _separatorController = TextEditingController();
  final TextEditingController _whitelistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _separatorController.dispose();
    _whitelistController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final separators = await SettingsService.getArtistSeparators();
    final whitelist = await SettingsService.getArtistWhitelist();
    setState(() {
      _artistSeparators = separators;
      _artistWhitelist = whitelist;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('艺术家设置')),
      body: ListView(
        children: [
          _buildSectionTitle('艺术家分隔符'),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '配置艺术家名称的分隔符，按优先级使用',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      _artistSeparators
                          .map(
                            (separator) => Chip(
                              label: Text(separator),
                              onDeleted: () => _removeSeparator(separator),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _separatorController,
                        decoration: const InputDecoration(
                          labelText: '添加分隔符',
                          hintText: '输入单个字符，如: / & ,',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        maxLength: 1,
                        onSubmitted: _addSeparator,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _addSeparator(_separatorController.text),
                      child: const Text('添加'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetToDefaultSeparators,
                      child: const Text('恢复默认'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _clearAllSeparators,
                      child: const Text('清空所有'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildSectionTitle('艺术家白名单'),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '设置不应被分割的艺术家名称，如: 25時、ナイトコードで。',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      _artistWhitelist
                          .map(
                            (artist) => Chip(
                              label: Text(artist),
                              onDeleted: () => _removeWhitelistArtist(artist),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _whitelistController,
                        decoration: const InputDecoration(
                          labelText: '添加艺术家',
                          hintText: '输入艺术家名称，如: 25時、ナイトコードで。',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: _addWhitelistArtist,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _addWhitelistArtist(_whitelistController.text),
                      child: const Text('添加'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetToDefaultWhitelist,
                      child: const Text('恢复默认'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _clearAllWhitelist,
                      child: const Text('清空所有'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addSeparator(String separator) {
    if (separator.isEmpty) return;

    final trimmedSeparator = separator.trim();
    if (trimmedSeparator.isEmpty) return;

    setState(() {
      if (!_artistSeparators.contains(trimmedSeparator)) {
        _artistSeparators.add(trimmedSeparator);
        SettingsService.setArtistSeparators(_artistSeparators);
      }
      _separatorController.clear();
    });
  }

  void _removeSeparator(String separator) {
    setState(() {
      _artistSeparators.remove(separator);
      SettingsService.setArtistSeparators(_artistSeparators);
    });
  }

  void _resetToDefaultSeparators() {
    setState(() {
      _artistSeparators = SettingsService.getDefaultSeparators();
      SettingsService.setArtistSeparators(_artistSeparators);
    });
  }

  void _clearAllSeparators() {
    setState(() {
      _artistSeparators.clear();
      SettingsService.setArtistSeparators(_artistSeparators);
    });
  }

  void _addWhitelistArtist(String artist) {
    if (artist.isEmpty) return;

    final trimmedArtist = artist.trim();
    if (trimmedArtist.isEmpty) return;

    setState(() {
      if (!_artistWhitelist.contains(trimmedArtist)) {
        _artistWhitelist.add(trimmedArtist);
        SettingsService.setArtistWhitelist(_artistWhitelist);
      }
      _whitelistController.clear();
    });
  }

  void _removeWhitelistArtist(String artist) {
    setState(() {
      _artistWhitelist.remove(artist);
      SettingsService.setArtistWhitelist(_artistWhitelist);
    });
  }

  void _resetToDefaultWhitelist() {
    setState(() {
      _artistWhitelist = SettingsService.getDefaultWhitelist();
      SettingsService.setArtistWhitelist(_artistWhitelist);
    });
  }

  void _clearAllWhitelist() {
    setState(() {
      _artistWhitelist.clear();
      SettingsService.setArtistWhitelist(_artistWhitelist);
    });
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