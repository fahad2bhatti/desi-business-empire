import 'package:desi_business_empire/widgets/wallet_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wallet chip shows virtual rupees with an accessible label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WalletChip(paisa: 124000))),
    );
    expect(find.text('Rs 1,240'), findsOneWidget);
    expect(find.text('VIRTUAL PKR'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Wallet: Rs 1,240 virtual PKR'),
      findsOneWidget,
    );
  });
}
