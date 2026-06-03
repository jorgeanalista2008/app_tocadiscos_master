import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core & Providers
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../widgets/vinyl_record_widget.dart';
import '../../../../../main.dart'; // Para abrir el EqualizerBottomSheet

/// Pantalla detallada del reproductor inmersivo (Player View).
/// Ofrece un disco de vinilo giratorio con la carátula, una barra de progreso interactiva
/// y todos los controles físicos: Play, Pausa, Retroceder (Anterior), Avanzar (Siguiente) y Stop.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItemAsync = ref.watch(currentMediaItemProvider);
    final playerStateAsync = ref.watch(playerStateProvider);
    final handler = ref.read(audioHandlerProvider);

    final currentItem = currentItemAsync.value;
    final playerState = playerStateAsync.value;

    if (currentItem == null) {
      return const Scaffold(
        body: Center(
          child: Text('No hay canción en reproducción.'),
        ),
      );
    }

    final isPlaying = playerState?.playing ?? false;
    final shuffleMode = playerState?.shuffleMode ?? AudioServiceShuffleMode.none;
    final repeatMode = playerState?.repeatMode ?? AudioServiceRepeatMode.none;
    final duration = currentItem.duration ?? Duration.zero;
    final songRawId = currentItem.extras?['albumId'] as int?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonando Ahora'),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.equalizer_rounded),
            tooltip: 'Ecualizador',
            onPressed: () => _openEqualizer(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Disco de vinilo animado
              Expanded(
                flex: 5,
                child: VinylRecordWidget(
                  isPlaying: isPlaying,
                  songRawId: songRawId,
                  size: MediaQuery.of(context).size.width * 0.75,
                ),
              ),

              const SizedBox(height: 24),

              // Información de la pista
              Column(
                children: [
                  Text(
                    currentItem.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentItem.artist ?? 'Artista Desconocido',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Barra de Progreso y Tiempos
              StreamBuilder<Duration>(
                stream: AudioService.position,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final double sliderValue = duration.inMilliseconds > 0
                      ? (position.inMilliseconds / duration.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0;

                  return Column(
                    children: [
                      Slider(
                        min: 0.0,
                        max: 1.0,
                        value: sliderValue,
                        activeColor: AppTheme.primaryColor,
                        inactiveColor: Theme.of(context).colorScheme.surface,
                        onChanged: (val) {
                          final targetMs = (val * duration.inMilliseconds).round();
                          handler.seek(Duration(milliseconds: targetMs));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Controles de Reproducción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: shuffleMode == AudioServiceShuffleMode.all
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                    onPressed: () {
                      final nextMode = shuffleMode == AudioServiceShuffleMode.all
                          ? AudioServiceShuffleMode.none
                          : AudioServiceShuffleMode.all;
                      handler.setShuffleMode(nextMode);
                    },
                  ),

                  // Retroceder / Anterior
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 42),
                    onPressed: handler.skipToPrevious,
                  ),

                  // Play / Pausa central
                  GestureDetector(
                    onTap: isPlaying ? handler.pause : handler.play,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor,
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Avanzar / Siguiente
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 42),
                    onPressed: handler.skipToNext,
                  ),

                  // Repetir
                  IconButton(
                    icon: Icon(
                      repeatMode == AudioServiceRepeatMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color: repeatMode != AudioServiceRepeatMode.none
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                    onPressed: () {
                      AudioServiceRepeatMode nextMode;
                      if (repeatMode == AudioServiceRepeatMode.none) {
                        nextMode = AudioServiceRepeatMode.all;
                      } else if (repeatMode == AudioServiceRepeatMode.all) {
                        nextMode = AudioServiceRepeatMode.one;
                      } else {
                        nextMode = AudioServiceRepeatMode.none;
                      }
                      handler.setRepeatMode(nextMode);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Botón de Stop
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined, size: 36, color: Colors.grey),
                tooltip: 'Detener Reproducción',
                onPressed: () async {
                  await handler.stop();
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Salir al detener
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatea duración a mm:ss
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Abre el ecualizador
  void _openEqualizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const EqualizerBottomSheet();
      },
    );
  }
}
