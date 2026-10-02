import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musikku/core/constants/app_colors.dart';
import 'package:musikku/features/player/data/audio_player_service.dart';
import 'package:musikku/features/player/domain/models/song.dart';

class NowPlayingScreen extends StatefulWidget {
  final Song? song;

  const NowPlayingScreen({
    super.key,
    this.song,
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final AudioPlayerService _playerService = AudioPlayerService.instance;
  bool _isDraggingSlider = false;
  double _dragValue = 0;

  @override
  void initState() {
    super.initState();
    if (widget.song != null && _playerService.currentSong?.id != widget.song!.id) {
      _playerService.playSong(widget.song!);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _playerService,
      builder: (context, child) {
        final currentSong = _playerService.currentSong ?? widget.song;

        if (currentSong == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text(
                'Tidak ada lagu yang sedang diputar',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final position = _playerService.position;
        final duration = _playerService.duration.inMilliseconds > 0
            ? _playerService.duration
            : (currentSong.duration.inMilliseconds > 0 ? currentSong.duration : const Duration(seconds: 1));

        final maxDurationMs = duration.inMilliseconds.toDouble();
        final currentPosMs = _isDraggingSlider
            ? _dragValue
            : position.inMilliseconds.toDouble().clamp(0.0, maxDurationMs);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              children: [
                const Text(
                  'MEMUTAR DARI DIREKTORI',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_outlined, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      currentSong.folderName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showSongDetails(context, currentSong),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                children: [
                  const Spacer(),
                  // Album Art or Query Artwork
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.78,
                      height: MediaQuery.of(context).size.width * 0.78,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 36,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: currentSong.audioQueryId != null
                            ? QueryArtworkWidget(
                                id: currentSong.audioQueryId!,
                                type: ArtworkType.AUDIO,
                                artworkWidth: double.infinity,
                                artworkHeight: double.infinity,
                                artworkFit: BoxFit.cover,
                                nullArtworkWidget: _buildArtworkPlaceholder(),
                              )
                            : _buildArtworkPlaceholder(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Song Title, Artist & Favorite
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentSong.artist,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_border,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.divider,
                      thumbColor: AppColors.primaryLight,
                    ),
                    child: Slider(
                      value: currentPosMs.clamp(0.0, maxDurationMs),
                      min: 0,
                      max: maxDurationMs,
                      onChangeStart: (value) {
                        setState(() {
                          _isDraggingSlider = true;
                          _dragValue = value;
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          _dragValue = value;
                        });
                      },
                      onChangeEnd: (value) async {
                        _isDraggingSlider = false;
                        await _playerService.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(
                            _isDraggingSlider
                                ? Duration(milliseconds: _dragValue.toInt())
                                : position,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Playback Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shuffle button
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: _playerService.isShuffle ? AppColors.secondary : AppColors.textSecondary,
                        ),
                        onPressed: () => _playerService.toggleShuffle(),
                      ),
                      // Skip Previous
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 38),
                        onPressed: () => _playerService.playPrevious(),
                      ),
                      // Play / Pause Button
                      GestureDetector(
                        onTap: () => _playerService.togglePlayPause(),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x667C4DFF),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            _playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Skip Next
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 38),
                        onPressed: () => _playerService.playNext(),
                      ),
                      // Repeat / Loop button
                      IconButton(
                        icon: Icon(
                          _playerService.loopMode == LoopMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: _playerService.loopMode != LoopMode.off
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                        ),
                        onPressed: () => _playerService.toggleLoopMode(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtworkPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 96,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showSongDetails(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi File Lagu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _detailRow('Judul', song.title),
              _detailRow('Artis', song.artist),
              _detailRow('Album', song.album),
              _detailRow('Durasi', song.durationString),
              _detailRow('Folder', song.folderName),
              _detailRow('Lokasi Path', song.uriOrPath),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
