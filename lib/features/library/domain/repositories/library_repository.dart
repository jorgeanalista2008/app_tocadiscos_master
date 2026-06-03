import 'package:on_audio_query/on_audio_query.dart';
import '../../domain/entities/song_entity.dart';

abstract class LibraryRepository {
  Future<List<SongEntity>> getSongs();
  Future<List<int>?> getSongArtwork(int songId, ArtworkType type);
}
