import 'dart:typed_data';
import '../services/settings_service.dart';

/// 歌曲数据模型类
/// 包含歌曲的完整信息，用于展示和播放
class Song {
  /// 歌曲ID
  final String id;

  /// 歌曲标题
  final String title;

  /// 艺术家名称列表
  late List<String> _artists;
  List<String> get artists => _artists;
  String get artist => _artists.join(" / ");

  /// 专辑名称
  final String album;

  /// 歌曲时长（毫秒）
  final int duration;

  /// 文件路径
  final String path;

  /// 文件大小（字节）
  final int size;

  /// 专辑封面缩略图
  // final Uint8List? albumArt;
  Uri? get albumArtUri =>
      albumId != null
          ? Uri.parse("content://media/external/audio/albumart/$albumId")
          : null;

  /// 专辑ID（用于获取封面）
  final String? albumId;

  /// 创建时间
  final DateTime dateAdded;

  /// 最后修改时间
  final DateTime dateModified;

  Song({
    required this.id,
    required this.title,
    required String artist,
    required this.album,
    required this.duration,
    required this.path,
    required this.size,
    // this.albumArt,
    this.albumId,
    required this.dateAdded,
    required this.dateModified,
  }) : _artists = SettingsService.splitArtists(artist);

  /// 获取格式化的时长字符串
  String get formattedDuration {
    final minutes = (duration ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((duration % 60000) ~/ 1000).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 获取格式化的文件大小字符串
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 从Map创建Song对象
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '未知歌曲',
      artist: map['artist'] ?? '未知艺术家',
      album: map['album'] ?? '未知专辑',
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      path: map['path'] ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      // albumArt: albumArt,
      albumId: map['albumId']?.toString(),
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['dateAdded'] ?? 0),
      dateModified: DateTime.fromMillisecondsSinceEpoch(
        map['dateModified'] ?? 0,
      ),
    );
  }

  /// 创建歌曲的副本，并可选择性地修改某些属性
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? path,
    int? size,
    Uint8List? albumArt,
    String? albumId,
    DateTime? dateAdded,
    DateTime? dateModified,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      path: path ?? this.path,
      size: size ?? this.size,
      // albumArt: albumArt ?? this.albumArt,
      albumId: albumId ?? this.albumId,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
    );
  }

  @override
  String toString() {
    return 'Song(id: $id, title: $title, artist: $artist, album: $album, duration: $duration, path: $path, size: $size, albumArtUri: $albumArtUri, albumId: $albumId, dateAdded: $dateAdded, dateModified: $dateModified)';
  }
}
