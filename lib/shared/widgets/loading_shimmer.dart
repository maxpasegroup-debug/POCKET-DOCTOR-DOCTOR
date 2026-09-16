import 'package:flutter/material.dart';

/// Decorative placeholders only: no previous account data is rendered.
class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key, required this.label, this.height});
  final String label;
  final double? height;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget block(double height, {double widthFactor = 1}) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final skeleton = widget.height != null
        ? block(widget.height!)
        : ListView(
            padding: const EdgeInsets.all(20),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              block(28, widthFactor: .6),
              const SizedBox(height: 12),
              block(16, widthFactor: .85),
              const SizedBox(height: 28),
              for (var i = 0; i < 3; i++) ...[
                block(100),
                const SizedBox(height: 20),
              ],
            ],
          );
    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            child: skeleton,
            builder: (context, child) => ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-3 + controller.value * 6, 0),
                end: Alignment(-1 + controller.value * 6, 0),
                colors: [
                  colors.surfaceContainerHighest,
                  colors.surfaceContainerLow,
                  colors.surfaceContainerHighest,
                ],
              ).createShader(bounds),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
