# GitHub Actions 自动构建工作流

## 简介

这个工作流会在每次代码推送到任意分支时自动构建Debug版本的APK文件。

## 功能特点

- ✅ 自动构建Debug APK
- ✅ 支持所有分支的push和PR
- ✅ 缓存依赖以加快构建速度
- ✅ 代码格式检查
- ✅ 静态代码分析
- ✅ 自动测试（如果存在）
- ✅ 构建产物自动上传
- ✅ 详细的构建日志

## 使用方法

### 1. 推送到任意分支

```bash
git add .
git commit -m "你的提交信息"
git push origin 你的分支名
```

### 2. 查看构建状态

1. 打开GitHub仓库页面
2. 点击"Actions"标签
3. 查看最新的工作流运行状态

### 3. 下载构建产物

构建成功后，可以在以下位置下载APK文件：
- 进入Actions页面
- 点击对应的工作流运行
- 在"Artifacts"部分下载debug-apk-{commit-sha}

## 工作流步骤

1. **Checkout code**: 检出最新代码
2. **Setup Flutter**: 安装和配置Flutter环境
3. **Get dependencies**: 获取项目依赖
4. **Cache dependencies**: 缓存依赖以加速后续构建
5. **Flutter doctor**: 检查Flutter环境配置
6. **Check formatting**: 检查代码格式
7. **Analyze code**: 运行静态代码分析
8. **Run tests**: 运行测试（可选）
9. **Build Debug APK**: 构建Debug版本APK
10. **Upload artifacts**: 上传构建产物和日志

## 自定义配置

### 修改Flutter版本

编辑 `.github/workflows/build_debug.yml` 文件，修改 `flutter-version`：

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '你想要的版本号'
    channel: 'stable'
```

### 修改触发条件

编辑 `.github/workflows/build_debug.yml` 文件，修改 `on` 部分：

```yaml
on:
  push:
    branches: [ main, develop ]  # 只在main和develop分支触发
  pull_request:
    branches: [ main ]
```

### 添加环境变量

如果需要添加环境变量，可以在工作流中添加：

```yaml
env:
  FLUTTER_VERSION: '3.27.0'
  JAVA_VERSION: '17'
```

## 常见问题

### 构建失败怎么办？

1. 查看Actions页面的详细日志
2. 检查错误信息
3. 修复本地问题后重新push

### 构建太慢怎么办？

工作流已经启用了缓存机制，后续构建会更快。

### 如何跳过某些检查？

可以临时修改工作流文件，注释掉不需要的步骤：

```yaml
# - name: Check formatting
#   run: flutter format --set-exit-if-changed .
```

## 相关链接

- [GitHub Actions文档](https://docs.github.com/en/actions)
- [Flutter官方文档](https://flutter.dev/docs)