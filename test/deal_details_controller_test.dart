import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/deal/deal_details_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/analytics_service.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/fake_api_service.dart';
import 'package:rescu/service/flash_sale_service.dart';

class _DealRepo extends DealRepo {
  _DealRepo() : super(api: FakeApiService());

  int? requestedId;

  @override
  Future<DealModel> fetchById(int id) async {
    requestedId = id;
    return DealModel.fromJson({
      'id': id,
      'name': 'Deep link deal',
      'pickupWindow': {
        'start': '2026-10-12T03:00:00.000Z',
        'end': '2026-10-12T06:00:00.000Z',
      },
    });
  }
}

void main() {
  test('loads a deal by id when no DealModel route argument is supplied',
      () async {
    final repo = _DealRepo();
    final cartService = CartService();
    final controller = DealDetailsController(
      dealRepo: repo,
      cartService: cartService,
      analytics: AnalyticsService(),
      flashSaleService: FlashSaleService(cartService: cartService),
    );

    await controller.loadDealById(42);

    expect(repo.requestedId, 42);
    expect(controller.deal.value?.id, 42);
    expect(controller.isLoading.value, isFalse);
    expect(controller.errorMessage.value, isNull);
    controller.onClose();
  });
}
