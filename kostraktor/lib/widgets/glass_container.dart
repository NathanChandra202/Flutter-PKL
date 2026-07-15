import 'package:flutter/material.dart';


class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultRadius = BorderRadius.circular(16);
    
    Widget container = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? defaultRadius,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      container = InkWell(
        onTap: onTap,
        borderRadius: (borderRadius as BorderRadius?) ?? defaultRadius,
        child: container,
      );
    }

    return container;
  }
}

