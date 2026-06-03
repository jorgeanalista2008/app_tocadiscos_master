import 'package:on_audio_query/on_audio_query.dart';
import '../../domain/entities/song_entity.dart';

/// Origen de datos local para consultar archivos de audio del almacenamiento.
class LocalAudioDatasource {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Realiza un escaneo de los archivos de audio en el almacenamiento externo/interno.
  /// Filtra archivos pequeños (como sonidos del sistema o tonos de mensajería)
  /// y mapea los resultados a nuestra entidad de dominio [SongEntity].
  Future<List<SongEntity>> queryLocalSongs() async {
    try {
      final List<SongModel> songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // Mapear y filtrar canciones menores a 5 segundos
      return songs
          .where((song) => (song.duration ?? 0) >= 5000)
          .map((song) => SongEntity(
                id: song.data, // Usamos el path del archivo físico como id único de reproducción
                rawId: song.id,
                title: song.title.trim().isEmpty ? 'Título Desconocido' : song.title,
                artist: (song.artist == '<unknown>' || song.artist == null)
                    ? 'Artista Desconocido'
                    : song.artist!,
                album: (song.album == '<unknown>' || song.album == null)
                    ? 'Álbum Desconocido'
                    : song.album!,
                duration: song.duration ?? 0,
                path: song.data,
                albumId: song.albumId,
                displayName: song.displayName,
              ))
          .toList();
    } catch (e) {
      // Registrar error o propagar según convenga en Clean Architecture
      rethrow;
    }
  }

  /// Retorna un Widget de carátula en formato de bytes (usando la API interna de on_audio_query)
  /// para renderizar en la interfaz de usuario.
  Future<List<int>?> getArtworkBytes(int id, ArtworkType type) async {
    try {
      return await _audioQuery.queryArtwork(
        id,
        type,
        format: ArtworkFormat.JPEG,
        size: 500,
      );
    } catch (e) {
      return null;
    }
  }
}
