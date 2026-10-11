import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/search/search_deals_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/fake_api_service.dart';

class _ControlledDealRepo extends DealRepo {
  _ControlledDealRepo() : super(api: FakeApiService());

  final requests = <String, Completer<List<DealModel>>>{};

  @override
  Future<List<DealModel>> search(String query) => requests[query]!.future;
}

DealModel _deal(int id) => DealModel.fromJson({'id': id});

void main() {
  test('only the latest search response updates the results', () async {
    final repo = _ControlledDealRepo()
      ..requests['s'] = Completer<List<DealModel>>()
      ..requests['su'] = Completer<List<DealModel>>();
    final controller = SearchDealsController(dealRepo: repo);

    controller.onQueryChanged('s');
    controller.onQueryChanged('su');

    repo.requests['su']!.complete([_deal(2)]);
    await Future<void>.delayed(Duration.zero);
    repo.requests['s']!.complete([_deal(1)]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.results.map((deal) => deal.id), [2]);
    expect(controller.isLoading.value, isFalse);
  });

  test('clearing the query ignores an in-flight response', () async {
    final repo = _ControlledDealRepo()
      ..requests['s'] = Completer<List<DealModel>>();
    final controller = SearchDealsController(dealRepo: repo);

    controller.onQueryChanged('s');
    controller.onQueryChanged('');
    repo.requests['s']!.complete([_deal(1)]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.results, isEmpty);
    expect(controller.hasSearched.value, isFalse);
    expect(controller.isLoading.value, isFalse);
  });
}
