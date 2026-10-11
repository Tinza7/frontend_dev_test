import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../service/analytics_service.dart';
import '../../service/cart_service.dart';
import '../../service/flash_sale_service.dart';
import '../../util/log_service.dart';

class DealDetailsController extends GetxController {
  final DealRepo dealRepo;
  final CartService cartService;
  final AnalyticsService analytics;
  final FlashSaleService flashSaleService;

  DealDetailsController({
    required this.dealRepo,
    required this.cartService,
    required this.analytics,
    required this.flashSaleService,
  });

  final deal = Rxn<DealModel>();
  final _quantityLeft = RxnInt();
  int? get quantityLeft => _quantityLeft.value;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  bool get canRetry => _requestedDealId != null;

  bool isDealExpired(DealModel value) => flashSaleService.isExpired(value);

  Worker? _cartItemCountWorker;
  int? _requestedDealId;
  int _loadGeneration = 0;
  String _source = 'unknown';

  @override
  void onInit() {
    super.onInit();
    _source = Get.parameters['source'] ?? 'unknown';
    final argument = Get.arguments;
    if (argument is DealModel) {
      _setDeal(argument);
      return;
    }

    final dealId = int.tryParse(Get.parameters['id'] ?? '');
    if (dealId == null || dealId <= 0) {
      errorMessage.value = 'This deal link is invalid.';
      return;
    }
    loadDealById(dealId);
  }

  Future<void> loadDealById(int id) async {
    _requestedDealId = id;
    final generation = ++_loadGeneration;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final fetchedDeal = await dealRepo.fetchById(id);
      if (generation != _loadGeneration || isClosed) return;
      _setDeal(fetchedDeal);
    } catch (e) {
      if (generation != _loadGeneration || isClosed) return;
      LogService.error('load deal details failed', e);
      errorMessage.value = 'Could not load this deal. Please try again.';
    } finally {
      if (generation == _loadGeneration && !isClosed) {
        isLoading.value = false;
      }
    }
  }

  void retryLoad() {
    final id = _requestedDealId;
    if (id != null) loadDealById(id);
  }

  void _setDeal(DealModel value) {
    deal.value = value;
    _quantityLeft.value = value.quantityLeft;
    if (value.isFlashSale) {
      flashSaleService.track(value);
    }
    analytics.logEvent('deal_details_view', {
      'deal_id': value.id,
      'source': _source,
    });

    // The listener belongs to this page's controller and is released in onClose.
    _cartItemCountWorker ??=
        ever(cartService.itemCount, (_) => _recheckAvailability());
  }

  Future<void> _recheckAvailability() async {
    final currentDeal = deal.value;
    if (currentDeal == null || isClosed) return;
    LogService.log('re-checking availability for deal ${currentDeal.id}');
    try {
      final fresh = await dealRepo.fetchById(currentDeal.id);
      if (!isClosed && deal.value?.id == currentDeal.id) {
        _quantityLeft.value = fresh.quantityLeft;
      }
    } catch (e) {
      LogService.error('re-check deal availability failed', e);
    }
  }

  void addToCart() {
    final currentDeal = deal.value;
    if (currentDeal == null || isLoading.value) return;
    if (flashSaleService.isExpired(currentDeal)) {
      Get.snackbar(
        'Flash sale ended',
        'This deal can no longer be added to your bag.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    cartService.add(currentDeal);
    Get.snackbar(
      'Added to bag',
      '${currentDeal.name} — pick up ${currentDeal.pickupWindow.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void onClose() {
    _loadGeneration++;
    _cartItemCountWorker?.dispose();
    super.onClose();
  }
}
