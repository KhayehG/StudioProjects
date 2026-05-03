import 'package:flutter/material.dart';

class NeuCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool inset;
  final bool small;

  const NeuCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.inset = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow>? outerShadows;
    if (!inset) {
      if (small) {
        outerShadows = const <BoxShadow>[
          BoxShadow(
            color: Color(0xFFD1D3D8),
            offset: Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
        ];
      } else {
        outerShadows = const <BoxShadow>[
          BoxShadow(
            color: Color(0xFFD1D3D8),
            offset: Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-6, -6),
            blurRadius: 12,
          ),
        ];
      }
    } else {
      outerShadows = null;
    }

    final Widget content = inset
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0xFFD1D3D8),
                  offset: Offset(4, 4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: child,
          )
        : child;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF0),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: outerShadows,
        ),
        child: content,
      ),
    );
  }
}

class GlassCard extends NeuCard {
  const GlassCard({
    super.key,
    required super.child,
    super.width,
    super.height,
    super.padding,
    super.margin,
    super.borderRadius,
    super.onTap,
  });
}
