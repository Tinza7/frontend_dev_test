import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../service/flash_sale_service.dart';

class FlashSaleCountdown extends StatelessWidget {
  const FlashSaleCountdown({
    super.key,
    required this.deal,
    this.style,
  });

  final DealModel deal;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final service = Get.find<FlashSaleService>();
    final remaining = service.track(deal);
    return Obx(
      () => Text(
        FlashSaleService.formatCountdown(remaining.value),
        style: style,
      ),
    );
  }
}
