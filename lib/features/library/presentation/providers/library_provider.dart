import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/library_repository.dart';
import '../../data/datasources/local_audio_datasource.dart';
import '../../data/repositories/library_repository_impl.dart';

/// Proveedor para la fuente de datos de audio local
final localAudioDatasourceProvider = Provider<LocalAudioDatasource>((ref) {
  return LocalAudioDatasource();
});

/// Proveedor para el repositorio de biblioteca
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final datasource = ref.watch(localAudioDatasourceProvider);
  return LibraryRepositoryImpl(datasource);
});

/// Notificador que maneja de manera asíncrona la lista de canciones en la biblioteca local.
/// Permite escanear y refrescar la lista.
class LibraryNotifier extends AsyncNotifier<List<SongEntity>> {
  @override
  Future<List<SongEntity>> build() async {
    return _fetchSongs();
  }

  Future<List<SongEntity>> _fetchSongs() async {
    final repository = ref.read(libraryRepositoryProvider);
    return await repository.getSongs();
  }

  /// Vuelve a escanear los archivos de música locales de forma asíncrona
  Future<void> scanSongs() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchSongs();
    });
  }
}

/// Proveedor de estado global para la lista de canciones en la biblioteca
final librarySongsProvider = AsyncNotifierProvider<LibraryNotifier, List<SongEntity>>(() {
  return LibraryNotifier();
});
