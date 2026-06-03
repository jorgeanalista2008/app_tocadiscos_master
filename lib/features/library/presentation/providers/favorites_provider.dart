import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends AsyncNotifier<List<String>> {
  static const _key = 'favorites_data';

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// Alterna el estado de favorita de una canción
  Future<void> toggleFavorite(String songPath) async {
    final favorites = state.value ?? [];
    final updated = List<String>.from(favorites);
    if (updated.contains(songPath)) {
      updated.remove(songPath);
    } else {
      updated.add(songPath);
    }
    
    state = AsyncValue.data(updated);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }

  /// Verifica si una canción es favorita
  bool isFavorite(String songPath) {
    return state.value?.contains(songPath) ?? false;
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<String>>(() {
  return FavoritesNotifier();
});
