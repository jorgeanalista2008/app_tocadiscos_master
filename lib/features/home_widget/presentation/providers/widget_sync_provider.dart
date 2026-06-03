import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/widget_sync_service.dart';
import '../../../player/presentation/providers/player_provider.dart';

/// Proveedor para instanciar el servicio de sincronización de widgets
final widgetSyncServiceProvider = Provider<WidgetSyncService>((ref) {
  return WidgetSyncService();
});

/// Proveedor de efectos (Side-Effects) que observa los cambios de estado del reproductor
/// y automáticamente dispara las actualizaciones hacia el Widget nativo.
final widgetSyncProvider = Provider<void>((ref) {
  final syncService = ref.watch(widgetSyncServiceProvider);
  
  // Escuchar cambios de la canción actual en reproducción
  ref.listen(currentMediaItemProvider, (previous, next) {
    final mediaItem = next.value;
    final isPlaying = ref.read(playerStateProvider).value?.playing ?? false;
    syncService.updateWidgetData(currentSong: mediaItem, isPlaying: isPlaying);
  });

  // Escuchar cambios en el estado de reproducción (Play/Pause)
  ref.listen(playerStateProvider, (previous, next) {
    final isPlaying = next.value?.playing ?? false;
    final mediaItem = ref.read(currentMediaItemProvider).value;
    syncService.updateWidgetData(currentSong: mediaItem, isPlaying: isPlaying);
  });
});
