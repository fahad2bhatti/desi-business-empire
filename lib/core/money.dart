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
