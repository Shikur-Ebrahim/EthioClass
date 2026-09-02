import 'package:flutter/material.dart';
import 'dart:math' show sin, pi;
import '../core/theme.dart';

class EthioClassLoading extends StatelessWidget {
  final double size;
  final bool showText;

  const EthioClassLoading({super.key, this.size = 12.0, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BouncingDots(size: size, color: AppColors.primary),
          if (showText) ...[
            const SizedBox(height: 20),
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
            const Text(
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

class BouncingDots extends StatefulWidget {
  final double size;
  final Color color;
  const BouncingDots({super.key, this.size = 12.0, required this.color});

  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double offset = index * 0.15;
        double t = (_controller.value - offset);
        if (t < 0) t += 1.0;

        double y = 0.0;
        if (t < 0.5) {
          y = -sin((t / 0.5) * pi) * (widget.size * 1.5);
        }

        return Transform.translate(
          offset: Offset(0, y),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: widget.size * 0.4),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => _buildDot(i)),
    );
  }
}
