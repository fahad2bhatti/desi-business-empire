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
    expect(find.text('Rs 340K'), findsOneWidget);
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

    for (final p in [AppPalette.dark, AppPalette.light]) {
      final where = p.brightness.name;
      expect(
        contrast(p.ink, p.background),
        greaterThanOrEqualTo(4.5),
        reason: where,
      );
      expect(
        contrast(p.inkMuted, p.surface),
        greaterThanOrEqualTo(4.5),
        reason: where,
      );
      expect(
        contrast(p.inkMuted, p.surfaceRaised),
        greaterThanOrEqualTo(4.5),
        reason: where,
      );
      expect(
        contrast(p.onAccent, p.accent),
        greaterThanOrEqualTo(4.5),
        reason: where,
      );
      expect(
        contrast(p.accentInk, p.surface),
        greaterThanOrEqualTo(4.5),
        reason: where,
      );
      expect(
        contrast(p.income, p.surface),
        greaterThanOrEqualTo(4.5),
        reason: where,
      );
      expect(
        contrast(p.income, p.surfaceRaised),
        greaterThanOrEqualTo(4.5),
        reason: where,
      );
      expect(
        contrast(p.danger, p.surface),
        greaterThanOrEqualTo(4.5),
        reason: where,
      );
      expect(
        contrast(p.onDanger, p.danger),
        greaterThanOrEqualTo(4.5),
        reason: where,
      );
    }
  });

  testWidgets('money header renders in the light theme too', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AppPalette.light),
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
    expect(find.text('Rs 340K'), findsOneWidget);
  });
}
