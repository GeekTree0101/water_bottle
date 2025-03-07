import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'water_container.dart';
import 'wave.dart';
import 'bubble.dart';

class WaterBottle extends StatefulWidget {
  /// Color of the water
  final Color waterColor;

  /// Color of the bottle
  final Color bottleColor;

  /// Color of the bottle cap
  final Color capColor;

  /// Create a regular bottle, you can customize it's part with
  /// [waterColor], [bottleColor], [capColor].
  WaterBottle(
      {Key? key,
      this.waterColor = Colors.blue,
      this.bottleColor = Colors.blue,
      this.capColor = Colors.blueGrey})
      : super(key: key);
  @override
  WaterBottleState createState() => WaterBottleState();
}

class WaterBottleState extends State<WaterBottle>
    with TickerProviderStateMixin, WaterContainer {
  @override
  void initState() {
    super.initState();
    initWater(widget.waterColor, this);
  }

  @override
  void dispose() {
    disposeWater();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        AspectRatio(
          aspectRatio: 1 / 1,
          child: AnimatedBuilder(
            animation: waves.first.animation,
            builder: (context, child) {
              return CustomPaint(
                painter: WaterBottlePainter(
                  waves: waves,
                  bubbles: bubbles,
                  waterLevel: waterLevel,
                  bottleColor: widget.bottleColor,
                  capColor: widget.capColor,
                ),
              );
            },
            child: Container(),
          ),
        ),
      ],
    );
  }
}

class WaterBottlePainter extends CustomPainter {
  /// Holds all wave object instances
  final List<WaveLayer> waves;

  /// Holds all bubble object instances
  final List<Bubble> bubbles;

  /// Water level, 0 = no water, 1 = full water
  final double waterLevel;

  /// Bottle color
  final Color bottleColor;

  /// Bottle cap color
  final Color capColor;

  WaterBottlePainter({
    Listenable? repaint,
    required this.waves,
    required this.bubbles,
    required this.waterLevel,
    required this.bottleColor,
    required this.capColor,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final bottlePaint = Paint()
      ..color = bottleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    paintEmptyBottle(canvas, size, bottlePaint);

    final maskPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(rect, maskPaint);
    paintBottleMask(canvas, size, maskPaint);

    final wavesPaint = Paint()
      ..blendMode = BlendMode.srcIn
      ..style = PaintingStyle.fill;
    for (var wave in waves) {
      final bounds = wave.svgData.getBounds();
      final desiredW = 15 * size.width;
      final desiredH = 0.1 * size.height;
      final translateRange = desiredW - size.width;
      final scaleX = desiredW / bounds.width;
      final scaleY = desiredH / bounds.height;
      final translateX = -wave.offset * translateRange;
      final waterRange = size.height + desiredH;
      final translateY = (1.0 - waterLevel) * waterRange - desiredH;
      final transform = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(scaleX, scaleY);
      wavesPaint.color = wave.color;
      canvas.drawPath(wave.svgData.transform(transform.storage), wavesPaint);

      if (wave == waves.last) {
        final gap = size.height - desiredH - translateY;
        if (gap > 0) {
          canvas.drawRect(
              Rect.fromLTWH(0, desiredH + translateY, size.width, size.height),
              wavesPaint);
        }
      }
    }

    final bubblesPaint = Paint()
      ..blendMode = BlendMode.srcATop
      ..style = PaintingStyle.fill;
    for (var bubble in bubbles) {
      bubblesPaint.color = bubble.color;
      final offset = Offset(
          bubble.x * size.width, (bubble.y + 1.0 - waterLevel) * size.height);
      final radius = bubble.size * math.min(size.width, size.height);
      canvas.drawCircle(offset, radius, bubblesPaint);
    }

    final glossyPaint = Paint()
      ..blendMode = BlendMode.srcATop
      ..style = PaintingStyle.fill;
    glossyPaint.color = Colors.white.withAlpha(20);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * 0.5, size.height), glossyPaint);
    glossyPaint.color = Colors.white.withAlpha(80);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.9, 0, size.width * 0.05, size.height),
        glossyPaint);
    final rectGradient = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
      colors: [
        Colors.white.withAlpha(180),
        Colors.white.withAlpha(0),
      ],
    ).createShader(rectGradient);
    glossyPaint
      ..shader = gradient
      ..color = Colors.white;
    canvas.drawRect(rectGradient, glossyPaint);

    canvas.restore();

    final capPaint = Paint()
      ..blendMode = BlendMode.srcATop
      ..style = PaintingStyle.fill
      ..color = capColor;
    paintCap(canvas, size, capPaint);
  }

  void paintEmptyBottle(Canvas canvas, Size size, Paint paint) {
    final neckTop = size.width * 0.1;
    final neckBottom = size.height;
    final neckRingOuter = 0.0;
    final neckRingOuterR = size.width - neckRingOuter;
    final neckRingInner = size.width * 0.1;
    final neckRingInnerR = size.width - neckRingInner;
    final path = Path();
    path.moveTo(neckRingOuter, neckTop);
    path.lineTo(neckRingInner, neckTop);
    path.lineTo(neckRingInner, neckBottom);
    path.lineTo(neckRingInnerR, neckBottom);
    path.lineTo(neckRingInnerR, neckTop);
    path.lineTo(neckRingOuterR, neckTop);
    canvas.drawPath(path, paint);
  }

  void paintBottleMask(Canvas canvas, Size size, Paint paint) {
    final neckRingInner = size.width * 0.1;
    final neckRingInnerR = size.width - neckRingInner;
    canvas.drawRect(
        Rect.fromLTRB(
            neckRingInner + 5, 0, neckRingInnerR - 5, size.height - 5),
        paint);
  }

  void paintCap(Canvas canvas, Size size, Paint paint) {
    final capTop = 0.0;
    final capBottom = size.width * 0.2;
    final capMid = (capBottom - capTop) / 2;
    final capL = size.width * 0.08 + 5;
    final capR = size.width - capL;
    final neckRingInner = size.width * 0.1 + 5;
    final neckRingInnerR = size.width - neckRingInner;
    final path = Path();
    path.moveTo(capL, capTop);
    path.lineTo(neckRingInner, capMid);
    path.lineTo(neckRingInner, capBottom);
    path.lineTo(neckRingInnerR, capBottom);
    path.lineTo(neckRingInnerR, capMid);
    path.lineTo(capR, capTop);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaterBottlePainter oldDelegate) {
    return waterLevel != oldDelegate.waterLevel ||
        bottleColor != oldDelegate.bottleColor ||
        capColor != oldDelegate.capColor ||
        waves != oldDelegate.waves ||
        bubbles != oldDelegate.bubbles;
  }
}
