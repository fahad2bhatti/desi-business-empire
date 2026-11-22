import 'package:flutter/material.dart';

import 'art_extra.dart';

enum _Kind { rickshaw, taxi, loader, bus, hatchback, sedan, suv, sports, truck }

class _Spec {
  const _Spec(this.kind, this.body);
  final _Kind kind;
  final Color body;
}

/// Ids that have a drawn vehicle instead of a glyph icon.
const _specs = <String, _Spec>{
  'rickshaw': _Spec(_Kind.rickshaw, Color(0xFF3F8F6B)),
  'taxi': _Spec(_Kind.taxi, Color(0xFFD8DEE6)),
  'loader': _Spec(_Kind.loader, Color(0xFF4F7FC4)),
  'bus': _Spec(_Kind.bus, Color(0xFFC9524A)),
  'rentacar': _Spec(_Kind.hatchback, Color(0xFF6C7AD0)),
  'transport': _Spec(_Kind.truck, Color(0xFF5B6B7C)),
  'car': _Spec(_Kind.hatchback, Color(0xFF4F7FC4)),
  'sedan': _Spec(_Kind.sedan, Color(0xFF2F3B4A)),
  'suv': _Spec(_Kind.suv, Color(0xFF3F8F6B)),
  'sportscar': _Spec(_Kind.sports, Color(0xFFC9524A)),
};

bool hasVehicleArt(String id) =>
    _specs.containsKey(id) || extraArt.containsKey(id);

/// Flat side-view vehicle drawn in code (no asset files). Fits [width];
/// height is 60% of it.
class VehicleArt extends StatelessWidget {
  const VehicleArt({super.key, required this.id, required this.width});

  final String id;
  final double width;

  @override
  Widget build(BuildContext context) {
    final spec = _specs[id];
    final extra = extraArt[id];
    if (spec == null && extra == null) return const SizedBox.shrink();
    return SizedBox(
      width: width,
      height: width * 0.6,
      child: CustomPaint(
        painter: spec != null ? _VehiclePainter(spec) : _ExtraPainter(extra!),
      ),
    );
  }
}

class _VehiclePainter extends CustomPainter {
  _VehiclePainter(this.spec);

  final _Spec spec;

  static const _glass = Color(0xFFBFD6EA);
  static const _tyre = Color(0xFF1B2128);
  static const _hub = Color(0xFFAAB4C0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final body = Paint()..color = spec.body;
    final dark = Paint()
      ..color = Color.lerp(spec.body, const Color(0xFF000000), 0.25)!;
    final glass = Paint()..color = _glass;

    switch (spec.kind) {
      case _Kind.hatchback:
        _car(canvas, body, glass, cabin: [24, 30, 32, 17, 66, 17, 80, 30]);
      case _Kind.sedan:
        _car(canvas, body, glass, cabin: [26, 30, 38, 16, 64, 16, 78, 30]);
      case _Kind.taxi:
        _car(canvas, body, glass, cabin: [26, 30, 38, 16, 64, 16, 78, 30]);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(44, 10, 12, 6),
            const Radius.circular(1.5),
          ),
          dark,
        );
        canvas.drawRect(const Rect.fromLTWH(6, 36, 88, 3), dark);
      case _Kind.suv:
        _car(
          canvas,
          body,
          glass,
          cabin: [20, 30, 24, 12, 72, 12, 84, 30],
          top: 28,
          wheelR: 8.5,
        );
      case _Kind.sports:
        _car(
          canvas,
          body,
          glass,
          cabin: [32, 36, 46, 22, 66, 22, 80, 36],
          top: 36,
          bottom: 47,
        );
      case _Kind.rickshaw:
        _rickshaw(canvas, body, dark, glass);
      case _Kind.loader:
        _loader(canvas, body, dark, glass);
      case _Kind.bus:
        _bus(canvas, body, dark, glass);
      case _Kind.truck:
        _truck(canvas, body, dark, glass);
    }
  }

  void _wheel(Canvas c, double x, double y, double r) {
    c.drawCircle(Offset(x, y), r, Paint()..color = _tyre);
    c.drawCircle(Offset(x, y), r * 0.45, Paint()..color = _hub);
  }

  void _poly(Canvas c, List<double> p, Paint paint) {
    final path = Path()..moveTo(p[0], p[1]);
    for (var i = 2; i < p.length; i += 2) {
      path.lineTo(p[i], p[i + 1]);
    }
    c.drawPath(path..close(), paint);
  }

  void _car(
    Canvas c,
    Paint body,
    Paint glass, {
    required List<double> cabin,
    double top = 30,
    double bottom = 46,
    double wheelR = 8,
  }) {
    _poly(c, cabin, body);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(6, top, 94, bottom),
        const Radius.circular(5),
      ),
      body,
    );
    // Windows: one pane per half of the cabin.
    final x0 = cabin[2] + 3, x1 = cabin[4] - 3;
    final y0 = cabin[3] + 3, y1 = top - 2;
    final mid = (x0 + x1) / 2;
    _poly(c, [x0 - 2, y1, x0 + 2, y0, mid - 1.5, y0, mid - 1.5, y1], glass);
    _poly(c, [mid + 1.5, y1, mid + 1.5, y0, x1 - 2, y0, x1 + 4, y1], glass);
    _wheel(c, 27, bottom, wheelR);
    _wheel(c, 73, bottom, wheelR);
  }

  void _rickshaw(Canvas c, Paint body, Paint dark, Paint glass) {
    final path = Path()
      ..moveTo(10, 44)
      ..lineTo(12, 33)
      ..quadraticBezierTo(14, 28, 22, 27)
      ..lineTo(32, 14)
      ..lineTo(82, 14)
      ..quadraticBezierTo(90, 14, 90, 22)
      ..lineTo(90, 44)
      ..close();
    c.drawPath(path, body);
    c.drawRect(const Rect.fromLTWH(30, 10, 58, 5), dark);
    _poly(c, [35, 19, 40, 19, 40, 31, 28, 31], glass);
    c.drawRect(const Rect.fromLTWH(46, 19, 14, 12), glass);
    c.drawRect(const Rect.fromLTWH(66, 19, 16, 12), glass);
    _wheel(c, 20, 47, 7);
    _wheel(c, 72, 47, 7);
  }

  void _loader(Canvas c, Paint body, Paint dark, Paint glass) {
    c.drawRect(const Rect.fromLTWH(4, 24, 52, 20), dark);
    c.drawRect(const Rect.fromLTWH(4, 24, 52, 4), body);
    final cab = Path()
      ..moveTo(58, 44)
      ..lineTo(58, 16)
      ..lineTo(76, 16)
      ..lineTo(90, 32)
      ..quadraticBezierTo(95, 34, 95, 40)
      ..lineTo(95, 44)
      ..close();
    c.drawPath(cab, body);
    _poly(c, [62, 20, 74, 20, 84, 31, 62, 31], glass);
    _wheel(c, 22, 46, 8);
    _wheel(c, 78, 46, 8);
  }

  void _bus(Canvas c, Paint body, Paint dark, Paint glass) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 10, 92, 36),
        const Radius.circular(6),
      ),
      body,
    );
    for (var i = 0; i < 5; i++) {
      c.drawRect(Rect.fromLTWH(10.0 + i * 14, 16, 11, 12), glass);
    }
    c.drawRect(const Rect.fromLTWH(82, 16, 10, 20), glass);
    c.drawRect(const Rect.fromLTWH(4, 34, 92, 3), dark);
    _wheel(c, 26, 47, 7);
    _wheel(c, 74, 47, 7);
  }

  void _truck(Canvas c, Paint body, Paint dark, Paint glass) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 8, 62, 36),
        const Radius.circular(3),
      ),
      body,
    );
    c.drawRect(const Rect.fromLTWH(2, 30, 62, 3), dark);
    final cab = Path()
      ..moveTo(66, 44)
      ..lineTo(66, 16)
      ..lineTo(84, 16)
      ..lineTo(96, 30)
      ..lineTo(96, 44)
      ..close();
    c.drawPath(cab, dark);
    _poly(c, [70, 20, 82, 20, 90, 30, 70, 30], glass);
    _wheel(c, 18, 46, 7);
    _wheel(c, 44, 46, 7);
    _wheel(c, 80, 46, 7);
  }

  @override
  bool shouldRepaint(_VehiclePainter old) => old.spec != spec;
}

class _ExtraPainter extends CustomPainter {
  _ExtraPainter(this.draw);

  final ArtFn draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    draw(canvas);
  }

  @override
  bool shouldRepaint(_ExtraPainter old) => old.draw != draw;
}
