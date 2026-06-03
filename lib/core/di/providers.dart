import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/player/data/services/audio_player_handler.dart';

/// Proveedor global para la instancia única de [AudioPlayerHandler].
/// Se inicializa en el arranque de la aplicación (dentro de `main.dart`)
/// y su valor es sobreescrito (overridden) en el `ProviderScope`.
final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  throw UnimplementedError(
    'audioHandlerProvider debe ser sobreescrito en el ProviderScope principal.',
  );
});
