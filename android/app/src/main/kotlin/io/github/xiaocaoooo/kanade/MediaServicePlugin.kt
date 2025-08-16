package io.github.xiaocaoooo.kanade

import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONArray
import org.json.JSONObject

class MediaServicePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "media_service")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getAllSongs" -> getAllSongs(result)
            "getAlbumArt" -> {
                val albumId = call.argument<String>("albumId")
                if (albumId != null) {
                    getAlbumArt(albumId, result)
                } else {
                    result.error("INVALID_ARGUMENT", "albumId is required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun getAllSongs(result: Result) {
        try {
            val songsList = JSONArray()
            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.SIZE,
                MediaStore.Audio.Media.ALBUM_ID,
                MediaStore.Audio.Media.DATE_ADDED,
                MediaStore.Audio.Media.DATE_MODIFIED
            )

            val cursor: Cursor? = context.contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                MediaStore.Audio.Media.IS_MUSIC + " != 0",
                null,
                MediaStore.Audio.Media.TITLE + " ASC"
            )

            cursor?.use {
                val idColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val titleColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
                val artistColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
                val albumColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
                val durationColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                val pathColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
                val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
                val albumIdColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
                val dateAddedColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
                val dateModifiedColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)

                while (it.moveToNext()) {
                    val song = JSONObject().apply {
                        put("id", it.getLong(idColumn).toString())
                        put("title", it.getString(titleColumn))
                        put("artist", it.getString(artistColumn))
                        put("album", it.getString(albumColumn))
                        put("duration", it.getLong(durationColumn))
                        put("path", it.getString(pathColumn))
                        put("size", it.getLong(sizeColumn))
                        put("albumId", it.getLong(albumIdColumn).toString())
                        put("dateAdded", it.getLong(dateAddedColumn) * 1000)
                        put("dateModified", it.getLong(dateModifiedColumn) * 1000)
                    }
                    songsList.put(song)
                }
            }

            result.success(songsList.toString())
        } catch (e: Exception) {
            result.error("MEDIA_ERROR", "Failed to load songs: ${e.message}", null)
        }
    }

    private fun getAlbumArt(albumId: String, result: Result) {
        try {
            val albumIdLong = albumId.toLong()
            val artworkUri = ContentUris.withAppendedId(
                Uri.parse("content://media/external/audio/albumart"),
                albumIdLong
            )
            
            context.contentResolver.openInputStream(artworkUri)?.use { inputStream ->
                val bytes = inputStream.readBytes()
                result.success(bytes)
            } ?: result.success(null)
        } catch (e: Exception) {
            result.error("ALBUM_ART_ERROR", "Failed to load album art: ${e.message}", null)
        }
    }
}