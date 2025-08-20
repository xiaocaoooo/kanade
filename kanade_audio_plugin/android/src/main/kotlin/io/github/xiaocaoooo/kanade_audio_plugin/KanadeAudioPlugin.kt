package io.github.xiaocaoooo.kanade_audio_plugin

import android.content.Context
import android.content.Intent
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import androidx.media3.common.util.UnstableApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import kotlinx.coroutines.*
import android.util.Log

/** KanadeAudioPlugin */
class KanadeAudioPlugin: FlutterPlugin, MethodCallHandler, StreamHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var playerStateChannel: EventChannel
    private lateinit var positionChannel: EventChannel
    private lateinit var currentSongChannel: EventChannel
    
    private var audioPlayer: KanadeAudioPlayer? = null
    private var playerStateSink: EventSink? = null
    private var positionSink: EventSink? = null
    private var currentSongSink: EventSink? = null
    private lateinit var mediaService: MediaService
    
    private var positionUpdateJob: kotlinx.coroutines.Job? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "kanade_audio_plugin")
        methodChannel.setMethodCallHandler(this)
        
        playerStateChannel = EventChannel(flutterPluginBinding.binaryMessenger, "kanade_audio_plugin/player_state")
        positionChannel = EventChannel(flutterPluginBinding.binaryMessenger, "kanade_audio_plugin/position")
        currentSongChannel = EventChannel(flutterPluginBinding.binaryMessenger, "kanade_audio_plugin/current_song")
        
        playerStateChannel.setStreamHandler(this)
        positionChannel.setStreamHandler(this)
        currentSongChannel.setStreamHandler(this)
        
        audioPlayer = KanadeAudioPlayer(context)
        mediaService = MediaService(context)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "getPlatformVersion" -> {
                    result.success("Android ${android.os.Build.VERSION.RELEASE}")
                }
                "initialize" -> {
                    result.success(null)
                }
                "setPlaylist" -> {
                    val songs = call.argument<List<Map<String, Any?>>>("songs") ?: emptyList()
                    val initialIndex = call.argument<Int>("initialIndex") ?: 0
                    audioPlayer?.setPlaylist(songs, initialIndex)
                    result.success(null)
                }
                "playSong" -> {
                    val song = call.argument<Map<String, Any?>>("song") ?: emptyMap()
                    audioPlayer?.playSong(song)
                    result.success(null)
                }
                "play" -> {
                    audioPlayer?.play()
                    result.success(null)
                }
                "pause" -> {
                    audioPlayer?.pause()
                    result.success(null)
                }
                "stop" -> {
                    audioPlayer?.stop()
                    result.success(null)
                }
                "previous" -> {
                    audioPlayer?.previous()
                    result.success(null)
                }
                "next" -> {
                    audioPlayer?.next()
                    result.success(null)
                }
                "seek" -> {
                    val position = call.argument<Int>("position") ?: 0
                    audioPlayer?.seek(position)
                    result.success(null)
                }
                "setVolume" -> {
                    val volume = call.argument<Double>("volume") ?: 1.0
                    audioPlayer?.setVolume(volume)
                    result.success(null)
                }
                "togglePlayMode" -> {
                    audioPlayer?.togglePlayMode()
                    result.success(null)
                }
                "getPlayerState" -> {
                    result.success(audioPlayer?.getPlayerState())
                }
                "getCurrentSong" -> {
                    result.success(audioPlayer?.getCurrentSong())
                }
                "getPosition" -> {
                    result.success(audioPlayer?.getPosition())
                }
                "getDuration" -> {
                    result.success(audioPlayer?.getDuration())
                }
                "getVolume" -> {
                    result.success(audioPlayer?.getVolume())
                }
                "getPlayMode" -> {
                    result.success(audioPlayer?.getPlayMode())
                }
                "getPlaylist" -> {
                    result.success(audioPlayer?.getPlaylist())
                }
                "getAlbumArt" -> {
                    val songId = call.argument<Int>("songId") ?: 0
                    val art = audioPlayer?.getAlbumArt(songId)
                    result.success(art)
                }
                "loadAlbumArt" -> {
                    val songId = call.argument<Int>("songId") ?: 0
                    val art = audioPlayer?.loadAlbumArt(songId)
                    result.success(art)
                }
                "getAllSongs" -> {
                    try {
                        val songsJson = mediaService.getAllSongs()
                        // 将JSON字符串解析为List<Map<String, Any>>
                        val jsonArray = org.json.JSONArray(songsJson)
                        val songsList = mutableListOf<Map<String, Any>>()
                        
                        for (i in 0 until jsonArray.length()) {
                            val jsonObject = jsonArray.getJSONObject(i)
                            val songMap = mutableMapOf<String, Any>()
                            
                            // 转换所有字段，确保类型正确匹配Dart端的期望
                            songMap["id"] = jsonObject.getString("id").toLong()
                            songMap["title"] = jsonObject.getString("title")
                            songMap["artist"] = jsonObject.getString("artist")
                            songMap["album"] = jsonObject.getString("album")
                            songMap["duration"] = jsonObject.getLong("duration").toInt()  // 转换为Int以匹配Dart端的int类型
                            songMap["path"] = jsonObject.getString("path")
                            songMap["size"] = jsonObject.getLong("size").toInt()  // 转换为Int
                            songMap["albumId"] = jsonObject.getString("albumId").toLong()
                            songMap["dateAdded"] = jsonObject.getLong("dateAdded").toInt()  // 转换为Int
                            songMap["dateModified"] = jsonObject.getLong("dateModified").toInt()  // 转换为Int
                            
                            songsList.add(songMap)
                        }
                        
                        result.success(songsList)
                    } catch (e: Exception) {
                        result.error("MEDIA_ERROR", "Failed to load songs: ${e.message}", null)
                    }
                }
                "getAlbumArtByAlbumId" -> {
                    val albumId = call.argument<String>("albumId") ?: call.argument<Int>("albumId")?.toString()
                    if (albumId != null) {
                        try {
                            Log.d("KanadeAudioPlugin", "开始获取专辑封面: albumId=$albumId")
                            val albumArt = mediaService.getAlbumArt(albumId)
                            Log.d("KanadeAudioPlugin", "获取专辑封面结果: albumId=$albumId, 结果=${if (albumArt != null) "成功(${albumArt.size}字节)" else "失败"}")
                            result.success(albumArt)
                        } catch (e: Exception) {
                            Log.d("KanadeAudioPlugin", "获取专辑封面失败: albumId=$albumId, error=${e.message}")
                            result.success(null) // 返回null而不是错误，避免应用崩溃
                        }
                    } else {
                        Log.d("KanadeAudioPlugin", "专辑ID为空")
                        result.success(null) // 返回null而不是错误
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, e.stackTraceToString())
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        playerStateChannel.setStreamHandler(null)
        positionChannel.setStreamHandler(null)
        currentSongChannel.setStreamHandler(null)
        
        audioPlayer?.dispose()
        audioPlayer = null
        
        positionUpdateJob?.cancel()
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        when (arguments) {
            "player_state" -> {
                playerStateSink = events
                startPositionUpdates()
            }
            "position" -> {
                positionSink = events
                startPositionUpdates()
            }
            "current_song" -> {
                currentSongSink = events
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        when (arguments) {
            "player_state" -> {
                playerStateSink = null
                stopPositionUpdates()
            }
            "position" -> {
                positionSink = null
                stopPositionUpdates()
            }
            "current_song" -> {
                currentSongSink = null
            }
        }
    }

    private fun startPositionUpdates() {
        if (positionUpdateJob != null) return
        
        positionUpdateJob = kotlinx.coroutines.GlobalScope.launch {
            while (isActive) {
                try {
                    val position = audioPlayer?.getPosition() ?: 0
                    val duration = audioPlayer?.getDuration() ?: 0
                    val state = audioPlayer?.getPlayerState() ?: 0
                    
                    val data = mapOf(
                        "position" to position,
                        "duration" to duration,
                        "state" to state
                    )
                    
                    positionSink?.success(data)
                    playerStateSink?.success(data)
                    
                    kotlinx.coroutines.delay(1000)
                } catch (e: Exception) {
                    positionSink?.error("UPDATE_ERROR", e.message, null)
                    playerStateSink?.error("UPDATE_ERROR", e.message, null)
                    break
                }
            }
        }
    }

    private fun stopPositionUpdates() {
        positionUpdateJob?.cancel()
        positionUpdateJob = null
    }
}
