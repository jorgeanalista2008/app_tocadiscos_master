/// Entidad del dominio que representa una lista de reproducción personalizada.
class PlaylistEntity {
  final String id;
  final String name;
  final List<String> songPaths; // Rutas físicas de las canciones asociadas a esta lista

  const PlaylistEntity({
    required this.id,
    required this.name,
    required this.songPaths,
  });

  /// Copiar con modificaciones
  PlaylistEntity copyWith({
    String? id,
    String? name,
    List<String>? songPaths,
  }) {
    return PlaylistEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      songPaths: songPaths ?? this.songPaths,
    );
  }
}
