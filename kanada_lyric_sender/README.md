# Lyric-Getter-API

#### 这是Lyric Getter 的API，用于收发歌词

---

### 使用方法

### 1. 项目 Gradle 添加 JitPack 依赖

```groovy
allprojects {
    repositories {
        // ...
        maven { url 'https://jitpack.io' }
    }
}
```

or

```kotlin
allprojects {
    repositories {
        // ...
        maven("https://jitpack.io")
    }
}
```

### 2. 要使用的模块下添加 Lyric-Getter-API 依赖

最新版本⬇️⬇️⬇️

[![](https://jitpack.io/v/xiaowine/Lyric-Getter-Api.svg)](https://jitpack.io/#xiaowine/Lyric-Getter-Api/)

```groovy
dependencies {
    // ...
    implementation 'com.github.xiaowine:Lyric-Getter-Api:<VERSION>'
}
```

or

```kotlin
dependencies {
    // ...
    implementation("com.github.xiaowine:Lyric-Getter-Api:<VERSION>")
}
```

### 3.具体使用请见[Demo](/app/src/main/java/cn/lyric/getter/api/demo/MainActivity.kt)  或查看[API](/Api)
---

## 注意 若开启了 proguard 请保证 API 类不被混淆:

```shrinker_config
-keep class cn.lyric.getter.api.data.*{*;}
-keep class cn.lyric.getter.api.API{*;}
```

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=xiaowine/Lyric-Getter-Api&type=Timeline)](https://star-history.com/#xiaowine/Lyric-Getter-Api&Timeline)
