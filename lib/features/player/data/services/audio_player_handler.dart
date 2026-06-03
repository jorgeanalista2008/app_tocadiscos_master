import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Implementación personalizada de [BaseAudioHandler] utilizando la librería `just_audio`.
/// Se encarga de gestionar la reproducción, la cola de canciones y la ecualización en segundo plano.
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  // Instancias del reproductor y ecualizador
  final _equalizer = Platform.isAndroid ? AndroidEqualizer() : null;
  late final AudioPlayer _player;
  
  // Fuente de audio concatenada (Playlist de just_audio)
  final _playlist = ConcatenatingAudioSource(children: []);

  AudioPlayerHandler() {
    // Inicializar el reproductor con el pipeline del ecualizador si estamos en Android
    if (Platform.isAndroid && _equalizer != null) {
      _player = AudioPlayer(
        audioPipeline: AudioPipeline(
          androidAudioEffects: [_equalizer],
        ),
      );
      // Habilitar el ecualizador por defecto
      _equalizer.setEnabled(true);
    } else {
      _player = AudioPlayer();
    }

    _init();
  }

  /// Escucha los cambios del reproductor y los propaga a audio_service
  void _init() {
    // Cargar la playlist en el reproductor
    _player.setAudioSource(_playlist);

    // Propagar eventos de estado de reproducción
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Escuchar el cambio de índice de reproducción para actualizar el MediaItem actual
    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

  }

  /// Mapea los estados de `just_audio` a los requeridos por `audio_service`
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setShuffleMode,
        MediaAction.setRepeatMode,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
      repeatMode: const {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[_player.loopMode]!,
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
  }

  // --- MÉTODOS DE REPRODUCCIÓN ---

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await playbackState.firstWhere((state) => state.processingState == AudioProcessingState.idle);
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    // Si la reproducción aleatoria está activada, just_audio mapea de forma inteligente
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode = const {
      AudioServiceRepeatMode.none: LoopMode.off,
      AudioServiceRepeatMode.one: LoopMode.one,
      AudioServiceRepeatMode.all: LoopMode.all,
      AudioServiceRepeatMode.group: LoopMode.all,
    }[repeatMode]!;
    await _player.setLoopMode(loopMode);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
  }

  // --- GESTIÓN DE COLA (PLAYLIST) ---

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSources = mediaItems.map((item) {
      // Creamos la fuente de audio desde el archivo local (id almacena el path)
      return AudioSource.file(
        item.id,
        tag: item, // Asignamos el tag para vincular metadata al reproductor
      );
    }).toList();

    await _playlist.addAll(audioSources);
    
    // Actualizar la cola visible del servicio
    final newQueue = List<MediaItem>.from(queue.value)..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    await _playlist.clear();
    final audioSources = newQueue.map((item) {
      return AudioSource.file(item.id, tag: item);
    }).toList();
    await _playlist.addAll(audioSources);
    queue.add(newQueue);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _playlist.removeAt(index);
    final newQueue = List<MediaItem>.from(queue.value)..removeAt(index);
    queue.add(newQueue);
  }

  // --- CONFIGURACIÓN DE ECUALIZADOR ---

  /// Obtiene los parámetros de ganancia mínima y máxima soportada (en dB).
  Future<Map<String, double>> getEqualizerGainRange() async {
    if (_equalizer == null) return {'min': -15.0, 'max': 15.0};
    final params = await _equalizer.parameters;
    return {
      'min': params.minDecibels,
      'max': params.maxDecibels,
    };
  }

  /// Obtiene la lista de frecuencias centrales de las bandas disponibles.
  Future<List<double>> getEqualizerFrequencies() async {
    if (_equalizer == null) return [];
    final params = await _equalizer.parameters;
    return params.bands.map((band) => band.centerFrequency).toList();
  }

  /// Obtiene los valores de ganancia actuales para cada banda.
  Future<List<double>> getEqualizerGains() async {
    if (_equalizer == null) return [];
    final params = await _equalizer.parameters;
    return params.bands.map((band) => band.gain).toList();
  }

  /// Establece la ganancia de una banda específica.
  Future<void> setEqualizerBandGain(int bandIndex, double gain) async {
    if (_equalizer == null) return;
    final params = await _equalizer.parameters;
    if (bandIndex >= 0 && bandIndex < params.bands.length) {
      await params.bands[bandIndex].setGain(gain);
    }
  }

  /// Activa o desactiva el ecualizador nativo.
  Future<void> setEqualizerEnabled(bool enabled) async {
    if (_equalizer == null) return;
    await _equalizer.setEnabled(enabled);
  }
}
