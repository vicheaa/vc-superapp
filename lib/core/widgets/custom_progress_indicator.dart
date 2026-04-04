import 'dart:math' as math;
import 'dart:ui' show clampDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vc_super_app/core/theme/app_colors.dart';

// ignore_for_file: no_leading_underscores_for_local_identifiers

const int _kIndeterminateLinearDuration = 1800;
const int _kIndeterminateCircularDuration = 1333 * 2222;

/// A base class for custom progress indicators.
abstract class AppProgressIndicator extends StatefulWidget {
  const AppProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.valueColor,
    this.semanticsLabel,
    this.semanticsValue,
    this.gradient,
    this.glowColor,
    this.glowSize = 0.0,
  });

  final double? value;
  final Color? backgroundColor;
  final Color? color;
  final Animation<Color?>? valueColor;
  final String? semanticsLabel;
  final String? semanticsValue;

  /// Custom gradient for the indicator.
  final Gradient? gradient;

  /// Optional glow effect color.
  final Color? glowColor;

  /// Size of the glow effect.
  final double glowSize;

  Color _getValueColor(BuildContext context) {
    return valueColor?.value ??
        color ??
        ProgressIndicatorTheme.of(context).color ??
        Theme.of(context).colorScheme.primary;
  }

  Widget _buildSemanticsWrapper({required BuildContext context, required Widget child}) {
    String? expandedSemanticsValue = semanticsValue;
    if (value != null) {
      expandedSemanticsValue ??= '${(value! * 100).round()}%';
    }
    return Semantics(label: semanticsLabel, value: expandedSemanticsValue, child: child);
  }
}

class _AppCircularProgressIndicatorPainter extends CustomPainter {
  _AppCircularProgressIndicatorPainter({
    this.trackColor,
    required this.valueColor,
    required this.value,
    required this.headValue,
    required this.tailValue,
    required this.offsetValue,
    required this.rotationValue,
    required this.strokeWidth,
    required this.strokeAlign,
    this.strokeCap,
    this.gradient,
    this.glowColor,
    this.glowSize = 0.0,
  }) : arcStart = value != null
           ? _startAngle
           : _startAngle +
                 tailValue * 3 / 2 * math.pi +
                 rotationValue * math.pi * 2.0 +
                 offsetValue * 0.5 * math.pi,
       arcSweep = value != null
           ? (value < 0.001 ? 0.001 : (value > 0.999 ? 0.999 * _twoPi : value * _twoPi))
           : math.max(headValue * 3 / 2 * math.pi - tailValue * 3 / 2 * math.pi, _epsilon);

  final Color? trackColor;
  final Color valueColor;
  final double? value;
  final double headValue;
  final double tailValue;
  final double offsetValue;
  final double rotationValue;
  final double strokeWidth;
  final double strokeAlign;
  final double arcStart;
  final double arcSweep;
  final StrokeCap? strokeCap;
  final Gradient? gradient;
  final Color? glowColor;
  final double glowSize;

  static const double _twoPi = math.pi * 2.0;
  static const double _epsilon = .001;
  static const double _startAngle = -math.pi / 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap ?? StrokeCap.round;

    final double strokeOffset = strokeWidth / 2 * -strokeAlign;
    final Offset arcBaseOffset = Offset(strokeOffset, strokeOffset);
    final Size arcActualSize = Size(size.width - strokeOffset * 2, size.height - strokeOffset * 2);
    final Rect rect = arcBaseOffset & arcActualSize;

    if (trackColor != null) {
      final Paint backgroundPaint = Paint()
        ..color = trackColor!
        ..strokeWidth = strokeWidth
        ..strokeCap = strokeCap ?? StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, 0, _twoPi, false, backgroundPaint);
    }

    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = valueColor;
    }

    // Glow Effect
    if (glowSize > 0 && (glowColor != null || gradient != null)) {
      final Paint glowPaint = Paint()
        ..strokeWidth = strokeWidth + glowSize
        ..style = PaintingStyle.stroke
        ..strokeCap = strokeCap ?? StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSize);
      
      if (gradient != null) {
        glowPaint.shader = gradient!.createShader(rect);
      } else {
        glowPaint.color = glowColor ?? valueColor.withAlpha(128);
      }
      
      canvas.drawArc(rect, arcStart, arcSweep, false, glowPaint);
    }

    canvas.drawArc(rect, arcStart, arcSweep, false, paint);
  }

  @override
  bool shouldRepaint(_AppCircularProgressIndicatorPainter oldPainter) {
    return oldPainter.trackColor != trackColor ||
        oldPainter.valueColor != valueColor ||
        oldPainter.value != value ||
        oldPainter.headValue != headValue ||
        oldPainter.tailValue != tailValue ||
        oldPainter.offsetValue != offsetValue ||
        oldPainter.rotationValue != rotationValue ||
        oldPainter.strokeWidth != strokeWidth ||
        oldPainter.strokeAlign != strokeAlign ||
        oldPainter.strokeCap != strokeCap ||
        oldPainter.glowSize != glowSize ||
        oldPainter.glowColor != glowColor;
  }
}

class AppCircularProgressIndicator extends AppProgressIndicator {
  const AppCircularProgressIndicator({
    super.key,
    super.value,
    super.backgroundColor,
    super.color,
    super.valueColor,
    this.strokeWidth = 3.0,
    this.strokeAlign = 0.0,
    super.semanticsLabel,
    super.semanticsValue,
    this.strokeCap,
    this.constraints,
    super.gradient,
    super.glowColor,
    super.glowSize = 0.0,
  });

  final double strokeWidth;
  final double strokeAlign;
  final StrokeCap? strokeCap;
  final BoxConstraints? constraints;

  @override
  State<AppCircularProgressIndicator> createState() => _AppCircularProgressIndicatorState();
}

class _AppCircularProgressIndicatorState extends State<AppCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  
  static const int _pathCount = _kIndeterminateCircularDuration ~/ 1333;
  static const int _rotationCount = _kIndeterminateCircularDuration ~/ 2222;

  static final Animatable<double> _strokeHeadTween = CurveTween(
    curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
  ).chain(CurveTween(curve: const SawTooth(_pathCount)));
  
  static final Animatable<double> _strokeTailTween = CurveTween(
    curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
  ).chain(CurveTween(curve: const SawTooth(_pathCount)));
  
  static final Animatable<double> _offsetTween = CurveTween(curve: const SawTooth(_pathCount));
  
  static final Animatable<double> _rotationTween = CurveTween(
    curve: const SawTooth(_rotationCount),
  );

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _kIndeterminateCircularDuration),
      vsync: this,
    );
    if (widget.value == null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AppCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.value != null && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIndicator(
    BuildContext context,
    double headValue,
    double tailValue,
    double offsetValue,
    double rotationValue,
  ) {
    final Color? trackColor = widget.backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100);

    return widget._buildSemanticsWrapper(
      context: context,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.neutral10,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: widget.constraints ?? const BoxConstraints(minWidth: 42.0, minHeight: 42.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomPaint(
            painter: _AppCircularProgressIndicatorPainter(
              trackColor: trackColor,
              valueColor: widget._getValueColor(context),
              value: widget.value,
              headValue: headValue,
              tailValue: tailValue,
              offsetValue: offsetValue,
              rotationValue: rotationValue,
              strokeWidth: widget.strokeWidth,
              strokeAlign: widget.strokeAlign,
              strokeCap: widget.strokeCap,
              gradient: widget.gradient,
              glowColor: widget.glowColor,
              glowSize: widget.glowSize,
            )
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != null) {
      return _buildIndicator(context, 0.0, 0.0, 0, 0.0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return _buildIndicator(
          context,
          _strokeHeadTween.evaluate(_controller),
          _strokeTailTween.evaluate(_controller),
          _offsetTween.evaluate(_controller),
          _rotationTween.evaluate(_controller),
        );
      },
    );
  }
}

class _AppLinearProgressIndicatorPainter extends CustomPainter {
  const _AppLinearProgressIndicatorPainter({
    required this.trackColor,
    required this.valueColor,
    this.value,
    required this.animationValue,
    required this.textDirection,
    this.indicatorBorderRadius,
    this.gradient,
    this.glowColor,
    this.glowSize = 0.0,
  });

  final Color trackColor;
  final Color valueColor;
  final double? value;
  final double animationValue;
  final TextDirection textDirection;
  final BorderRadiusGeometry? indicatorBorderRadius;
  final Gradient? gradient;
  final Color? glowColor;
  final double glowSize;

  static const Curve line1Head = Interval(
    0.0,
    750.0 / _kIndeterminateLinearDuration,
    curve: Cubic(0.2, 0.0, 0.8, 1.0),
  );
  static const Curve line1Tail = Interval(
    333.0 / _kIndeterminateLinearDuration,
    (333.0 + 750.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.4, 0.0, 1.0, 1.0),
  );
  static const Curve line2Head = Interval(
    1000.0 / _kIndeterminateLinearDuration,
    (1000.0 + 567.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.0, 0.0, 0.65, 1.0),
  );
  static const Curve line2Tail = Interval(
    1267.0 / _kIndeterminateLinearDuration,
    (1267.0 + 533.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.10, 0.0, 0.45, 1.0),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    
    final Rect trackRect = Offset.zero & size;
    if (indicatorBorderRadius != null) {
      canvas.drawRRect(indicatorBorderRadius!.resolve(textDirection).toRRect(trackRect), trackPaint);
    } else {
      canvas.drawRect(trackRect, trackPaint);
    }

    void drawIndicator({required double startFraction, required double endFraction}) {
      if (endFraction - startFraction <= 0) return;

      final bool isLtr = textDirection == TextDirection.ltr;
      final double left = (isLtr ? startFraction : 1 - endFraction) * size.width;
      final double right = (isLtr ? endFraction : 1 - startFraction) * size.width;
      final Rect rect = Rect.fromLTRB(left, 0, right, size.height);

      final Paint paint = Paint()..style = PaintingStyle.fill;
      if (gradient != null) {
        paint.shader = gradient!.createShader(Offset.zero & size);
      } else {
        paint.color = valueColor;
      }

      // Glow 
      if (glowSize > 0) {
        final Paint glowPaint = Paint()
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSize);
        
        if (gradient != null) {
          glowPaint.shader = gradient!.createShader(Offset.zero & size);
        } else {
          glowPaint.color = glowColor ?? valueColor.withAlpha(128);
        }

        final Rect glowRect = rect.inflate(glowSize / 2);
        if (indicatorBorderRadius != null) {
          canvas.drawRRect(indicatorBorderRadius!.resolve(textDirection).toRRect(glowRect), glowPaint);
        } else {
          canvas.drawRect(glowRect, glowPaint);
        }
      }

      if (indicatorBorderRadius != null) {
        canvas.drawRRect(indicatorBorderRadius!.resolve(textDirection).toRRect(rect), paint);
      } else {
        canvas.drawRect(rect, paint);
      }
    }

    if (value != null) {
      drawIndicator(startFraction: 0.0, endFraction: clampDouble(value!, 0.0, 1.0));
    } else {
      final double head1 = line1Head.transform(animationValue);
      final double tail1 = line1Tail.transform(animationValue);
      final double head2 = line2Head.transform(animationValue);
      final double tail2 = line2Tail.transform(animationValue);
      
      drawIndicator(startFraction: tail1, endFraction: head1);
      drawIndicator(startFraction: tail2, endFraction: head2);
    }
  }

  @override
  bool shouldRepaint(_AppLinearProgressIndicatorPainter oldPainter) {
    return oldPainter.trackColor != trackColor ||
        oldPainter.valueColor != valueColor ||
        oldPainter.value != value ||
        oldPainter.animationValue != animationValue ||
        oldPainter.indicatorBorderRadius != indicatorBorderRadius;
  }
}

class AppLinearProgressIndicator extends AppProgressIndicator {
  const AppLinearProgressIndicator({
    super.key,
    super.value,
    super.backgroundColor,
    super.color,
    super.valueColor,
    this.minHeight,
    super.semanticsLabel,
    super.semanticsValue,
    this.borderRadius,
    super.gradient,
    super.glowColor,
    super.glowSize = 0.0,
  });

  final double? minHeight;
  final BorderRadiusGeometry? borderRadius;

  @override
  State<AppLinearProgressIndicator> createState() => _AppLinearProgressIndicatorState();
}

class _AppLinearProgressIndicatorState extends State<AppLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _kIndeterminateLinearDuration),
      vsync: this,
    );
    if (widget.value == null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AppLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.value != null && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIndicator(BuildContext context, double animationValue, TextDirection textDirection) {
    final Color trackColor = widget.backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant.withAlpha(100);
    final double minHeight = widget.minHeight ?? 4.0;

    return widget._buildSemanticsWrapper(
      context: context,
      child: Container(
        constraints: BoxConstraints(minWidth: double.infinity, minHeight: minHeight),
        child: CustomPaint(
          painter: _AppLinearProgressIndicatorPainter(
            trackColor: trackColor,
            valueColor: widget._getValueColor(context),
            value: widget.value,
            animationValue: animationValue,
            textDirection: textDirection,
            indicatorBorderRadius: widget.borderRadius,
            gradient: widget.gradient,
            glowColor: widget.glowColor,
            glowSize: widget.glowSize,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);

    if (widget.value != null) {
      return _buildIndicator(context, 0.0, textDirection);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return _buildIndicator(context, _controller.value, textDirection);
      },
    );
  }
}
