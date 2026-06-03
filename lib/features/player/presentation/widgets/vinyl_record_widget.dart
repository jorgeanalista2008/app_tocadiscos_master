import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget que representa un disco de vinilo giratorio animado.
/// Muestra surcos analógicos concéntricos, la carátula de la canción en el centro,
/// y rota indefinidamente a velocidad de 33 RPM cuando [isPlaying] es verdadero.
class VinylRecordWidget extends StatefulWidget {
  final bool isPlaying;
  final int? songRawId;
  final double size;

  const VinylRecordWidget({
    super.key,
    required this.isPlaying,
    this.songRawId,
    this.size = 280.0,
  });

  @override
  State<VinylRecordWidget> createState() => _VinylRecordWidgetState();
}

class _VinylRecordWidgetState extends State<VinylRecordWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Velocidad realista
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VinylRecordWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0D0D0D), // Negro carbón de vinilo
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Efecto de surcos del disco de vinilo (círculos concéntricos)
              ...List.generate(7, (index) {
                final double currentSize = widget.size - (24.0 * (index + 1));
                if (currentSize <= 70.0) return const SizedBox.shrink();
                return Container(
                  width: currentSize,
                  height: currentSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.04),
                      width: 1.0,
                    ),
                  ),
                );
              }),
              
              // Centro del disco: Etiqueta y carátula
              Container(
                width: widget.size * 0.40,
                height: widget.size * 0.40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  border: Border.all(color: const Color(0xFF0D0D0D), width: 4),
                ),
                child: ClipOval(
                  child: widget.songRawId != null
                      ? QueryArtworkWidget(
                          id: widget.songRawId!,
                          type: ArtworkType.AUDIO,
                          keepOldArtwork: true,
                          artworkBorder: BorderRadius.circular(0),
                          nullArtworkWidget: _buildDefaultLabel(),
                        )
                      : _buildDefaultLabel(),
                ),
              ),
              
              // El agujero central del plato
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLabel() {
    return Container(
      color: AppTheme.primaryColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.album_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              'TocaNexxos.pro',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 6,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
