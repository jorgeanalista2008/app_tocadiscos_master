/// Entidad del dominio que representa una canción en el reproductor.
/// Esto desacopla nuestra UI y lógica de negocio de la librería externa `on_audio_query`.
class SongEntity {
  final String id; // Path completo o URI único
  final int rawId; // ID numérico de la base de datos de Android
  final String title;
  final String artist;
  final String album;
  final int duration; // Duración en milisegundos
  final String? path;
  final int? albumId;
  final String displayName;

  const SongEntity({
    required this.id,
    required this.rawId,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.path,
    this.albumId,
    required this.displayName,
  });

  /// Copiar con modificaciones (para facilitar mutaciones si fueran necesarias)
  SongEntity copyWith({
    String? id,
    int? rawId,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? path,
    int? albumId,
    String? displayName,
  }) {
    return SongEntity(
      id: id ?? this.id,
      rawId: rawId ?? this.rawId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      path: path ?? this.path,
      albumId: albumId ?? this.albumId,
      displayName: displayName ?? this.displayName,
    );
  }
}
