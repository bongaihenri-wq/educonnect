// lib/presentation/widgets/responsive_dialog.dart
import 'package:flutter/material.dart';

class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final double maxWidthPercent;
  final double maxHeightPercent;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.maxWidthPercent = 0.92,
    this.maxHeightPercent = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: screenWidth * maxWidthPercent,
        constraints: BoxConstraints(
          maxHeight: screenHeight * maxHeightPercent,
        ),
        child: child,
      ),
    );
  }
}