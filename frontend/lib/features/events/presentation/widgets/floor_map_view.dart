import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/campus_map_data.dart';
import '../../models/campus_map.dart';

/// Interactive indoor map for a single [MapRoom]: the floor SVG with a
/// destination pin and a static dotted route from the floor's start point.
/// Pinch to zoom, drag to pan.
class FloorMapView extends StatelessWidget {
  final MapRoom room;
  final double height;

  const FloorMapView({super.key, required this.room, this.height = 320});

  @override 
  Widget build(BuildContext context) {
    final floor = floorForRoom(room);
    if (floor == null) {
      return MapUnavailable(location: room.name, height: height);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        color: const Color(0xFFEEF2F4),
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 6,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: floor.mapSize.width,
                height: floor.mapSize.height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SvgPicture.asset(floor.svgAsset, fit: BoxFit.fill),
                    ),
                    Positioned.fill(
                      child: CustomPaint(painter: _RoutePainter(room)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback shown when a location can't be matched to a known room
class MapUnavailable extends StatelessWidget {
  final String location;
  final double height;

  const MapUnavailable({super.key, required this.location, this.height = 320});

  @override 
  Widget build(BuildContext context) {
    return ClipRRect( 
      borderRadius: BorderRadius.circular(12),
      child: Container ( 
        height: height, 
        width: double.infinity,
        color: const Color(0xFFEEF2F4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined, size: 44, color: Color(0xFF8A979E)),
              const SizedBox(height: 12),
              const Text(
                'map not available for this location',
                style: TextStyle(color: Color(0xff5a6d75), fontSize: 13),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  location,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff8a979e),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
}

/// Paints the dotted route, the start ("you start here") dot, and the
/// destination pin, all in the map's raw coordinate space.
class _RoutePainter extends CustomPainter {
  final MapRoom room;

  _RoutePainter(this.room);

  static const _routeColor = Color(0xFF1F2A30);
  static const _startColor = Color(0xFF2D6CDF);
  static const _pinColor = Color(0xFFD64545);

  @override 
  void paint(Canvas canvas, Size size) {
    final path = room.routePath;

    final linePaint = Paint()
      ..color = _routeColor 
      ..strokeWidth = 7 
      ..strokeCap = StrokeCap.round 
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < path.length - 1; i++) {
      _drawDashedLine(canvas, path[i], path[i + 1], linePaint);
    }

    final start = path.isNotEmpty ? path.first : room.marker;
    canvas.drawCircle(start, 17, Paint()..color = Colors.white);
    canvas.drawCircle(start, 12, Paint()..color = _startColor);

    _drawPin(canvas, room.marker);
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 15.0;
    const gap = 12.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var drawn = 0.0;

    while(drawn < total){
      final end = (drawn + dash) < total ? drawn + dash : total;
      canvas.drawLine(a + dir * drawn, a + dir * end, paint);
      drawn += dash + gap;
    }
  }

  void _drawPin(Canvas canvas, Offset tip) {
    const radius = 26.0;
    final center = Offset(tip.dx, tip.dy - 42);
    final fill = Paint()..color = _pinColor;

    final tail = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(center.dx - radius * 0.72, center.dy + radius * 0.5)
      ..lineTo(center.dx + radius * 0.72, center.dy + radius * 0.5)
      ..close();
    canvas.drawPath(tail, fill);
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle( 
      center,
      radius,
      Paint()
        ..color = Colors.white 
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(center, radius * 0.42, Paint()..color = Colors.white);
  }

  @override 
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
    oldDelegate.room != room;
}
