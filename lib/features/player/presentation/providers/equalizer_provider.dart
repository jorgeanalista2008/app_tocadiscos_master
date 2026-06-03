import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';

/// Clase que encapsula el estado del ecualizador
class EqualizerState {
  final bool isEnabled;
  final List<double> gains;
  final List<double> frequencies;
  final String activePreset;

  EqualizerState({
    required this.isEnabled,
    required this.gains,
    required this.frequencies,
    required this.activePreset,
  });

  EqualizerState copyWith({
    bool? isEnabled,
    List<double>? gains,
    List<double>? frequencies,
    String? activePreset,
  }) {
    return EqualizerState(
      isEnabled: isEnabled ?? this.isEnabled,
      gains: gains ?? this.gains,
      frequencies: frequencies ?? this.frequencies,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}

/// Notificador de Riverpod para manipular las bandas y presets del ecualizador
class EqualizerNotifier extends StateNotifier<EqualizerState> {
  final Ref ref;

  EqualizerNotifier(this.ref)
      : super(EqualizerState(
          isEnabled: false,
          gains: [],
          frequencies: [],
          activePreset: 'Flat',
        )) {
    _init();
  }

  /// Inicializa cargando las bandas nativas devueltas por just_audio/Android
  Future<void> _init() async {
    try {
      final handler = ref.read(audioHandlerProvider);
      final freqs = await handler.getEqualizerFrequencies();
      final gains = await handler.getEqualizerGains();
      
      state = EqualizerState(
        isEnabled: true,
        gains: gains.isEmpty ? List.filled(freqs.length, 0.0) : gains,
        frequencies: freqs,
        activePreset: 'Flat',
      );
    } catch (e) {
      // Manejar la inicialización fallida (por ejemplo en simuladores que no tengan ecualizador nativo)
    }
  }

  /// Ajusta la ganancia en decibelios para una banda específica
  Future<void> setBandGain(int bandIndex, double gain) async {
    final handler = ref.read(audioHandlerProvider);
    await handler.setEqualizerBandGain(bandIndex, gain);
    
    final newGains = List<double>.from(state.gains);
    newGains[bandIndex] = gain;
    
    state = state.copyWith(
      gains: newGains,
      activePreset: 'Personalizado',
    );
  }

  /// Activa/Desactiva el ecualizador
  Future<void> setEnabled(bool enabled) async {
    final handler = ref.read(audioHandlerProvider);
    await handler.setEqualizerEnabled(enabled);
    state = state.copyWith(isEnabled: enabled);
  }

  /// Aplica uno de los presets preconfigurados
  Future<void> applyPreset(String presetName) async {
    final Map<String, List<double>> presets = {
      'Normal': [0.0, 0.0, 0.0, 0.0, 0.0],
      'Rock': [4.0, 2.0, -1.0, 2.0, 4.0],
      'Heavy Metal': [5.0, 1.0, -1.0, 3.0, 1.0],
      'Pop': [-1.0, 2.0, 4.0, 2.0, -2.0],
      'Clásica': [4.0, 3.0, -1.0, 3.0, 4.0],
      'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
      'Bass Boost': [6.0, 4.0, 0.0, 0.0, 0.0],
    };

    final gains = presets[presetName];
    if (gains == null) return;

    final handler = ref.read(audioHandlerProvider);
    for (int i = 0; i < gains.length; i++) {
      if (i < state.gains.length) {
        await handler.setEqualizerBandGain(i, gains[i]);
      }
    }

    state = state.copyWith(
      gains: List<double>.from(gains),
      activePreset: presetName,
    );
  }
}

/// Proveedor para controlar y leer de forma reactiva el ecualizador
final equalizerProvider = StateNotifierProvider<EqualizerNotifier, EqualizerState>((ref) {
  return EqualizerNotifier(ref);
});
