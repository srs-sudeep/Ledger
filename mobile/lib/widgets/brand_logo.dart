import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 64,
    this.borderRadius,
  });

  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.22;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/brand/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
