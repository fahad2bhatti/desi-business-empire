import 'package:desi_business_empire/app/theme.dart';
import 'package:desi_business_empire/features/common/money_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('money header shows cash, income and an accessible summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: MoneyHeader(
            empireName: 'Chaudhry Group',
            cashPaisa: 34000000,
            incomePaisaPerSec: 4700,
            netWorthPaisa: 40000000,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rs 3.4 lakh'), findsOneWidget);
    expect(find.text('+Rs 47/s'), findsOneWidget);
    expect(find.text('Chaudhry Group'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Cash Rs 340,000 virtual PKR, earning Rs 47 a second',
      ),
      findsOneWidget,
    );
  });

  test('text and buttons keep readable contrast', () {
    double contrast(Color a, Color b) {
      final l1 = a.computeLuminance(), l2 = b.computeLuminance();
      return (l1 > l2 ? l1 + 0.05 : l2 + 0.05) /
          (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
    }

    const p = AppPalette.night;
    expect(contrast(p.ink, p.background), greaterThanOrEqualTo(4.5));
    expect(contrast(p.inkMuted, p.surface), greaterThanOrEqualTo(4.5));
    expect(contrast(p.inkMuted, p.surfaceRaised), greaterThanOrEqualTo(4.5));
    expect(contrast(p.onGold, p.gold), greaterThanOrEqualTo(4.5));
    expect(contrast(p.onIncome, p.income), greaterThanOrEqualTo(4.5));
    expect(contrast(p.gold, p.surface), greaterThanOrEqualTo(4.5));
    expect(contrast(p.income, p.surface), greaterThanOrEqualTo(4.5));
    expect(contrast(p.danger, p.surfaceRaised), greaterThanOrEqualTo(4.5));
  });
}
