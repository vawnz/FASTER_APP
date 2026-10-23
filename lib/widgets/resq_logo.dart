import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResQLogo extends StatefulWidget {
  final double height;
  final bool animate;
  final bool autoPlay;
  final Object? trigger;
  final double? progress;
  final Color? textColor;
  // Legacy parameters maintained for backwards compatibility
  final double clockScale;
  final double clockOpacity;
  final double armRotationProgress;
  final double textSlideProgress;
  final double textOpacity;
  final double streaksProgress;
  final double streaksOpacity;

  const ResQLogo({
    super.key,
    this.height = 42,
    this.animate = true,
    this.autoPlay = true,
    this.trigger,
    this.progress,
    this.textColor,
    this.clockScale = 1.0,
    this.clockOpacity = 1.0,
    this.armRotationProgress = 1.0,
    this.textSlideProgress = 1.0,
    this.textOpacity = 1.0,
    this.streaksProgress = 1.0,
    this.streaksOpacity = 1.0,
  });

  @override
  State<ResQLogo> createState() => _ResQLogoState();
}

class _ResQLogoState extends State<ResQLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    if (widget.animate && widget.autoPlay && widget.progress == null) {
      _animController.value = 0.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.animate && widget.autoPlay && widget.progress == null) {
          _animController.forward(from: 0.0);
        }
      });
    } else {
      _animController.value = widget.animate ? 0.0 : 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ResQLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && widget.trigger != oldWidget.trigger && widget.progress == null) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _replay() {
    if (widget.animate && widget.progress == null) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveTextColor =
        widget.textColor ?? (isDark ? Colors.white : const Color(0xFF141416));

    final textStyle = GoogleFonts.montserrat(
      fontSize: widget.height * 0.52,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.normal,
      letterSpacing: 2.2,
      color: effectiveTextColor,
    ).copyWith(
      fontFamilyFallback: const [
        'Montserrat',
        'Roboto',
        'SF Pro Display',
        'Segoe UI',
        'Arial',
        'sans-serif',
      ],
    );

    return GestureDetector(
      onTap: _replay,
      child: SizedBox(
        height: widget.height,
        width: widget.height * 3.8,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final double animProgress = widget.progress ??
                (widget.animate ? _animController.value : 1.0);

            return CustomPaint(
              painter: _FasterLogoPainter(
                baseTextStyle: textStyle,
                animProgress: animProgress,
                textColor: effectiveTextColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FasterLogoPainter extends CustomPainter {
  final TextStyle baseTextStyle;
  final double animProgress;
  final Color textColor;

  _FasterLogoPainter({
    required this.baseTextStyle,
    required this.animProgress,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double h = size.height;
    final double fontSize = h * 0.52;

    final TextStyle layoutStyle = baseTextStyle.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.normal,
      letterSpacing: 2.2,
    );

    // Layout measurement painters for 'FAS' and 'ER'
    final TextPainter tpFAS = TextPainter(
      text: TextSpan(text: 'FAS', style: layoutStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final TextPainter tpER = TextPainter(
      text: TextSpan(text: 'ER', style: layoutStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final double wFAS = tpFAS.width;
    final double wER = tpER.width;
    final double textHeight = tpFAS.height;

    // Cross metrics (scaled up relative to text)
    final double crossRadius = h * 0.32;
    final double crossWidth = crossRadius * 2.0;
    final double gap = h * 0.16;

    // Settled Rest State Geometry
    final double totalW = wFAS + gap + crossWidth + gap + wER;
    final double startX = (size.width - totalW) / 2;
    final double centerY = size.height / 2;
    final double textY = (size.height - textHeight) / 2;

    final double xFasSettled = startX;
    final double xCrossCenter = xFasSettled + wFAS + gap + crossRadius;
    final double xCrossLeft = xCrossCenter - crossRadius;
    final double xCrossRight = xCrossCenter + crossRadius;
    final double xErSettled = xCrossRight + gap;

    final double p = animProgress.clamp(0.0, 1.0);

    // ==========================================
    // STAGE TIMINGS & INTERPOLATIONS (Reference Video)
    // ==========================================
    // Phase 1 (0.00 -> 0.25): Red Cross '+' blooms in center
    // Phase 2 (0.25 -> 0.55): 'FAS' emerges from behind the cross to the left
    // Phase 3 (0.55 -> 0.60): Slight rhythm pause
    // Phase 4 (0.60 -> 0.85): 'ER' emerges from behind the cross to the right
    // Phase 5 (0.85 -> 1.00): Fully settled 'FAS + ER' hold

    double crossAlpha = 1.0;
    double crossScale = 1.0;
    double fasAlpha = 0.0;
    double erAlpha = 0.0;
    double xFAS = xFasSettled;
    double xER = xErSettled;

    if (animProgress >= 1.0) {
      crossAlpha = 1.0;
      crossScale = 1.0;
      fasAlpha = 1.0;
      erAlpha = 1.0;
      xFAS = xFasSettled;
      xER = xErSettled;
    } else {
      if (p <= 0.25) {
        // Phase 1: Cross blooms in center (immediately visible from frame 0)
        final double t1 = (p / 0.25).clamp(0.0, 1.0);
        final double c1 = Curves.easeOutBack.transform(t1);
        crossAlpha = (0.5 + 0.5 * t1).clamp(0.0, 1.0);
        crossScale = (0.6 + 0.4 * c1).clamp(0.0, 1.15);
        fasAlpha = 0.0;
        erAlpha = 0.0;
      } else {
        crossAlpha = 1.0;
        crossScale = 1.0;

        if (p < 0.55) {
          // Phase 2: FAS emerges from behind the cross to the left
          final double t2 = ((p - 0.25) / 0.30).clamp(0.0, 1.0);
          final double c2 = Curves.easeOutCubic.transform(t2);
          fasAlpha = (t2 * 2.0).clamp(0.0, 1.0);
          // Starts tucked behind cross at xCrossLeft and slides leftward to xFasSettled
          xFAS = xCrossLeft + (xFasSettled - xCrossLeft) * c2;
          erAlpha = 0.0;
        } else if (p < 0.60) {
          // Phase 3: Beat pause
          fasAlpha = 1.0;
          xFAS = xFasSettled;
          erAlpha = 0.0;
        } else if (p < 0.85) {
          // Phase 4: ER emerges from behind the cross to the right
          fasAlpha = 1.0;
          xFAS = xFasSettled;
          final double t3 = ((p - 0.60) / 0.25).clamp(0.0, 1.0);
          final double c3 = Curves.easeOutCubic.transform(t3);
          erAlpha = (t3 * 2.0).clamp(0.0, 1.0);
          // Starts tucked behind cross at (xCrossRight - wER) and slides rightward to xErSettled
          final double xErOrigin = xCrossRight - wER;
          xER = xErOrigin + (xErSettled - xErOrigin) * c3;
        } else {
          // Phase 5: Fully settled hold
          fasAlpha = 1.0;
          xFAS = xFasSettled;
          erAlpha = 1.0;
          xER = xErSettled;
        }
      }
    }

    // 1. Draw 'FAS' on left (clipped so it physically emerges out from behind the cross)
    if (fasAlpha > 0.01) {
      canvas.save();
      if (animProgress < 1.0) {
        canvas.clipRect(Rect.fromLTRB(0, 0, xCrossLeft + 1.0, size.height));
      }
      _drawText(
        canvas,
        'FAS',
        Offset(xFAS, textY),
        fasAlpha,
        layoutStyle,
        textColor,
        h,
      );
      canvas.restore();
    }

    // 2. Draw 'ER' on right (clipped so it physically emerges out from behind the cross)
    if (erAlpha > 0.01) {
      canvas.save();
      if (animProgress < 1.0) {
        canvas.clipRect(Rect.fromLTRB(xCrossRight - 1.0, 0, size.width, size.height));
      }
      _drawText(
        canvas,
        'ER',
        Offset(xER, textY),
        erAlpha,
        layoutStyle,
        textColor,
        h,
      );
      canvas.restore();
    }

    // 3. Draw Red Emergency Medical Cross in center (drawn in front of the text)
    if (crossAlpha > 0.01) {
      _drawEmergencyCross(
        canvas,
        Offset(xCrossCenter, centerY),
        crossRadius * crossScale,
        crossAlpha,
        h,
      );
    }
  }

  void _drawEmergencyCross(
    Canvas canvas,
    Offset center,
    double r,
    double alpha,
    double height,
  ) {
    if (r <= 0.5 || alpha <= 0.01) return;
    final int a = (alpha * 255).round().clamp(0, 255);

    final double armW = r * 0.64;
    final double cornerR = armW * 0.16;

    final RRect hBar = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: r * 2.0, height: armW),
      Radius.circular(cornerR),
    );
    final RRect vBar = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: armW, height: r * 2.0),
      Radius.circular(cornerR),
    );

    final Path crossPath = Path()
      ..addRRect(hBar)
      ..addRRect(vBar);
    crossPath.fillType = PathFillType.nonZero;

    final double shadowDist = height * 0.035;

    // Soft drop shadow
    canvas.drawPath(
      crossPath.shift(Offset(shadowDist * 1.1, shadowDist * 1.3)),
      Paint()
        ..color = const Color(0x33000000).withAlpha((a * 0.35).round())
        ..style = PaintingStyle.fill,
    );

    // Fine white contour for guaranteed contrast against dark or red surfaces
    canvas.drawPath(
      crossPath,
      Paint()
        ..color = Colors.white.withAlpha((a * 0.90).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * 0.035
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Vibrant Red Core Fill
    canvas.drawPath(
      crossPath,
      Paint()
        ..color = const Color(0xFFE50914).withAlpha(a)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double alpha,
    TextStyle style,
    Color color,
    double height,
  ) {
    if (alpha <= 0.01) return;
    final int a = (alpha * 255).round().clamp(0, 255);

    final double shadowDist = height * 0.03;

    // Subtle ambient shadow
    final TextPainter shadowPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          color: Colors.black.withAlpha((a * 0.20).round()),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shadowPainter.paint(canvas, Offset(offset.dx + shadowDist, offset.dy + shadowDist));

    // Crisp text fill
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          color: color.withAlpha(a),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _FasterLogoPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress ||
        oldDelegate.textColor != textColor ||
        oldDelegate.baseTextStyle != baseTextStyle;
  }
}
