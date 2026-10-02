import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musikku/core/constants/app_colors.dart';
import 'package:musikku/features/player/data/audio_player_service.dart';
import 'package:musikku/features/player/domain/models/song.dart';
import 'package:musikku/features/player/presentation/screens/now_playing_screen.dart';

class FolderSongsScreen extends StatelessWidget {
  final String folderName;
  final String folderPath;
  final List<Song> songs;

  const FolderSongsScreen({
    super.key,
    required this.folderName,
    required this.folderPath,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    final playerService = AudioPlayerService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
      ),
      body: Column(
        children: [
          // Folder Info & Actions
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: AppColors.secondary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folderName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${songs.length} lagu di folder ini',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Play All & Shuffle buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Putar Semua'),
                    onPressed: songs.isEmpty
                        ? null
                        : () {
                            playerService.playSong(songs.first, playlist: songs);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const NowPlayingScreen(),
                              ),
                            );
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.shuffle, size: 20),
                    label: const Text('Acak'),
                    onPressed: songs.isEmpty
                        ? null
                        : () {
                            if (!playerService.isShuffle) {
                              playerService.toggleShuffle();
                            }
                            playerService.playSong(songs.first, playlist: songs);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const NowPlayingScreen(),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Songs List
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final song = songs[index];
                return AnimatedBuilder(
                  animation: playerService,
                  builder: (context, child) {
                    final isCurrent = playerService.currentSong?.id == song.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.surface : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrent
                            ? Border.all(color: AppColors.primaryLight.withAlpha(120), width: 1)
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: song.audioQueryId != null
                              ? QueryArtworkWidget(
                                  id: song.audioQueryId!,
                                  type: ArtworkType.AUDIO,
                                  nullArtworkWidget: _defaultCover(isCurrent),
                                )
                              : _defaultCover(isCurrent),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isCurrent ? AppColors.primaryLight : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.album}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          song.durationString,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        onTap: () {
                          playerService.playSong(song, playlist: songs);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NowPlayingScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultCover(bool isCurrent) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isCurrent ? Icons.equalizer : Icons.music_note,
        color: isCurrent ? AppColors.primaryLight : AppColors.textSecondary,
      ),
    );
  }
}
