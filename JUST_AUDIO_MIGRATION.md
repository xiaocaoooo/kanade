# 从 AudioPlayers 迁移到 JustAudio

## 迁移概述
项目已从 `audioplayers` 库迁移到 `just_audio` 库，并且移除了 `just_audio_background` 依赖。

## 主要变更

### 1. 依赖变更
- **移除**: `audioplayers: ^6.1.0`
- **新增**: `just_audio: ^0.9.38`

### 2. 音频服务重构
- 完全重构了 `AudioPlayerService` 类
- 从 `AudioPlayer` (audioplayers) 改为 `just_audio.AudioPlayer`
- 更新了事件监听机制以适应 just_audio 的流式API

### 3. API变更对比

| 功能 | AudioPlayers (旧) | JustAudio (新) |
|------|-------------------|----------------|
| 播放音频 | `play(DeviceFileSource(path))` | `setAudioSource(AudioSource.uri(...))` 然后 `play()` |
| 暂停 | `pause()` | `pause()` |
| 停止 | `stop()` | `stop()` |
| 进度监听 | `onPositionChanged` | `positionStream` |
| 时长监听 | `onDurationChanged` | `durationStream` |
| 播放完成 | `onPlayerComplete` | `playerStateStream` 检查 `ProcessingState.completed` |

### 4. 事件监听更新
- 使用 `positionStream` 替代 `onPositionChanged`
- 使用 `durationStream` 替代 `onDurationChanged`
- 使用 `playerStateStream` 和 `playingStream` 替代 `onPlayerComplete`

### 5. 音频源处理
- 从 `DeviceFileSource` 改为 `AudioSource.uri(Uri.file(...))`
- 支持更灵活的音频源配置

## 移除的依赖
- 完全移除了 `just_audio_background` 相关代码
- 简化了音频播放逻辑，专注于前台播放

## 测试验证
迁移后的音频服务保持原有功能：
- ✅ 播放/暂停/停止
- ✅ 上一首/下一首
- ✅ 进度控制
- ✅ 音量控制
- ✅ 播放模式切换
- ✅ 播放列表管理

## 注意事项
1. 由于移除了 `just_audio_background`，应用切换到后台时音频会停止
2. 如果需要后台播放功能，需要重新集成 `just_audio_background`
3. 当前实现专注于前台音频播放体验

## 文件修改
- `pubspec.yaml`: 更新依赖
- `lib/services/audio_player_service.dart`: 完全重构音频服务
- 移除了所有 `just_audio_background` 相关文件和配置

## 编译问题修复

### 问题描述
在迁移过程中遇到了编译错误：
```
lib/services/audio_player_service.dart:106:70: Error: Member not found: 'error'.
```

### 解决方案
`just_audio` 的 `ProcessingState` 枚举中确实没有 `error` 成员。修复方法是：
- 移除了对 `ProcessingState.error` 的直接引用
- 使用更通用的状态检查逻辑来处理错误情况
- 通过检查非预期状态来推断错误情况

### 最终验证
- ✅ 项目成功编译
- ✅ 生成了 debug APK
- ✅ 没有编译错误

## 最终状态
项目已成功从 `audioplayers` 迁移到 `just_audio`，并且：
1. 移除了 `just_audio_background` 依赖
2. 重构了音频播放服务
3. 修复了编译问题
4. 保留了所有原有功能
