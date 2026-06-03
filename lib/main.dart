import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

// Core Imports
import 'core/di/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/permission/permission_service.dart';

// Features Imports
import 'features/library/domain/entities/song_entity.dart';
import 'features/library/presentation/providers/library_provider.dart';
import 'features/player/data/services/audio_player_handler.dart';
import 'features/player/presentation/providers/player_provider.dart';
import 'features/player/presentation/providers/equalizer_provider.dart';
import 'features/home_widget/presentation/providers/widget_sync_provider.dart';
import 'features/player/presentation/screens/player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar el servicio de audio en segundo plano
  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.tocadiscos.app.channel.audio',
      androidNotificationChannelName: 'Tocadiscos.pro Reproductor',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        // Inyectamos la instancia real del manejador de audio
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el provider de sincronización de widgets en segundo plano
    ref.watch(widgetSyncProvider);

    // Obtener la selección actual del tema
    final currentThemeMode = ref.watch(themeProvider);

    // Mapear AppThemeMode a ThemeData
    ThemeData appThemeData;
    ThemeMode systemThemeMode;

    switch (currentThemeMode) {
      case AppThemeMode.light:
        appThemeData = AppTheme.lightTheme;
        systemThemeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        appThemeData = AppTheme.darkTheme;
        systemThemeMode = ThemeMode.dark;
        break;
      case AppThemeMode.amoled:
        appThemeData = AppTheme.amoledTheme;
        systemThemeMode = ThemeMode.dark; // AMOLED se mapea a dark
        break;
    }

    return MaterialApp(
      title: 'Tocadiscos.pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: appThemeData,
      themeMode: systemThemeMode,
      home: const MainLibraryScreen(),
    );
  }
}

/// Pantalla Principal que gestiona el permiso, lista de canciones y reproductor
class MainLibraryScreen extends ConsumerStatefulWidget {
  const MainLibraryScreen({super.key});

  @override
  ConsumerState<MainLibraryScreen> createState() => _MainLibraryScreenState();
}

class _MainLibraryScreenState extends ConsumerState<MainLibraryScreen> {
  bool _hasPermission = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// Comprueba los permisos de almacenamiento
  Future<void> _checkPermissions() async {
    final permissionService = ref.read(permissionServiceProvider);
    final granted = await permissionService.hasAudioPermission();
    setState(() {
      _hasPermission = granted;
      _isChecking = false;
    });

    if (granted) {
      // Disparar escaneo de canciones
      ref.read(librarySongsProvider.notifier).scanSongs();
    }
  }

  /// Solicita explícitamente los permisos de almacenamiento
  Future<void> _requestPermission() async {
    final permissionService = ref.read(permissionServiceProvider);
    final granted = await permissionService.requestAudioPermission();
    setState(() {
      _hasPermission = granted;
    });

    if (granted) {
      ref.read(librarySongsProvider.notifier).scanSongs();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se requieren permisos para buscar música local.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SplashLoader();
    }

    if (!_hasPermission) {
      return _buildPermissionRequestScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tocadiscos.pro'),
        actions: [
          // Selector de Ecualizador
          IconButton(
            icon: const Icon(Icons.equalizer_rounded),
            tooltip: 'Ecualizador',
            onPressed: () => _openEqualizerBottomSheet(context),
          ),
          // Botón alternador de Temas (Claro -> Oscuro -> AMOLED)
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Cambiar Tema',
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
              final nextTheme = ref.read(themeProvider);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tema cambiado a: ${nextTheme.name.toUpperCase()}'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildSongsList(),
          ),
          _buildMiniPlayer(),
        ],
      ),
    );
  }

  /// Pantalla cuando no se tienen permisos concedidos
  Widget _buildPermissionRequestScreen() {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.music_note_rounded,
              size: 100,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Tu Tocadiscos Personal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Para poder reproducir la música de tu dispositivo, necesitamos acceso a los archivos de audio locales.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_shared_rounded),
              label: const Text('Conceder Permisos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _requestPermission,
            ),
          ],
        ),
      ),
    );
  }

  /// Lista de canciones del almacén local
  Widget _buildSongsList() {
    final songsAsync = ref.watch(librarySongsProvider);

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.album_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No se encontraron canciones locales.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(librarySongsProvider.notifier).scanSongs(),
          child: ListView.builder(
            itemCount: songs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final song = songs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 0,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: QueryArtworkWidget(
                      id: song.rawId,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: Container(
                        width: 50,
                        height: 50,
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatDuration(song.duration),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () => _playSong(songs, index),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error al escanear música: $err'),
      ),
    );
  }

  /// Mini Reproductor en la parte inferior de la pantalla
  Widget _buildMiniPlayer() {
    final currentItemAsync = ref.watch(currentMediaItemProvider);
    final playerStateAsync = ref.watch(playerStateProvider);

    final currentItem = currentItemAsync.value;
    final playerState = playerStateAsync.value;

    if (currentItem == null) {
      return const SizedBox.shrink();
    }

    final isPlaying = playerState?.playing ?? false;
    final handler = ref.read(audioHandlerProvider);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PlayerScreen(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: const Border(
            top: BorderSide(color: Color(0xFF222222), width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Carátula
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const Icon(
                  Icons.album_rounded,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              // Detalles de la canción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentItem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currentItem.artist ?? 'Artista Desconocido',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Controles
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: handler.skipToPrevious,
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                  size: 36,
                  color: AppTheme.primaryColor,
                ),
                onPressed: isPlaying ? handler.pause : handler.play,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: handler.skipToNext,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carga la lista completa a la cola y reproduce el índice correspondiente
  Future<void> _playSong(List<SongEntity> songs, int index) async {
    final handler = ref.read(audioHandlerProvider);
    final mediaItems = songs
        .map((song) => MediaItem(
              id: song.path!,
              title: song.title,
              artist: song.artist,
              album: song.album,
              duration: Duration(milliseconds: song.duration),
              extras: {'albumId': song.albumId},
            ))
        .toList();

    await handler.updateQueue(mediaItems);
    await handler.skipToQueueItem(index);
    await handler.play();
  }

  /// Formatea la duración de milisegundos a mm:ss
  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Abre la BottomSheet del Ecualizador
  void _openEqualizerBottomSheet(BuildContext context) {
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

/// BottomSheet que expone los controles del ecualizador
class EqualizerBottomSheet extends ConsumerWidget {
  const EqualizerBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ecualizador Nativo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Switch(
                value: eqState.isEnabled,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) {
                  eqNotifier.setEnabled(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Presets selector
          if (eqState.isEnabled) ...[
            DropdownButtonFormField<String>(
              value: eqState.activePreset,
              decoration: const InputDecoration(
                labelText: 'Ajuste Predefinido',
                border: OutlineInputBorder(),
              ),
              items: ['Normal', 'Rock', 'Heavy Metal', 'Pop', 'Clásica', 'Flat', 'Bass Boost', 'Personalizado']
                  .map((preset) => DropdownMenuItem(
                        value: preset,
                        child: Text(preset),
                      ))
                  .toList(),
              onChanged: (preset) {
                if (preset != null) {
                  eqNotifier.applyPreset(preset);
                }
              },
            ),
            const SizedBox(height: 24),
            // Controles de las 5 Bandas
            const Text(
              'Ajuste Manual (dB)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(eqState.gains.length, (index) {
                final frequency = eqState.frequencies.length > index
                    ? _formatFrequency(eqState.frequencies[index])
                    : '${index + 1}';
                final gain = eqState.gains[index];

                return Expanded(
                  child: Column(
                    children: [
                      Text('${gain.toStringAsFixed(1)} dB', style: const TextStyle(fontSize: 10)),
                      SizedBox(
                        height: 150,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            min: -15.0,
                            max: 15.0,
                            value: gain.clamp(-15.0, 15.0),
                            activeColor: AppTheme.primaryColor,
                            onChanged: (newVal) {
                              eqNotifier.setBandGain(index, newVal);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(frequency, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ),
          ] else ...[
            const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Activa el ecualizador para ajustar el audio.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Formatea la frecuencia nativa
  String _formatFrequency(double frequencyHz) {
    if (frequencyHz >= 1000) {
      return '${(frequencyHz / 1000).toStringAsFixed(0)}kHz';
    }
    return '${frequencyHz.toStringAsFixed(0)}Hz';
  }
}

/// Extensión utilitaria para ListView
extension ListTilePressed on ListTile {
  Widget onPressed(VoidCallback callback) {
    return InkWell(
      onTap: callback,
      child: this,
    );
  }
}

/// Pantalla de Carga Premium (Splash Screen) con vinilo giratorio y logotipo de la marca
class SplashLoader extends StatefulWidget {
  const SplashLoader({super.key});

  @override
  State<SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF33C2D2), // Fondo Turquesa de la imagen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo del tocadiscos con animación de pulso
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Marca de la app solicitada
            const Text(
              'TocaNexxos.pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: 'Outfit',
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tocadiscos.pro',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 48),
            // Cargador blanco minimalista
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
