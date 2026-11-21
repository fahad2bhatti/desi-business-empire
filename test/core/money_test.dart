import 'package:desi_business_empire/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rupees converts to paisa', () {
    expect(rupees(30), 3000);
  });

  test('formatRs groups thousands and hides zero paisa', () {
    expect(formatRs(0), 'Rs 0');
    expect(formatRs(3000), 'Rs 30');
    expect(formatRs(124000), 'Rs 1,240');
    expect(formatRs(500000000), 'Rs 5,000,000');
  });

  test('formatRs shows paisa and negatives without losing precision', () {
    expect(formatRs(123456), 'Rs 1,234.56');
    expect(formatRs(1205), 'Rs 12.05');
    expect(formatRs(-12000), '− Rs 120');
  });
}
