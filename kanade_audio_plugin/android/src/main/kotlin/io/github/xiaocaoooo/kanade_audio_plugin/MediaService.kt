package io.github.xiaocaoooo.kanade_audio_plugin

import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.NonNull
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileNotFoundException

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
            throw Exception("Failed to load songs: " + e.message)
        }
    }

    /**
     * 根据专辑ID获取专辑封面
     * @param albumId 专辑ID
     * @return 专辑封面的字节数组，如果没有找到返回null
     */
    fun getAlbumArt(albumId: String): ByteArray? {
        try {
            val albumIdLong = albumId.toLongOrNull() ?: return null
            Log.d("MediaService", "开始获取专辑封面: albumId=" + albumId)
            
            // 方法1: 使用MediaStore查询专辑封面 - 标准方法
            val albumArtUri = ContentUris.withAppendedId(
                Uri.parse("content://media/external/audio/albumart"),
                albumIdLong
            )
            
            Log.d("MediaService", "尝试方法1 - URI查询: " + albumArtUri)
            try {
                context.contentResolver.openInputStream(albumArtUri)?.use { inputStream ->
                    val bytes = inputStream.readBytes()
                    Log.d("MediaService", "方法1成功: albumId=" + albumId + ", 大小=" + bytes.size + "字节")
                    if (bytes.isNotEmpty()) {
                        return bytes
                    }
                }
            } catch (e: Exception) {
                Log.d("MediaService", "方法1失败: albumId=" + albumId + ", error=" + e.message)
            }
            
            // 方法2: 使用MediaStore查询专辑信息
            val projection = arrayOf(
                MediaStore.Audio.Albums.ALBUM_ART,
                MediaStore.Audio.Albums.ALBUM
            )
            
            Log.d("MediaService", "尝试方法2 - 专辑信息查询: albumId=" + albumId)
            val cursor = context.contentResolver.query(
                MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                projection,
                MediaStore.Audio.Albums._ID + " = ?",
                arrayOf(albumId),
                null
            )
            
            cursor?.use {
                if (it.moveToFirst()) {
                    val albumArtColumn = it.getColumnIndex(MediaStore.Audio.Albums.ALBUM_ART)
                    if (albumArtColumn != -1) {
                        val albumArtPath = it.getString(albumArtColumn)
                        Log.d("MediaService", "方法2找到专辑路径: albumId=" + albumId + ", path=" + albumArtPath)
                        if (!albumArtPath.isNullOrEmpty()) {
                            val file = File(albumArtPath)
                            if (file.exists() && file.length() > 0) {
                                file.inputStream().use { inputStream ->
                                    val bytes = inputStream.readBytes()
                                    Log.d("MediaService", "方法2成功: albumId=" + albumId + ", 大小=" + bytes.size + "字节")
                                    return bytes
                                }
                            } else {
                                Log.d("MediaService", "方法2文件不存在或为空: albumId=" + albumId + ", path=" + albumArtPath)
                            }
                        } else {
                            Log.d("MediaService", "方法2专辑路径为空: albumId=" + albumId)
                        }
                    } else {
                        Log.d("MediaService", "方法2专辑封面列不存在: albumId=" + albumId)
                    }
                } else {
                    Log.d("MediaService", "方法2未找到专辑: albumId=" + albumId)
                }
                return null // 添加显式的返回值
            }
            
            // 方法3: 尝试从歌曲文件中提取嵌入封面
            Log.d("MediaService", "尝试方法3 - 嵌入封面提取: albumId=" + albumId)
            val embeddedArt = tryExtractEmbeddedArt(albumIdLong)
            if (embeddedArt != null) {
                Log.d("MediaService", "方法3成功: albumId=" + albumId + ", 大小=" + embeddedArt.size + "字节")
            } else {
                Log.d("MediaService", "所有方法失败: albumId=" + albumId)
            }
            return embeddedArt
            
        } catch (e: Exception) {
            Log.d("MediaService", "获取专辑封面异常: albumId=" + albumId + ", error=" + e.message)
            return null
        }
    }
    
    /**
     * 从歌曲文件中提取嵌入的专辑封面
     * @param albumId 专辑ID
     * @return 嵌入封面的字节数组，如果没有找到返回null
     */
    private fun tryExtractEmbeddedArt(albumId: Long): ByteArray? {
        try {
            Log.d("MediaService", "开始提取嵌入封面: albumId=" + albumId)
            
            // 查找该专辑下的第一首歌曲
            val projection = arrayOf(
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.ALBUM_ID
            )
            
            val cursor = context.contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                MediaStore.Audio.Media.ALBUM_ID + " = ?",
                arrayOf(albumId.toString()),
                null
            )

            cursor?.use {
                Log.d("MediaService", "找到专辑下的歌曲数量: albumId=" + albumId + ", count=" + it.count)
                if (it.moveToFirst()) {
                    val pathColumn = it.getColumnIndex(MediaStore.Audio.Media.DATA)
                    if (pathColumn != -1) {
                        val filePath = it.getString(pathColumn)
                        Log.d("MediaService", "提取嵌入封面 - 歌曲路径: albumId=" + albumId + ", path=" + filePath)
                        
                        if (!filePath.isNullOrEmpty()) {
                            val file = File(filePath)
                            if (file.exists()) {
                                Log.d("MediaService", "提取嵌入封面 - 文件存在: albumId=" + albumId + ", size=" + file.length())
                                
                                // 使用MediaMetadataRetriever提取嵌入封面
                                val retriever = android.media.MediaMetadataRetriever()
                                try {
                                    retriever.setDataSource(filePath)
                                    val embeddedArt = retriever.embeddedPicture
                                    Log.d("MediaService", "提取嵌入封面结果: albumId=" + albumId + ", 封面存在=" + (embeddedArt != null))
                                    
                                    if (embeddedArt != null && embeddedArt.isNotEmpty()) {
                                        Log.d("MediaService", "提取嵌入封面成功: albumId=" + albumId + ", 大小=" + embeddedArt.size + "字节")
                                        return embeddedArt
                                    } else {
                                        Log.d("MediaService", "提取嵌入封面 - 文件中没有嵌入封面: albumId=" + albumId)
                                    }
                                } catch (e: Exception) {
                                    Log.d("MediaService", "提取嵌入封面异常: albumId=" + albumId + ", error=" + e.message)
                                } finally {
                                    retriever.release()
                                }
                            } else {
                                Log.d("MediaService", "提取嵌入封面 - 文件不存在: albumId=" + albumId + ", path=" + filePath)
                            }
                        } else {
                            Log.d("MediaService", "提取嵌入封面 - 文件路径为空: albumId=" + albumId)
                        }
                    } else {
                        Log.d("MediaService", "提取嵌入封面 - DATA列索引无效: albumId=" + albumId)
                    }
                } else {
                    Log.d("MediaService", "提取嵌入封面 - 未找到专辑下的歌曲: albumId=" + albumId)
                }
                return null // 添加显式的返回值
            }
            
            Log.d("MediaService", "提取嵌入封面 - 所有尝试失败: albumId=" + albumId)
            return null
        } catch (e: Exception) {
            Log.d("MediaService", "提取嵌入封面 - 异常: albumId=" + albumId + ", error=" + e.message)
            return null
        }
    }
}