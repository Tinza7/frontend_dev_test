import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/home/home_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/paged_response_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/fake_api_service.dart';

class _ControlledDealRepo extends DealRepo {
  _ControlledDealRepo() : super(api: FakeApiService());

  final requests = <int, List<Completer<PagedResponseModel<DealModel>>>>{};

  @override
  Future<PagedResponseModel<DealModel>> fetchDeals({int page = 1}) =>
      requests[page]!.removeAt(0).future;
}

DealModel _deal(int id) => DealModel.fromJson({
      'id': id,
      'pickupWindow': {
        'start': '2026-10-12T10:00:00.000Z',
        'end': '2026-10-12T12:00:00.000Z',
      },
    });

PagedResponseModel<DealModel> _page(
  int page,
  int totalPages,
  int dealId,
) =>
    PagedResponseModel(
      items: [_deal(dealId)],
      page: page,
      totalPages: totalPages,
    );

void main() {
  test('ignores a load-more response started before refresh', () async {
    final initialPage = Completer<PagedResponseModel<DealModel>>();
    final stalePage = Completer<PagedResponseModel<DealModel>>();
    final refreshedPage = Completer<PagedResponseModel<DealModel>>();
    final nextPage = Completer<PagedResponseModel<DealModel>>();
    final repo = _ControlledDealRepo()
      ..requests[1] = [initialPage, refreshedPage]
      ..requests[2] = [stalePage, nextPage];
    final controller = HomeController(dealRepo: repo);

    final initialRefresh = controller.refreshDeals();
    initialPage.complete(_page(1, 2, 1));
    await initialRefresh;

    final oldLoadMore = controller.loadMore();
    final refresh = controller.refreshDeals();
    refreshedPage.complete(_page(1, 2, 10));
    await refresh;
    stalePage.complete(_page(2, 2, 2));
    await oldLoadMore;

    expect(controller.deals.map((deal) => deal.id), [10]);

    final currentLoadMore = controller.loadMore();
    nextPage.complete(_page(2, 2, 20));
    await currentLoadMore;

    expect(controller.deals.map((deal) => deal.id), [10, 20]);
    controller.onClose();
  });
}
