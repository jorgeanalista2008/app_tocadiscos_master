import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/playlist_entity.dart';

class PlaylistsNotifier extends AsyncNotifier<List<PlaylistEntity>> {
  static const _key = 'playlists_data';

  @override
  Future<List<PlaylistEntity>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    try {
      final List decoded = jsonDecode(data);
      return decoded.map((item) => PlaylistEntity(
        id: item['id'] as String,
        name: item['name'] as String,
        songPaths: List<String>.from(item['songPaths'] as List),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Crea una nueva lista de reproducción
  Future<void> createPlaylist(String name) async {
    final playlists = state.value ?? [];
    final newPlaylist = PlaylistEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songPaths: [],
    );
    final updated = [...playlists, newPlaylist];
    state = AsyncValue.data(updated);
    await _save(updated);
  }

  /// Elimina una lista de reproducción
  Future<void> deletePlaylist(String id) async {
    final playlists = state.value ?? [];
    final updated = playlists.where((p) => p.id != id).toList();
    state = AsyncValue.data(updated);
    await _save(updated);
  }

  /// Agrega una canción a una lista de reproducción
  Future<void> addSongToPlaylist(String playlistId, String songPath) async {
    final playlists = state.value ?? [];
    final updated = playlists.map((p) {
      if (p.id == playlistId) {
        if (!p.songPaths.contains(songPath)) {
          return p.copyWith(songPaths: [...p.songPaths, songPath]);
        }
      }
      return p;
    }).toList();
    state = AsyncValue.data(updated);
    await _save(updated);
  }

  /// Quita una canción de una lista de reproducción
  Future<void> removeSongFromPlaylist(String playlistId, String songPath) async {
    final playlists = state.value ?? [];
    final updated = playlists.map((p) {
      if (p.id == playlistId) {
        return p.copyWith(
          songPaths: p.songPaths.where((path) => path != songPath).toList(),
        );
      }
      return p;
    }).toList();
    state = AsyncValue.data(updated);
    await _save(updated);
  }

  Future<void> _save(List<PlaylistEntity> list) async {
    final prefs = await SharedPreferences.getInstance();
    final data = list.map((p) => {
      'id': p.id,
      'name': p.name,
      'songPaths': p.songPaths,
    }).toList();
    await prefs.setString(_key, jsonEncode(data));
  }
}

final playlistsProvider = AsyncNotifierProvider<PlaylistsNotifier, List<PlaylistEntity>>(() {
  return PlaylistsNotifier();
});
