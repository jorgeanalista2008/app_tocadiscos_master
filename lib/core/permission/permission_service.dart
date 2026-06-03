import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Solicita el permiso correspondiente para acceder a los archivos de audio locales.
  /// Retorna [true] si el permiso fue concedido, de lo contrario [false].
  Future<bool> requestAudioPermission() async {
    if (!Platform.isAndroid) {
      // En plataformas que no son Android (como iOS), el comportamiento del simulador
      // o permisos generales puede diferir. Retornamos true ya que on_audio_query se adapta,
      // pero para Android aplicamos la lógica estricta.
      return true;
    }

    // Estado del permiso de audio (READ_MEDIA_AUDIO - Android 13 / API 33+)
    final audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted) {
      return true;
    }

    // Estado del permiso de almacenamiento general (READ_EXTERNAL_STORAGE - Android 12 o inferior)
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) {
      return true;
    }

    // Intentar solicitar permiso de audio para Android 13+
    final audioRequestResult = await Permission.audio.request();
    if (audioRequestResult.isGranted) {
      return true;
    }

    // Si el permiso de audio no está concedido (probablemente Android < 13 donde no existe este permiso),
    // intentamos con el de almacenamiento general.
    final storageRequestResult = await Permission.storage.request();
    if (storageRequestResult.isGranted) {
      return true;
    }

    // Si el usuario deniega permanentemente, se sugiere abrir la configuración del sistema
    if (audioRequestResult.isPermanentlyDenied || storageRequestResult.isPermanentlyDenied) {
      // Opcional: Se puede lanzar un callback o abrir la configuración desde aquí.
      // await openAppSettings();
    }

    return false;
  }

  /// Comprueba si algún permiso de audio o almacenamiento ya está concedido.
  Future<bool> hasAudioPermission() async {
    if (!Platform.isAndroid) return true;
    final audioGranted = await Permission.audio.isGranted;
    final storageGranted = await Permission.storage.isGranted;
    return audioGranted || storageGranted;
  }
}

/// Proveedor para instanciar el servicio de permisos
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});
