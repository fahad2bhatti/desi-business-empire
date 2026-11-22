import 'dart:ui';

/// Flat drawings for everything that is not a car or bus. Each draws into a
/// 100 x 60 box. Colours are fixed (artwork, not UI chrome).
typedef ArtFn = void Function(Canvas c);

Paint _p(int argb) => Paint()..color = Color(argb);
const _glass = 0xFFBFD6EA;
const _dark = 0xFF2B333D;
const _wall = 0xFFE8DCC8;
const _door = 0xFF6B4A33;

void _r(
  Canvas c,
  double l,
  double t,
  double w,
  double h,
  int col, [
  double rad = 0,
]) {
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(rad)),
    _p(col),
  );
}

void _o(Canvas c, double x, double y, double r, int col) =>
    c.drawCircle(Offset(x, y), r, _p(col));

void _poly(Canvas c, List<double> v, int col) {
  final path = Path()..moveTo(v[0], v[1]);
  for (var i = 2; i < v.length; i += 2) {
    path.lineTo(v[i], v[i + 1]);
  }
  c.drawPath(path..close(), _p(col));
}

void _windows(Canvas c, double x, double y, int cols, int rows, double gap) {
  for (var i = 0; i < cols; i++) {
    for (var j = 0; j < rows; j++) {
      _r(c, x + i * gap, y + j * gap, 5, 5, _glass, 1);
    }
  }
}

ArtFn _house(double w, int roof, {int floors = 1, int wall = _wall}) => (c) {
  final x = (100 - w) / 2;
  final h = 16.0 * floors;
  final top = 54 - h;
  _r(c, x, top, w, h, wall);
  _poly(c, [x - 4, top, 50, top - 14, x + w + 4, top], roof);
  _r(c, 46, 54 - 11, 8, 11, _door, 1);
  _windows(
    c,
    x + 6,
    top + 4,
    ((w - 12) / 14).floor().clamp(1, 5).toInt(),
    floors,
    14,
  );
};

ArtFn _tower(int floors, int col, {double w = 34}) => (c) {
  final x = (100 - w) / 2;
  final h = 8.0 * floors;
  _r(c, x, 56 - h, w, h, col, 2);
  _windows(c, x + 5, 56 - h + 3, ((w - 6) / 9).floor(), floors - 1, 8);
  _r(c, 46, 49, 8, 7, _door, 1);
};

final Map<String, ArtFn> extraArt = {
  'samosa': (c) {
    _poly(c, [20, 50, 50, 10, 80, 50], 0xFFD9A441);
    _poly(c, [32, 50, 50, 24, 68, 50], 0xFFC48A2C);
    _r(c, 14, 50, 72, 4, 0xFF8A6A2A, 2);
  },
  'chai': (c) {
    _r(c, 28, 20, 36, 28, 0xFFF1EEE8, 5);
    c.drawArc(
      const Rect.fromLTWH(58, 25, 18, 16),
      -1.57,
      3.14,
      false,
      _p(0xFFF1EEE8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    _r(c, 31, 23, 30, 8, 0xFFC08A52, 3);
    _r(c, 22, 48, 48, 4, 0xFFB5BDC7, 2);
    for (final x in [38.0, 46.0, 54.0]) {
      _r(c, x, 8, 2.5, 9, 0xFFB5BDC7, 1);
    }
  },
  'chaat': (c) {
    _poly(c, [16, 28, 84, 28, 74, 50, 26, 50], 0xFFB5733E);
    _o(c, 36, 24, 9, 0xFFD25A4A);
    _o(c, 52, 20, 10, 0xFFE0B03C);
    _o(c, 66, 24, 9, 0xFF5E9E5B);
    _r(c, 20, 28, 60, 4, 0xFF8A5A2E, 2);
  },
  'kiryana': (c) {
    _r(c, 14, 20, 72, 34, 0xFFE8DCC8);
    _poly(c, [10, 20, 90, 20, 84, 8, 16, 8], 0xFF3F8F6B);
    for (var i = 0; i < 4; i++) {
      _r(c, 14.0 + i * 18, 8, 9, 12, 0xFFF1EEE8);
    }
    _r(c, 22, 30, 24, 24, 0xFF4F7FC4, 2);
    _r(c, 56, 30, 22, 24, 0xFFD9A441, 2);
    _r(c, 40, 46, 20, 8, _door, 1);
  },
  'mobile': (c) {
    _r(c, 34, 4, 32, 52, _dark, 6);
    _r(c, 38, 10, 24, 36, 0xFF6C9AD8, 2);
    _o(c, 50, 51, 2.2, 0xFF94A0AE);
    _r(c, 41, 15, 18, 5, 0xFFF1EEE8, 1.5);
    _r(c, 41, 24, 18, 5, 0xFFF1EEE8, 1.5);
  },
  'cloth': (c) {
    _poly(c, [
      36,
      12,
      64,
      12,
      82,
      24,
      72,
      32,
      66,
      28,
      66,
      54,
      34,
      54,
      34,
      28,
      28,
      32,
      18,
      24,
    ], 0xFF5B7FD0);
    _poly(c, [42, 12, 50, 22, 58, 12], 0xFFE8EDF5);
  },
  'mechanic': (c) {
    _r(c, 44, 6, 12, 48, 0xFFB5BDC7, 4);
    _o(c, 50, 14, 14, 0xFFB5BDC7);
    _o(c, 50, 14, 6, 0xFF2B333D);
    _o(c, 50, 48, 9, 0xFFB5BDC7);
    _o(c, 50, 48, 4, 0xFF2B333D);
  },
  'restaurant': (c) {
    _o(c, 50, 36, 22, 0xFFF1EEE8);
    _o(c, 50, 36, 15, 0xFFD9DEE6);
    _r(c, 14, 10, 3, 40, 0xFFB5BDC7, 1.5);
    _r(c, 10, 10, 3, 14, 0xFFB5BDC7, 1.5);
    _r(c, 18, 10, 3, 14, 0xFFB5BDC7, 1.5);
    _poly(c, [83, 10, 90, 10, 90, 50, 83, 50], 0xFFB5BDC7);
  },
  'hall': (c) {
    _r(c, 14, 24, 72, 30, 0xFFE8DCC8);
    c.drawArc(
      const Rect.fromLTWH(28, 4, 44, 44),
      3.14,
      3.14,
      true,
      _p(0xFFC9524A),
    );
    _r(c, 44, 36, 12, 18, _door, 6);
    for (final x in [14.0, 80.0]) {
      _r(c, x, 14, 6, 40, 0xFFD9A441, 1);
    }
  },
  'factory': (c) {
    _r(c, 12, 28, 76, 26, 0xFF8895A4);
    _poly(c, [
      12,
      28,
      12,
      18,
      32,
      28,
      32,
      18,
      52,
      28,
      52,
      18,
      72,
      28,
    ], 0xFF8895A4);
    _r(c, 70, 8, 10, 46, 0xFF6B7785);
    _r(c, 68, 6, 14, 4, 0xFF4A5461);
    _windows(c, 18, 36, 4, 1, 14);
    _o(c, 84, 4, 4, 0x66B5BDC7);
  },
  'plot': (c) {
    _poly(c, [10, 52, 22, 28, 78, 28, 92, 52], 0xFF7FB07A);
    _poly(c, [22, 28, 78, 28, 74, 24, 26, 24], 0xFF9CC596);
    _r(c, 34, 36, 3, 14, 0xFFE8DCC8);
    _poly(c, [37, 36, 52, 41, 37, 46], 0xFFC9524A);
  },
  'shopspace': _house(60, 0xFF3F8F6B, wall: 0xFFE8DCC8),
  'house': _house(54, 0xFFC9524A),
  'apartments': _tower(5, 0xFF9AA7B6),
  'plaza': (c) {
    _tower(7, 0xFF7C8AA0, w: 28)(c);
    _r(c, 8, 34, 22, 22, 0xFF9AA7B6, 2);
    _r(c, 70, 28, 22, 28, 0xFFAAB6C4, 2);
    _windows(c, 12, 38, 2, 2, 8);
    _windows(c, 74, 32, 2, 3, 8);
  },
  'farmhouse': (c) {
    _house(44, 0xFFB5733E)(c);
    _r(c, 4, 30, 18, 24, 0xFFC9524A);
    _poly(c, [2, 30, 13, 20, 24, 30], 0xFF8A4A33);
    _r(c, 8, 38, 10, 16, 0xFFF1EEE8, 1);
  },
  'room': (c) {
    _r(c, 14, 36, 72, 12, 0xFF6B7AA0, 3);
    _r(c, 14, 28, 14, 20, 0xFF8895B8, 3);
    _r(c, 20, 30, 28, 8, 0xFFF1EEE8, 3);
    _r(c, 16, 48, 4, 6, _dark);
    _r(c, 80, 48, 4, 6, _dark);
    _r(c, 62, 8, 22, 16, 0xFFBFD6EA, 2);
  },
  'flat': _tower(4, 0xFFAAB6C4, w: 40),
  'familyhome': _house(50, 0xFF4F7FC4),
  'bungalow': _house(70, 0xFF3F8F6B),
  'villa': (c) {
    _house(70, 0xFFC9524A, floors: 2, wall: 0xFFF1EEE8)(c);
    _r(c, 4, 48, 92, 6, 0xFF7FB07A, 2);
  },
  'mansion': (c) {
    _r(c, 8, 22, 84, 32, 0xFFF1EEE8);
    _poly(c, [4, 22, 50, 6, 96, 22], 0xFF5B6B7C);
    for (final x in [24.0, 40.0, 56.0, 72.0]) {
      _r(c, x, 18, 4, 36, 0xFFD9DEE6);
    }
    _r(c, 44, 36, 12, 18, _door, 6);
    _windows(c, 14, 28, 1, 1, 10);
    _windows(c, 80, 28, 1, 1, 10);
  },
  'motorbike': (c) {
    for (final x in [24.0, 76.0]) {
      c.drawCircle(
        Offset(x, 42),
        11,
        _p(0xFF1B2128)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      _o(c, x, 42, 3, 0xFFAAB6C4);
    }
    _poly(c, [
      24,
      42,
      40,
      24,
      62,
      24,
      76,
      42,
      66,
      42,
      54,
      32,
      38,
      36,
    ], 0xFFC9524A);
    _r(c, 38, 20, 22, 6, _dark, 3);
    _r(c, 62, 16, 3, 12, _dark);
    _r(c, 58, 14, 12, 3, _dark, 1);
  },
  'watch': (c) {
    _r(c, 42, 2, 16, 56, 0xFF2B333D, 3);
    _o(c, 50, 30, 20, 0xFFD9A441);
    _o(c, 50, 30, 16, 0xFFF1EEE8);
    _r(c, 49, 18, 2, 13, _dark, 1);
    _r(c, 49, 29, 11, 2, _dark, 1);
  },
  'jewellery': (c) {
    _poly(c, [30, 10, 70, 10, 84, 26, 50, 56, 16, 26], 0xFF6CC3E0);
    _poly(c, [30, 10, 50, 26, 16, 26], 0xFF9ADBF0);
    _poly(c, [70, 10, 84, 26, 50, 26], 0xFF4FA9CB);
    _poly(c, [16, 26, 50, 26, 50, 56], 0xFF5BB6D6);
  },
  'painting': (c) {
    _r(c, 12, 8, 76, 46, 0xFF8A6A2A, 3);
    _r(c, 17, 13, 66, 36, 0xFF9CC9E6, 1);
    _poly(c, [17, 49, 40, 26, 58, 49], 0xFF5E9E5B);
    _poly(c, [44, 49, 64, 32, 83, 49], 0xFF3F7F4B);
    _o(c, 70, 22, 6, 0xFFE0B03C);
  },
  'helicopter': (c) {
    _r(c, 14, 8, 72, 3, 0xFF2B333D, 1.5);
    _r(c, 48, 10, 4, 8, _dark);
    c.drawOval(const Rect.fromLTWH(30, 16, 46, 26), _p(0xFFC9524A));
    _poly(c, [32, 24, 12, 26, 12, 32, 34, 34], 0xFFC9524A);
    _r(c, 8, 20, 4, 14, _dark, 1);
    c.drawArc(const Rect.fromLTWH(54, 19, 20, 16), 3.2, 3.2, true, _p(_glass));
    _r(c, 30, 50, 52, 3, _dark, 1.5);
    _r(c, 40, 42, 3, 8, _dark);
    _r(c, 64, 42, 3, 8, _dark);
  },
  'yacht': (c) {
    _poly(c, [8, 38, 92, 38, 80, 50, 20, 50], 0xFFF1EEE8);
    _r(c, 8, 38, 84, 3, 0xFF4F7FC4);
    _r(c, 28, 26, 40, 12, 0xFFD9DEE6, 2);
    _r(c, 34, 29, 28, 5, _glass, 1);
    _r(c, 42, 16, 14, 10, 0xFFF1EEE8, 2);
    _r(c, 49, 8, 2, 8, _dark);
    c.drawRect(const Rect.fromLTWH(0, 51, 100, 6), _p(0xFF4F7FC4));
  },
  'jet': (c) {
    c.drawOval(const Rect.fromLTWH(8, 22, 84, 14), _p(0xFFF1EEE8));
    _poly(c, [14, 26, 4, 8, 14, 8, 26, 26], 0xFFC9524A);
    _poly(c, [44, 28, 56, 28, 38, 54, 28, 54], 0xFFB5BDC7);
    _poly(c, [44, 28, 56, 28, 38, 6, 28, 6], 0xFFD9DEE6);
    _o(c, 84, 28, 3, 0xFF6C9AD8);
    _r(c, 60, 29, 14, 3, _dark, 1);
  },
};
