import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/order/widget/pickup_countdown.dart';

void main() {
  testWidgets('stops its timer when removed from the tree', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PickupCountdown(
        pickupStart: DateTime.now().add(const Duration(minutes: 5)),
      ),
    ));

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });
}
