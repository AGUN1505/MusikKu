class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? coverUrl;
  final bool isFavorite;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.coverUrl,
    this.isFavorite = false,
  });

  String get durationString {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? coverUrl,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  static List<Song> get sampleSongs => const [
        Song(
          id: '1',
          title: 'Senja di Jakarta',
          artist: 'Nusantara Beats',
          album: 'Kota Kenangan',
          duration: Duration(minutes: 3, seconds: 45),
        ),
        Song(
          id: '2',
          title: 'Hujan Bulan Juni',
          artist: 'Acoustic Soul',
          album: 'Puisi Suara',
          duration: Duration(minutes: 4, seconds: 12),
        ),
        Song(
          id: '3',
          title: 'Midnight Drive',
          artist: 'Synthwave Boy',
          album: 'Neon Lights',
          duration: Duration(minutes: 3, seconds: 18),
        ),
        Song(
          id: '4',
          title: 'Kopi & Cerita',
          artist: 'Indie Sore',
          album: 'Santai Sejenak',
          duration: Duration(minutes: 3, seconds: 55),
        ),
        Song(
          id: '5',
          title: 'Ruang Rindu',
          artist: 'Melodi Hati',
          album: 'Harmoni',
          duration: Duration(minutes: 4, seconds: 30),
        ),
      ];
}
