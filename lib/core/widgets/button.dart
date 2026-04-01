import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppButtonType { filled, outlined, text, dashed }

class AppButton extends StatelessWidget {
  /// The text to display inside the button
  final String text;

  /// The callback that is called when the button is tapped. If null, the button is disabled.
  final VoidCallback? onPressed;

  /// The aesthetic type of the button
  final AppButtonType type;

  /// If true, displays a loading spinner instead of the text/icon
  final bool isLoading;

  /// Optional icon to display to the left of the text
  final IconData? icon;

  /// Override the default background color
  final Color? backgroundColor;

  /// Override the default text/icon color
  final Color? foregroundColor;

  /// The border radius of the button
  final double borderRadius;

  /// Fixed width of the button (expands to fill if null)
  final double? width;

  /// Fixed height of the button
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.filled,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 30.0,
    this.width,
    this.height = 54.0,
  });

  // ──── Named Constructors for Cleaner Code ────

  const AppButton.filled({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 30.0,
    this.width,
    this.height = 54.0,
  }) : type = AppButtonType.filled;

  const AppButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 30.0,
    this.width,
    this.height = 54.0,
  }) : type = AppButtonType.outlined;

  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 30.0,
    this.width,
    this.height = 54.0,
  }) : type = AppButtonType.text;

  const AppButton.dashed({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 30.0,
    this.width,
    this.height = 54.0,
  }) : type = AppButtonType.dashed;

  // ──── Helpers ────

  bool get _isDisabled => onPressed == null || isLoading;

  Color get _effectiveBgColor =>
      backgroundColor ?? AppColors.primary400;

  Color get _effectiveFgColor =>
      foregroundColor ?? AppColors.primary400;

  Widget _buildContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: textColor,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ──── Builders ────

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: _buildButtonWidget(),
    );
  }

  Widget _buildButtonWidget() {
    switch (type) {
      case AppButtonType.filled:
        return ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _effectiveBgColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _effectiveBgColor.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 0,
          ),
          child: _buildContent(foregroundColor ?? Colors.white),
        );

      case AppButtonType.outlined:
        return OutlinedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _effectiveFgColor,
            side: BorderSide(
              color: _isDisabled ? _effectiveFgColor.withValues(alpha: 0.5) : _effectiveFgColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildContent(_effectiveFgColor),
        );

      case AppButtonType.text:
        return TextButton(
          onPressed: _isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: _effectiveFgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildContent(_effectiveFgColor),
        );

      case AppButtonType.dashed:
        final fgColor = _isDisabled ? _effectiveFgColor.withValues(alpha: 0.5) : _effectiveFgColor;
        return Material(
          color: Colors.transparent,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: fgColor,
              strokeWidth: 1.5,
              borderRadius: borderRadius,
            ),
            child: InkWell(
              onTap: _isDisabled ? null : onPressed,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Center(
                child: _buildContent(_effectiveFgColor),
              ),
            ),
          ),
        );
    }
  }
}

// ──── Internal Dashed Border Painter ────
// Used exclusively by AppButtonType.dashed

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rrect);

    final PathMetrics pathMetrics = path.computeMetrics();
    final Path dashedPath = Path();

    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
  }
}
