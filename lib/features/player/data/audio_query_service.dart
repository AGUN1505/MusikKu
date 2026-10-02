import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:musikku/features/player/domain/models/song.dart';

class AudioQueryService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  OnAudioQuery get audioQuery => _audioQuery;

  /// Request permissions for reading audio on Android / iOS
  Future<bool> requestPermission() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        // Android 13+ (API 33+) uses READ_MEDIA_AUDIO
        final audioStatus = await Permission.audio.status;
        if (audioStatus.isGranted) return true;

        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) return true;

        // Request audio or storage
        final requestedAudio = await Permission.audio.request();
        if (requestedAudio.isGranted) return true;

        final requestedStorage = await Permission.storage.request();
        if (requestedStorage.isGranted) return true;

        // Fallback to on_audio_query internal permission request
        return await _audioQuery.permissionsRequest();
      } else if (Platform.isIOS) {
        final status = await Permission.mediaLibrary.request();
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting audio permissions: $e');
    }
    return false;
  }

  /// Query all offline songs from device MediaStore
  Future<List<Song>> queryOfflineSongs() async {
    try {
      final hasPerm = await requestPermission();
      if (!hasPerm) {
        debugPrint('Storage/Audio permission was denied');
      }

      final songModels = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // Filter songs with duration > 5 seconds to exclude voice notes/ringtone snippets
      final validSongs = songModels
          .where((m) => (m.duration ?? 0) > 5000)
          .map((m) => Song.fromSongModel(m))
          .toList();

      return validSongs;
    } catch (e) {
      debugPrint('Error querying offline songs: $e');
      return [];
    }
  }

  /// Groups songs into folders based on their folderName
  Map<String, List<Song>> groupSongsByFolder(List<Song> songs) {
    final Map<String, List<Song>> folderMap = {};
    for (final song in songs) {
      final key = song.folderName.isNotEmpty ? song.folderName : 'Penyimpanan';
      folderMap.putIfAbsent(key, () => []).add(song);
    }
    return folderMap;
  }

  /// Let user manually pick a folder from phone storage and scan music inside it
  Future<List<Song>> pickAndScanFolder() async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory == null || selectedDirectory.isEmpty) {
        return [];
      }

      return await scanDirectoryForAudio(selectedDirectory);
    } catch (e) {
      debugPrint('Error picking and scanning folder: $e');
      return [];
    }
  }

  /// Recursively scan a directory path for audio files (.mp3, .m4a, .wav, .flac, .aac, .ogg)
  Future<List<Song>> scanDirectoryForAudio(String dirPath) async {
    final List<Song> foundSongs = [];
    final dir = Directory(dirPath);

    if (!await dir.exists()) return foundSongs;

    final supportedExtensions = ['.mp3', '.m4a', '.wav', '.flac', '.aac', '.ogg', '.opus'];

    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final pathLower = entity.path.toLowerCase();
          final isAudio = supportedExtensions.any((ext) => pathLower.endsWith(ext));
          if (isAudio) {
            foundSongs.add(Song.fromFilePath(entity.path));
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory $dirPath: $e');
    }

    return foundSongs;
  }
}
