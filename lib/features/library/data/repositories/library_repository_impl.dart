import 'package:on_audio_query/on_audio_query.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/local_audio_datasource.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final LocalAudioDatasource _datasource;

  LibraryRepositoryImpl(this._datasource);

  @override
  Future<List<SongEntity>> getSongs() {
    return _datasource.queryLocalSongs();
  }

  @override
  Future<List<int>?> getSongArtwork(int songId, ArtworkType type) {
    return _datasource.getArtworkBytes(songId, type);
  }
}
