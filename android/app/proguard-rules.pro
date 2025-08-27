# Lyric-Getter-API 相关类不被混淆
-keep class cn.lyric.getter.api.data.*{*;}
-keep class cn.lyric.getter.api.API{*;}

# Flutter 相关类不被混淆
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }