package io.github.xiaocaoooo.kanade_audio_plugin

import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.MediaStore
import androidx.annotation.NonNull
import org.json.JSONArray
import org.json.JSONObject

/**
 * 媒体服务类，用于处理设备媒体库的访问
 * 提供获取歌曲列表和专辑封面的功能
 */
class MediaService(private val context: Context) {

    /**
     * 获取设备中所有的音乐文件
     * @return 包含所有歌曲信息的JSON字符串
     */
    fun getAllSongs(): String {
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

            return songsList.toString()
        } catch (e: Exception) {
            throw Exception("Failed to load songs: ${e.message}")
        }
    }

    /**
     * 根据专辑ID获取专辑封面
     * @param albumId 专辑ID
     * @return 专辑封面的字节数组，如果没有找到返回null
     */
    fun getAlbumArt(albumId: String): ByteArray? {
        try {
            val albumIdLong = albumId.toLong()
            val artworkUri = ContentUris.withAppendedId(
                Uri.parse("content://media/external/audio/albumart"),
                albumIdLong
            )
            
            context.contentResolver.openInputStream(artworkUri)?.use { inputStream ->
                return inputStream.readBytes()
            } ?: return null
        } catch (e: Exception) {
            return null
        }
    }
}