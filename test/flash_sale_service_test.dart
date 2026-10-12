import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/flash_sale_service.dart';

void main() {
  test('formats countdowns as mm:ss or hh:mm:ss', () {
    expect(FlashSaleService.formatCountdown(0), 'Expired');
    expect(FlashSaleService.formatCountdown(59), '00:59');
    expect(FlashSaleService.formatCountdown(3600), '01:00:00');
  });

  test('marks a deal expired when it is tracked after its deadline', () async {
    final service = FlashSaleService(cartService: CartService());
    final deal = DealModel.fromJson({
      'id': 42,
      'flashSaleEndsAt':
          DateTime.now().subtract(const Duration(seconds: 1)).toIso8601String(),
      'pickupWindow': {
        'start': '2026-10-12T03:00:00.000Z',
        'end': '2026-10-12T06:00:00.000Z',
      },
    });

    final remaining = service.track(deal);
    await Future<void>.delayed(Duration.zero);

    expect(remaining.value, 0);
    expect(service.expiredDealIds, contains(42));
    service.onClose();
  });

  testWidgets('expired deals still provide a reactive dependency to Obx',
      (tester) async {
    final service = FlashSaleService(cartService: CartService());
    final deal = DealModel.fromJson({
      'id': 43,
      'flashSaleEndsAt':
          DateTime.now().subtract(const Duration(seconds: 1)).toIso8601String(),
      'pickupWindow': {
        'start': '2026-10-12T03:00:00.000Z',
        'end': '2026-10-12T06:00:00.000Z',
      },
    });
    service.track(deal);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Obx(
          () => Text(service.isExpired(deal) ? 'Expired' : 'Active'),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Expired'), findsOneWidget);
    service.onClose();
  });
}
