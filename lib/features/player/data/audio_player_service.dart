import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musikku/features/player/domain/models/song.dart';

class AudioPlayerService extends ChangeNotifier {
  // Singleton pattern for easy app-wide access
  static final AudioPlayerService instance = AudioPlayerService._internal();

  factory AudioPlayerService() => instance;

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  List<Song> _playlist = [];
  int _currentIndex = -1;
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;

  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;

  AudioPlayerService._internal() {
    _initListeners();
  }

  void _initListeners() {
    // Listen to player state (playing / paused / buffering / completed)
    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

      _isPlaying = playing && processingState != ProcessingState.completed;

      if (processingState == ProcessingState.completed) {
        playNext(auto: true);
      }
      notifyListeners();
    });

    // Listen to position changes
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    // Listen to duration changes
    _player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });
  }

  /// Play a specific song and optionally update the active playlist
  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    if (playlist != null && playlist.isNotEmpty) {
      _playlist = List.from(playlist);
      _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    } else if (!_playlist.any((s) => s.id == song.id)) {
      _playlist.add(song);
      _currentIndex = _playlist.length - 1;
    } else {
      _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    }

    _currentSong = song;
    notifyListeners();

    try {
      await _player.stop();

      // Check whether it's a file path or a content URI
      final uriString = song.uriOrPath;
      if (uriString.startsWith('content://') || uriString.startsWith('http')) {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(uriString)));
      } else {
        final file = File(uriString);
        if (await file.exists()) {
          await _player.setAudioSource(AudioSource.uri(Uri.file(file.path)));
        } else {
          // Attempt fallback parsing
          await _player.setAudioSource(AudioSource.uri(Uri.parse(uriString)));
        }
      }

      await _player.play();
    } catch (e) {
      debugPrint('Error playing song ${song.title}: $e');
    }
  }

  /// Toggle Play / Pause
  Future<void> togglePlayPause() async {
    if (_currentSong == null) {
      if (_playlist.isNotEmpty) {
        await playSong(_playlist.first);
      }
      return;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Skip to next song in playlist
  Future<void> playNext({bool auto = false}) async {
    if (_playlist.isEmpty) return;

    if (_isShuffle) {
      final random = DateTime.now().millisecondsSinceEpoch % _playlist.length;
      _currentIndex = random;
    } else {
      if (_currentIndex + 1 < _playlist.length) {
        _currentIndex++;
      } else {
        if (_loopMode == LoopMode.all || auto) {
          _currentIndex = 0;
        } else {
          await _player.stop();
          return;
        }
      }
    }

    final nextSong = _playlist[_currentIndex];
    await playSong(nextSong);
  }

  /// Skip to previous song in playlist
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    // If already played more than 3 seconds, replay current song from beginning
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_currentIndex - 1 >= 0) {
      _currentIndex--;
    } else {
      _currentIndex = _playlist.length - 1;
    }

    final prevSong = _playlist[_currentIndex];
    await playSong(prevSong);
  }

  /// Seek to duration
  Future<void> seek(Duration newPosition) async {
    await _player.seek(newPosition);
  }

  /// Toggle shuffle
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  /// Toggle loop mode (off -> all -> one -> off)
  void toggleLoopMode() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
      _player.setLoopMode(LoopMode.all);
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
      _player.setLoopMode(LoopMode.one);
    } else {
      _loopMode = LoopMode.off;
      _player.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
