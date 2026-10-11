import 'dart:async';

import 'package:get/get.dart';

import '../model/deal_model.dart';
import 'cart_service.dart';

class FlashSaleService extends GetxService {
  FlashSaleService({required this.cartService});

  final CartService cartService;

  final expiredDealIds = <int>{}.obs;
  final Map<int, DateTime> _endsAtByDeal = {};
  final Map<int, String> _namesByDeal = {};
  final Map<int, RxInt> _remainingSecondsByDeal = {};
  final RxInt _expiredCountdown = 0.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  RxInt track(DealModel deal) {
    final endsAt = deal.flashSaleEndsAt;
    if (endsAt == null) {
      throw ArgumentError.value(deal.id, 'deal', 'Deal is not a flash sale');
    }
    if (expiredDealIds.contains(deal.id)) return _expiredCountdown;

    _endsAtByDeal[deal.id] = endsAt;
    _namesByDeal[deal.id] = deal.name;
    final remaining = _remainingSecondsByDeal.putIfAbsent(
      deal.id,
      () => _secondsUntil(endsAt).obs,
    );
    if (remaining.value == 0) {
      scheduleMicrotask(() => _expire(deal.id));
    }
    return remaining;
  }

  bool isExpired(DealModel deal) {
    final endsAt = deal.flashSaleEndsAt;
    return endsAt != null &&
        (!endsAt.isAfter(DateTime.now()) ||
            expiredDealIds.contains(deal.id));
  }

  static int _secondsUntil(DateTime end) {
    final milliseconds = end.difference(DateTime.now()).inMilliseconds;
    return milliseconds > 0 ? (milliseconds + 999) ~/ 1000 : 0;
  }

  static String formatCountdown(int seconds) {
    if (seconds <= 0) return 'Expired';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _tick() {
    for (final entry in _endsAtByDeal.entries.toList()) {
      final seconds = _secondsUntil(entry.value);
      final remaining = _remainingSecondsByDeal[entry.key]!;
      if (remaining.value != seconds) {
        remaining.value = seconds;
      }
      if (seconds == 0) {
        _expire(entry.key);
      }
    }
  }

  void _expire(int dealId) {
    if (expiredDealIds.contains(dealId)) return;
    expiredDealIds.add(dealId);

    final name = _namesByDeal[dealId] ?? 'Flash-sale deal';
    final wasInBag = cartService.items.any((item) => item.deal.id == dealId);
    _endsAtByDeal.remove(dealId);
    _namesByDeal.remove(dealId);
    _remainingSecondsByDeal.remove(dealId);
    if (!wasInBag) return;

    cartService.remove(dealId);
    Get.snackbar(
      'Flash sale ended',
      '$name was removed from your bag because the sale expired.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
