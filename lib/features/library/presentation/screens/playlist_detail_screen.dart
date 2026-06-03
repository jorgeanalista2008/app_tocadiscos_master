import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/playlist_entity.dart';
import '../providers/favorites_provider.dart';
import '../providers/library_provider.dart';
import '../providers/playlists_provider.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider).value ?? [];
    final playlist = playlists.firstWhere((p) => p.id == playlistId, orElse: () => PlaylistEntity(id: playlistId, name: playlistName, songPaths: []));
    
    // Mapear rutas de archivos a SongEntity reales usando las canciones ya escaneadas
    final allSongs = ref.watch(librarySongsProvider).value ?? [];
    final playlistSongs = playlist.songPaths.map((path) {
      return allSongs.firstWhere((song) => song.path == path, orElse: () => SongEntity(
        id: path,
        rawId: 0,
        title: 'Archivo Desconocido',
        artist: 'Desconocido',
        album: 'Desconocido',
        duration: 0,
        path: path,
        displayName: 'Desconocido',
      ));
    }).where((song) => song.rawId != 0).toList(); // Filtrar canciones que ya no existen

    final favorites = ref.watch(favoritesProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(playlistName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Agregar Canciones',
            onPressed: () => _showAddSongsSelector(context, ref, playlistId, playlistSongs),
          ),
        ],
      ),
      body: playlistSongs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.playlist_add_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Esta lista está vacía.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddSongsSelector(context, ref, playlistId, playlistSongs),
                    child: const Text('Agregar Canciones'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${playlistSongs.length} canciones',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        label: const Text('Reproducir Lista', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => _playSongs(ref, playlistSongs, 0),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: playlistSongs.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final song = playlistSongs[index];
                      final isFav = favorites.contains(song.path);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 0,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: QueryArtworkWidget(
                              id: song.rawId,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: Container(
                                width: 50,
                                height: 50,
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isFav ? Colors.pink : Colors.grey,
                                ),
                                onPressed: () {
                                  ref.read(favoritesProvider.notifier).toggleFavorite(song.path!);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                                tooltip: 'Quitar de la lista',
                                onPressed: () {
                                  ref.read(playlistsProvider.notifier).removeSongFromPlaylist(playlistId, song.path!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Removido de $playlistName')),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () => _playSongs(ref, playlistSongs, index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// Agrega la lista completa a la cola y reproduce el índice correspondiente
  Future<void> _playSongs(WidgetRef ref, List<SongEntity> songsList, int index) async {
    final handler = ref.read(audioHandlerProvider);
    final mediaItems = songsList
        .map((song) => MediaItem(
              id: song.path!,
              title: song.title,
              artist: song.artist,
              album: song.album,
              duration: Duration(milliseconds: song.duration),
              extras: {'albumId': song.albumId},
            ))
        .toList();

    await handler.updateQueue(mediaItems);
    await handler.skipToQueueItem(index);
    await handler.play();
  }

  /// Muestra el selector modal para agregar canciones de la biblioteca
  void _showAddSongsSelector(BuildContext context, WidgetRef ref, String playlistId, List<SongEntity> currentSongs) {
    final allSongs = ref.read(librarySongsProvider).value ?? [];
    final currentPaths = currentSongs.map((s) => s.path).toSet();
    
    // Canciones que NO están en la playlist
    final availableSongs = allSongs.where((song) => !currentPaths.contains(song.path)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Agregar Canciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: availableSongs.isEmpty
                      ? const Center(
                          child: Text(
                            'Todas las canciones ya están agregadas.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: availableSongs.length,
                          itemBuilder: (context, index) {
                            final song = availableSongs[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: QueryArtworkWidget(
                                  id: song.rawId,
                                  type: ArtworkType.AUDIO,
                                  nullArtworkWidget: Container(
                                    width: 40,
                                    height: 40,
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.music_note_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor),
                              onTap: () {
                                ref.read(playlistsProvider.notifier).addSongToPlaylist(playlistId, song.path!);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('"${song.title}" agregada a la lista.')),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
