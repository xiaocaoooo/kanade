import 'package:flutter/material.dart';
import 'package:kanade/services/music_service.dart';
import 'package:kanade/services/settings_service.dart';

/// 文件夹白名单设置页面
/// 允许用户设置哪些文件夹的音乐文件需要被扫描和显示
class FolderWhitelistPage extends StatefulWidget {
  const FolderWhitelistPage({super.key});

  @override
  State<FolderWhitelistPage> createState() => _FolderWhitelistPageState();
}

class _FolderWhitelistPageState extends State<FolderWhitelistPage> {
  Map<String, bool> _folderWhitelist = {};
  List<String> _allFolders = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  /// 加载文件夹列表和白名单设置
  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取所有音乐文件夹
      final allFolders = await MusicService.getAllMusicFolders();
      
      // 获取当前白名单设置
      final whitelist = await SettingsService.getFolderWhitelist();
      
      // 合并设置，确保所有文件夹都有默认值（true）
      final Map<String, bool> mergedWhitelist = {};
      for (final folder in allFolders) {
        mergedWhitelist[folder] = whitelist[folder] ?? true;
      }
      
      setState(() {
        _allFolders = allFolders;
        _folderWhitelist = mergedWhitelist;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载文件夹列表时出错: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 保存白名单设置
  Future<void> _saveWhitelist() async {
    if (!_hasChanges) return;

    try {
      await SettingsService.setFolderWhitelist(_folderWhitelist);
      setState(() {
        _hasChanges = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存')),
        );
      }
    } catch (e) {
      debugPrint('保存白名单设置时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
    }
  }

  /// 切换文件夹的白名单状态
  void _toggleFolder(String folder, bool? value) {
    if (value == null) return;
    
    setState(() {
      _folderWhitelist[folder] = value;
      _hasChanges = true;
    });
  }

  /// 全选所有文件夹
  void _selectAll() {
    setState(() {
      for (final folder in _allFolders) {
        _folderWhitelist[folder] = true;
      }
      _hasChanges = true;
    });
  }

  /// 取消全选所有文件夹
  void _deselectAll() {
    setState(() {
      for (final folder in _allFolders) {
        _folderWhitelist[folder] = false;
      }
      _hasChanges = true;
    });
  }

  /// 恢复默认设置（全部选中）
  void _resetToDefault() {
    setState(() {
      for (final folder in _allFolders) {
        _folderWhitelist[folder] = true;
      }
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件夹白名单'),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveWhitelist,
              tooltip: '保存设置',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allFolders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '未找到音乐文件夹',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '请确保设备中有音乐文件',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFolders,
              child: const Text('重新扫描'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildActionsBar(),
        Expanded(
          child: _buildFolderList(),
        ),
      ],
    );
  }

  Widget _buildActionsBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          TextButton.icon(
            icon: const Icon(Icons.select_all),
            label: const Text('全选'),
            onPressed: _selectAll,
          ),
          TextButton.icon(
            icon: const Icon(Icons.deselect),
            label: const Text('取消全选'),
            onPressed: _deselectAll,
          ),
          TextButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('恢复默认'),
            onPressed: _resetToDefault,
          ),
          const Spacer(),
          if (_hasChanges)
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('保存'),
              onPressed: _saveWhitelist,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFolderList() {
    return ListView.builder(
      itemCount: _allFolders.length,
      itemBuilder: (context, index) {
        final folder = _allFolders[index];
        final isEnabled = _folderWhitelist[folder] ?? true;
        
        return _buildFolderItem(folder, isEnabled);
      },
    );
  }

  Widget _buildFolderItem(String folder, bool isEnabled) {
    // 简化文件夹路径显示
    final displayPath = folder.replaceAll('/storage/emulated/0/', '');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: ListTile(
        leading: Icon(
          isEnabled ? Icons.folder : Icons.folder_off,
          color: isEnabled ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        title: Text(
          displayPath,
          style: TextStyle(
            color: isEnabled ? null : Colors.grey,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isEnabled ? '已包含在扫描范围' : '已排除在扫描范围',
          style: TextStyle(
            color: isEnabled ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: isEnabled,
          onChanged: (value) => _toggleFolder(folder, value),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        onTap: () => _toggleFolder(folder, !isEnabled),
      ),
    );
  }
}