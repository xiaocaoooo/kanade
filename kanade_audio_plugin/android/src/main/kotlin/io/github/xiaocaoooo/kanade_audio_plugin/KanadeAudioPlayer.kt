package io.github.xiaocaoooo.kanade_audio_plugin

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.util.Log
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.MediaMetadata
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream

class KanadeAudioPlayer(private val context: Context) {
    private var player: ExoPlayer? = null
    private var playlist: MutableList<MutableMap<String, Any?>> = mutableListOf()
    private var currentIndex: Int = 0
    private var playMode: Int = 0 // 0: sequence, 1: repeatOne, 2: repeatAll, 3: shuffle
    private var volume: Float = 1.0f

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    init {
        initializePlayer()
    }

    private fun initializePlayer() {
        player = ExoPlayer.Builder(context).build().apply {
            addListener(object : Player.Listener {
                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    super.onIsPlayingChanged(isPlaying)
                    notifyPlayerStateChanged()
                }

                override fun onPlaybackStateChanged(playbackState: Int) {
                    super.onPlaybackStateChanged(playbackState)
                    when (playbackState) {
                        Player.STATE_ENDED -> onPlayComplete()
                        Player.STATE_IDLE -> notifyPlayerStateChanged()
                        Player.STATE_BUFFERING -> notifyPlayerStateChanged()
                        Player.STATE_READY -> notifyPlayerStateChanged()
                    }
                }

                override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                    super.onMediaItemTransition(mediaItem, reason)
                    mediaItem?.let {
                        currentIndex = playlist.indexOfFirst { item ->
                            item["id"] == it.mediaId.toIntOrNull()
                        }
                        notifyCurrentSongChanged()
                    }
                }
            })
        }
    }

    fun setPlaylist(songs: List<Map<String, Any?>>, initialIndex: Int) {
        playlist.clear()
        playlist.addAll(songs.map { it.toMutableMap() })
        currentIndex = initialIndex.coerceIn(0, playlist.size - 1)
        
        val mediaItems = playlist.map { song ->
            MediaItem.Builder()
                .setMediaId(song["id"].toString())
                .setUri(Uri.parse(song["path"] as String))
                .setMediaMetadata(
                    MediaMetadata.Builder()
                        .setTitle(song["title"] as String)
                        .setArtist(song["artist"] as? String ?: "Unknown Artist")
                        .setAlbumTitle(song["album"] as? String ?: "Unknown Album")
                        .build()
                )
                .build()
        }
        
        player?.setMediaItems(mediaItems)
    }

    fun playSong(song: Map<String, Any?>) {
        val index = playlist.indexOfFirst { it["id"] == song["id"] }
        if (index != -1) {
            currentIndex = index
            player?.seekTo(index, 0)
            play()
        }
    }

    fun play() {
        if (playlist.isEmpty()) return
        
        if (player?.currentMediaItem == null && playlist.isNotEmpty()) {
            val mediaItem = MediaItem.Builder()
                .setMediaId(playlist[currentIndex]["id"].toString())
                .setUri(Uri.parse(playlist[currentIndex]["path"] as String))
                .setMediaMetadata(
                    MediaMetadata.Builder()
                        .setTitle(playlist[currentIndex]["title"] as String)
                        .setArtist(playlist[currentIndex]["artist"] as? String ?: "Unknown Artist")
                        .setAlbumTitle(playlist[currentIndex]["album"] as? String ?: "Unknown Album")
                        .build()
                )
                .build()
            
            player?.setMediaItem(mediaItem)
        }
        
        player?.play()
    }

    fun pause() {
        player?.pause()
    }

    fun stop() {
        player?.stop()
        player?.seekTo(0)
    }

    fun previous() {
        if (playlist.isEmpty()) return
        
        when (playMode) {
            3 -> { // shuffle
                currentIndex = (0 until playlist.size).random()
            }
            else -> {
                currentIndex = if (currentIndex > 0) currentIndex - 1 else playlist.size - 1
            }
        }
        
        player?.seekTo(currentIndex, 0)
        if (player?.isPlaying == false) play()
    }

    fun next() {
        if (playlist.isEmpty()) return
        
        when (playMode) {
            1 -> { // repeatOne
                // 重新播放当前歌曲
                player?.seekTo(0)
            }
            3 -> { // shuffle
                currentIndex = (0 until playlist.size).random()
                player?.seekTo(currentIndex, 0)
            }
            else -> {
                currentIndex = if (currentIndex < playlist.size - 1) currentIndex + 1 else 0
                player?.seekTo(currentIndex, 0)
            }
        }
        
        if (player?.isPlaying == false) play()
    }

    fun seek(position: Int) {
        player?.seekTo(position.toLong())
    }

    fun setVolume(volume: Double) {
        this.volume = volume.toFloat()
        player?.volume = this.volume
    }

    fun togglePlayMode() {
        playMode = (playMode + 1) % 4
    }

    fun getPlayerState(): Int {
        return when (player?.playbackState) {
            Player.STATE_IDLE -> 0
            Player.STATE_BUFFERING -> 3
            Player.STATE_READY -> if (player?.isPlaying == true) 1 else 2
            Player.STATE_ENDED -> 0
            else -> 0
        }
    }

    fun getCurrentSong(): Map<String, Any?>? {
        return if (currentIndex in 0 until playlist.size) playlist[currentIndex] else null
    }

    fun getPosition(): Int {
        return player?.currentPosition?.toInt() ?: 0
    }

    fun getDuration(): Int {
        return player?.duration?.toInt() ?: 0
    }

    fun getVolume(): Double {
        return volume.toDouble()
    }

    fun getPlayMode(): Int {
        return playMode
    }

    fun getPlaylist(): List<Map<String, Any?>> {
        return playlist
    }

    fun getAlbumArt(songId: Int): ByteArray? {
        val song = playlist.find { it["id"] == songId } ?: return null
        val filePath = song["path"] as? String ?: return null
        
        return try {
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(filePath)
            val art = retriever.embeddedPicture
            retriever.release()
            art
        } catch (e: Exception) {
            Log.e("KanadeAudioPlayer", "Error getting album art", e)
            null
        }
    }

    fun loadAlbumArt(songId: Int): ByteArray? {
        return getAlbumArt(songId)
    }

    fun dispose() {
        player?.release()
        player = null
        scope.cancel()
    }

    private fun onPlayComplete() {
        when (playMode) {
            1 -> { // repeatOne
                player?.seekTo(0)
                play()
            }
            2, 3 -> { // repeatAll, shuffle
                next()
            }
            else -> { // sequence
                if (currentIndex < playlist.size - 1) {
                    next()
                } else {
                    stop()
                }
            }
        }
    }

    private fun notifyPlayerStateChanged() {
        // 将通过事件通道通知 Flutter
    }

    private fun notifyCurrentSongChanged() {
        // 将通过事件通道通知 Flutter
    }
}