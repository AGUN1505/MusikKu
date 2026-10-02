import 'package:on_audio_query/on_audio_query.dart';

class Song {
  final String id;
  final int? audioQueryId;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String uriOrPath;
  final String folderName;
  final String folderPath;
  final bool isFavorite;

  const Song({
    required this.id,
    this.audioQueryId,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.uriOrPath,
    this.folderName = 'Musik',
    this.folderPath = '',
    this.isFavorite = false,
  });

  String get durationString {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  factory Song.fromSongModel(SongModel model) {
    // Determine folder name from data (file path)
    String folder = 'Penyimpanan Internal';
    String dirPath = '';
    if (model.data.isNotEmpty) {
      final normalized = model.data.replaceAll(r'\', '/');
      final parts = normalized.split('/');
      if (parts.length >= 2) {
        folder = parts[parts.length - 2];
        dirPath = parts.sublist(0, parts.length - 1).join('/');
      }
    }

    return Song(
      id: model.id.toString(),
      audioQueryId: model.id,
      title: model.title.isNotEmpty ? model.title : (model.displayNameWOExt.isNotEmpty ? model.displayNameWOExt : 'Tanpa Judul'),
      artist: (model.artist != null && model.artist != '<unknown>') ? model.artist! : 'Artis Tidak Dikenal',
      album: (model.album != null && model.album != '<unknown>') ? model.album! : 'Album',
      duration: Duration(milliseconds: model.duration ?? 0),
      uriOrPath: model.uri ?? model.data,
      folderName: folder,
      folderPath: dirPath,
    );
  }

  factory Song.fromFilePath(String filePath) {
    final normalized = filePath.replaceAll(r'\', '/');
    final filename = normalized.split('/').last;
    final nameWithoutExt = filename.contains('.') 
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    
    final parts = normalized.split('/');
    final folder = parts.length >= 2 ? parts[parts.length - 2] : 'Folder';
    final dirPath = parts.length >= 2 ? parts.sublist(0, parts.length - 1).join('/') : '';

    return Song(
      id: filePath.hashCode.toString(),
      title: nameWithoutExt,
      artist: 'File Lokal',
      album: folder,
      duration: Duration.zero,
      uriOrPath: filePath,
      folderName: folder,
      folderPath: dirPath,
    );
  }

  Song copyWith({
    String? id,
    int? audioQueryId,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? uriOrPath,
    String? folderName,
    String? folderPath,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      audioQueryId: audioQueryId ?? this.audioQueryId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      uriOrPath: uriOrPath ?? this.uriOrPath,
      folderName: folderName ?? this.folderName,
      folderPath: folderPath ?? this.folderPath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
