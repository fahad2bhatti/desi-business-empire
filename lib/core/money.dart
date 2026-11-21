/// All game money is integer paisa (1 PKR = 100 paisa). Never use double.
const int paisaPerRupee = 100;

/// Whole rupees to paisa.
int rupees(int pkr) => pkr * paisaPerRupee;

/// `123456` -> `Rs 1,234.56`, `124000` -> `Rs 1,240`, `-12000` -> `− Rs 120`.
String formatRs(int paisa) {
  final abs = paisa.abs();
  final digits = (abs ~/ paisaPerRupee).toString();
  final frac = abs % paisaPerRupee;
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final fracText = frac == 0 ? '' : '.${frac.toString().padLeft(2, '0')}';
  return '${paisa < 0 ? '− ' : ''}Rs $buf$fracText';
}

/// Short money in the South Asian system, for headers and cards:
/// `Rs 950`, `Rs 12.5K`, `Rs 3.4 lakh`, `Rs 7.8 crore`, `Rs 1.2 arab`,
/// `Rs 36 kharab`. Use [formatRs] where the exact value matters.
String formatShort(int paisa) {
  final negative = paisa < 0;
  final rs = paisa.abs() / paisaPerRupee;
  String out;
  String scaled(double v, String unit) {
    final digits = v >= 100 ? 0 : (v >= 10 ? 1 : 2);
    var text = v.toStringAsFixed(digits);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return 'Rs $text$unit';
  }

  if (rs < 10000) {
    out = formatRs(paisa.abs() - paisa.abs() % paisaPerRupee);
  } else if (rs < 100000) {
    out = scaled(rs / 1000, 'K');
  } else if (rs < 10000000) {
    out = scaled(rs / 100000, ' lakh');
  } else if (rs < 1000000000) {
    out = scaled(rs / 10000000, ' crore');
  } else if (rs < 100000000000) {
    out = scaled(rs / 1000000000, ' arab');
  } else {
    out = scaled(rs / 100000000000, ' kharab');
  }
  return negative ? '− $out' : out;
}
