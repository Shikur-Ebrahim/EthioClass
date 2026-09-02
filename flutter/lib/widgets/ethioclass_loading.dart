import 'package:flutter/material.dart';
import '../core/theme.dart';

class EthioClassLoading extends StatefulWidget {
  final double size;
  final bool showText;

  const EthioClassLoading({
    super.key,
    this.size = 56.0,
    this.showText = true,
  });

  @override
  State<EthioClassLoading> createState() => _EthioClassLoadingState();
}

class _EthioClassLoadingState extends State<EthioClassLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom animated spinner
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                RotationTransition(
                  turns: _controller,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: 0.75, // Creates a 75% filled circle with a 25% gap
                      strokeWidth: widget.size * 0.08,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                // Inner pulsing icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Pulsing scale effect (bounces between 0.85 and 1.05)
                    final double progress = _controller.value;
                    final double pulse = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
                    final double scale = 0.85 + (pulse * 0.2);
                    
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        Icons.school_rounded,
                        color: AppColors.primary,
                        size: widget.size * 0.45,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (widget.showText) ...[
            const SizedBox(height: 16),
            const Text(
              'EthioClass',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Loading...',
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}