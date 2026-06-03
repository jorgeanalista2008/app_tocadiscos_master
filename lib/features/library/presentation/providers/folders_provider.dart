import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import 'library_provider.dart';

/// Obtiene la ruta del directorio padre de una canción
String getFolderPath(String filePath) {
  final normalized = filePath.replaceAll('\\', '/');
  final lastSlash = normalized.lastIndexOf('/');
  if (lastSlash != -1) {
    return normalized.substring(0, lastSlash);
  }
  return '';
}

/// Obtiene el nombre del directorio (el último segmento de la ruta)
String getFolderName(String folderPath) {
  if (folderPath.isEmpty) return 'Raíz';
  final normalized = folderPath.replaceAll('\\', '/');
  final parts = normalized.split('/');
  return parts.isNotEmpty ? parts.last : 'Carpeta';
}

/// Agrupa dinámicamente las canciones escaneadas en carpetas basadas en su ruta física
final foldersProvider = Provider<Map<String, List<SongEntity>>>((ref) {
  final songsAsync = ref.watch(librarySongsProvider);
  return songsAsync.maybeWhen(
    data: (songs) {
      final Map<String, List<SongEntity>> grouped = {};
      for (final song in songs) {
        if (song.path != null && song.path!.isNotEmpty) {
          final folderPath = getFolderPath(song.path!);
          if (grouped.containsKey(folderPath)) {
            grouped[folderPath]!.add(song);
          } else {
            grouped[folderPath] = [song];
          }
        }
      }
      return grouped;
    },
    orElse: () => {},
  );
});
