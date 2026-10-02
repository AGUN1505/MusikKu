import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musikku/core/constants/app_colors.dart';
import 'package:musikku/features/home/presentation/screens/folder_songs_screen.dart';
import 'package:musikku/features/player/data/audio_player_service.dart';
import 'package:musikku/features/player/data/audio_query_service.dart';
import 'package:musikku/features/player/domain/models/song.dart';
import 'package:musikku/features/player/presentation/screens/now_playing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AudioQueryService _audioQueryService = AudioQueryService();
  final AudioPlayerService _playerService = AudioPlayerService.instance;

  late TabController _tabController;
  List<Song> _allSongs = [];
  Map<String, List<Song>> _folderGroups = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDeviceAudio();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceAudio() async {
    setState(() => _isLoading = true);
    final songs = await _audioQueryService.queryOfflineSongs();
    final folderMap = _audioQueryService.groupSongsByFolder(songs);

    setState(() {
      _allSongs = songs;
      _folderGroups = folderMap;
      _isLoading = false;
    });
  }

  Future<void> _pickCustomFolder() async {
    final newSongs = await _audioQueryService.pickAndScanFolder();
    if (newSongs.isNotEmpty) {
      final updatedList = List<Song>.from(_allSongs);
      for (final s in newSongs) {
        if (!updatedList.any((existing) => existing.uriOrPath == s.uriOrPath)) {
          updatedList.add(s);
        }
      }
      final updatedFolders = _audioQueryService.groupSongsByFolder(updatedList);
      setState(() {
        _allSongs = updatedList;
        _folderGroups = updatedFolders;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ditemukan ${newSongs.length} lagu baru dari folder yang dipilih!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  List<Song> get _filteredSongs {
    if (_searchQuery.isEmpty) return _allSongs;
    final query = _searchQuery.toLowerCase();
    return _allSongs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          song.folderName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar & Search
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MusikKu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${_allSongs.length} lagu offline tersedia',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_outlined, color: AppColors.secondary),
                    tooltip: 'Pilih Folder dari HP',
                    onPressed: _pickCustomFolder,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Muat Ulang Lagu',
                    onPressed: _loadDeviceAudio,
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari judul lagu, artis, atau folder...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Tabs Header
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primaryLight,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(
                  icon: const Icon(Icons.queue_music_rounded),
                  text: 'Semua Lagu (${_allSongs.length})',
                ),
                Tab(
                  icon: const Icon(Icons.folder_open_rounded),
                  text: 'Folder (${_folderGroups.keys.length})',
                ),
              ],
            ),

            // Tab Views Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSongsTab(),
                        _buildFoldersTab(),
                      ],
                    ),
            ),

            // Persistent Mini-Player
            _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsTab() {
    final songs = _filteredSongs;

    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _allSongs.isEmpty ? Icons.folder_off_outlined : Icons.search_off_rounded,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                _allSongs.isEmpty
                    ? 'Tidak ditemukan file musik di HP Anda'
                    : 'Tidak ada hasil untuk "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (_allSongs.isEmpty) ...[
                const Text(
                  'Pastikan izin penyimpanan diaktifkan atau pilih folder tempat Anda menyimpan file lagu (.mp3, .m4a, dll).',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Pilih Folder Musik'),
                  onPressed: _pickCustomFolder,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeviceAudio,
      color: AppColors.primary,
      child: ListView.builder(
        itemCount: songs.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          final song = songs[index];

          return AnimatedBuilder(
            animation: _playerService,
            builder: (context, child) {
              final isCurrent = _playerService.currentSong?.id == song.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrent
                      ? Border.all(color: AppColors.primaryLight.withAlpha(120), width: 1)
                      : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.audioQueryId != null
                        ? QueryArtworkWidget(
                            id: song.audioQueryId!,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: _songCoverPlaceholder(isCurrent),
                          )
                        : _songCoverPlaceholder(isCurrent),
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
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          song.folderName,
                          style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          song.artist,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    song.durationString,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  onTap: () {
                    _playerService.playSong(song, playlist: songs);
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
    );
  }

  Widget _buildFoldersTab() {
    final folderNames = _folderGroups.keys.toList();

    if (folderNames.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Belum ada folder musik terdeteksi',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.folder_open),
              label: const Text('Pilih Folder dari HP'),
              onPressed: _pickCustomFolder,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: folderNames.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final folderName = folderNames[index];
        final folderSongs = _folderGroups[folderName] ?? [];
        final samplePath = folderSongs.isNotEmpty ? folderSongs.first.folderPath : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.folder_rounded,
                color: AppColors.secondary,
                size: 30,
              ),
            ),
            title: Text(
              folderName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${folderSongs.length} lagu',
                  style: const TextStyle(color: AppColors.primaryLight, fontSize: 13),
                ),
                if (samplePath.isNotEmpty)
                  Text(
                    samplePath,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FolderSongsScreen(
                    folderName: folderName,
                    folderPath: samplePath,
                    songs: folderSongs,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _songCoverPlaceholder(bool isCurrent) {
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
        size: 26,
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return AnimatedBuilder(
      animation: _playerService,
      builder: (context, child) {
        final currentSong = _playerService.currentSong;
        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        final pos = _playerService.position.inMilliseconds.toDouble();
        final dur = _playerService.duration.inMilliseconds.toDouble();
        final progress = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear progress indicator on top of mini player
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 2.5,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NowPlayingScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: currentSong.audioQueryId != null
                          ? QueryArtworkWidget(
                              id: currentSong.audioQueryId!,
                              type: ArtworkType.AUDIO,
                              artworkWidth: 44,
                              artworkHeight: 44,
                              nullArtworkWidget: _songCoverPlaceholder(true),
                            )
                          : _songCoverPlaceholder(true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentSong.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                currentSong.folderName,
                                style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                              ),
                              const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              Expanded(
                                child: Text(
                                  currentSong.artist,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: () => _playerService.playPrevious(),
                    ),
                    IconButton(
                      icon: Icon(
                        _playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () => _playerService.togglePlayPause(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: () => _playerService.playNext(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
