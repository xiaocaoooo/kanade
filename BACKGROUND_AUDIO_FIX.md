# 后台音频播放修复说明

## 问题描述
在播放页面点击返回按钮回到首页后，音频内容停止播放。

## 解决方案

### 1. 音频服务单例化
- 将 `AudioPlayerService` 改为全局单例模式
- 在 `MainNavigation` 中创建并管理音频服务实例
- 所有页面共享同一个音频服务实例

### 2. 页面生命周期管理
- 修改 `PlayerPage` 不再在 `dispose` 中释放音频服务
- 仅释放通知服务资源
- 音频服务在应用生命周期内保持活跃

### 3. 依赖注入优化
- 使用 `ChangeNotifierProvider.value` 提供全局音频服务
- 确保所有页面都能访问同一个音频服务实例

### 4. 权限配置
- 添加后台音频播放所需权限：
  - `android.permission.WAKE_LOCK`
  - `android.permission.FOREGROUND_SERVICE`
  - `android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK`

## 文件修改

### 主要修改文件：
1. `lib/main.dart` - 改为使用全局音频服务
2. `lib/pages/player_page.dart` - 移除音频服务销毁逻辑
3. `android/app/src/main/AndroidManifest.xml` - 添加后台播放权限

### 次要修改：
- 修复了一些代码警告和未使用的import

## 测试方法
1. 启动应用
2. 播放任意歌曲
3. 进入播放页面
4. 点击返回按钮回到首页
5. 验证音频是否继续播放

## 设备兼容性
已在13pro设备上测试通过。
