import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/song_entity.dart';
import '../providers/favorites_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/playlists_provider.dart';

class FolderSongsScreen extends ConsumerStatefulWidget {
  final String folderPath;
  final String folderName;

  const FolderSongsScreen({
    super.key,
    required this.folderPath,
    required this.folderName,
  });

  @override
  ConsumerState<FolderSongsScreen> createState() => _FolderSongsScreenState();
}

class _FolderSongsScreenState extends ConsumerState<FolderSongsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider);
    final songs = folders[widget.folderPath] ?? [];
    
    final filteredSongs = songs.where((song) {
      final query = _searchQuery.toLowerCase();
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();

    final favorites = ref.watch(favoritesProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar en esta carpeta...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: filteredSongs.isEmpty
          ? const Center(
              child: Text(
                'No se encontraron canciones en esta carpeta.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
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
                        '${filteredSongs.length} canciones',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        label: const Text('Reproducir Todo', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => _playSongs(filteredSongs, 0),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredSongs.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
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
                                icon: const Icon(Icons.more_vert_rounded),
                                onPressed: () => _showSongMenu(context, song),
                              ),
                            ],
                          ),
                          onTap: () => _playSongs(filteredSongs, index),
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
  Future<void> _playSongs(List<SongEntity> songsList, int index) async {
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

  /// Muestra el menú de la canción
  void _showSongMenu(BuildContext context, SongEntity song) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final playlists = ref.watch(playlistsProvider).value ?? [];

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.playlist_add_rounded, color: AppTheme.primaryColor),
                    title: const Text('Agregar a Lista de Reproducción'),
                    onTap: () {
                      Navigator.pop(context);
                      if (playlists.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No tienes listas de reproducción. Crea una primero.')),
                        );
                        return;
                      }
                      _showPlaylistSelector(context, song);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Muestra el diálogo para seleccionar la lista de reproducción
  void _showPlaylistSelector(BuildContext context, SongEntity song) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Lista'),
          content: Consumer(
            builder: (context, ref, _) {
              final playlists = ref.watch(playlistsProvider).value ?? [];
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: const Icon(Icons.playlist_play_rounded),
                      title: Text(playlist.name),
                      onTap: () {
                        ref.read(playlistsProvider.notifier).addSongToPlaylist(playlist.id, song.path!);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Agregado a ${playlist.name}')),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}
