import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:home_widget/home_widget.dart';

/// Servicio responsable de enviar información de la canción en reproducción
/// a los widgets nativos de la pantalla de inicio (Android AppWidgets / iOS WidgetKit).
class WidgetSyncService {
  static const String _groupId = 'group.com.tocadiscos.app'; // Requerido para iOS AppGroups
  static const String _androidWidgetName = 'TocadiscosHomeWidgetReceiver'; // Nombre del BroadcastReceiver en Android
  static const String _iOSWidgetName = 'TocadiscosHomeWidget'; // Nombre de la extensión de iOS WidgetKit

  WidgetSyncService() {
    // Configurar App Group ID en iOS para compartir datos entre la app principal y el widget
    if (Platform.isIOS) {
      HomeWidget.setAppGroupId(_groupId);
    }
  }

  /// Envía los metadatos de la canción actual y el estado de reproducción al Widget nativo.
  Future<void> updateWidgetData({
    required MediaItem? currentSong,
    required bool isPlaying,
  }) async {
    try {
      if (currentSong != null) {
        await HomeWidget.saveWidgetData<String>('song_title', currentSong.title);
        await HomeWidget.saveWidgetData<String>('song_artist', currentSong.artist);
        await HomeWidget.saveWidgetData<String>('song_album', currentSong.album ?? '');
      } else {
        await HomeWidget.saveWidgetData<String>('song_title', 'Tocadiscos.pro');
        await HomeWidget.saveWidgetData<String>('song_artist', 'Sin reproducción');
        await HomeWidget.saveWidgetData<String>('song_album', '');
      }

      await HomeWidget.saveWidgetData<bool>('is_playing', isPlaying);

      // Disparar la actualización del widget visual nativo
      await HomeWidget.updateWidget(
        name: Platform.isAndroid ? _androidWidgetName : _iOSWidgetName,
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );
    } catch (e) {
      // Manejar excepciones de integración nativa de manera segura
    }
  }

  /// Registra el callback que responderá cuando el usuario pulse el botón de Play/Pause en el Widget de pantalla de inicio.
  /// Este callback se ejecuta en un Isolate de segundo plano.
  static Future<void> registerBackgroundCallback(Function(Uri?) callback) async {
    await HomeWidget.registerBackgroundCallback(callback);
  }
}
