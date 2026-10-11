import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/model/pickup_window_model.dart';

void main() {
  test('formats UTC instants as market-local pickup times', () {
    final pickupWindow = PickupWindowModel(
      start: DateTime.utc(2026, 10, 11, 23),
      end: DateTime.utc(2026, 10, 12, 2, 30),
    );

    expect(pickupWindow.label, '06:00 – 09:30');
  });

  test('identifies today using the full market-local calendar date', () {
    final marketNow = DateTime.now().toUtc().add(const Duration(hours: 7));
    final marketMidnight = DateTime.utc(
      marketNow.year,
      marketNow.month,
      marketNow.day,
    );
    final todayStartUtc = marketMidnight.subtract(const Duration(hours: 7)).add(
          const Duration(hours: 1),
        );
    final sameDayOfMonthLastYearUtc = DateTime.utc(
      marketNow.year - 1,
      marketNow.month,
      marketNow.day,
      1,
    ).subtract(const Duration(hours: 7));

    expect(
      PickupWindowModel(
        start: todayStartUtc,
        end: todayStartUtc.add(const Duration(hours: 1)),
      ).isToday,
      isTrue,
    );
    expect(
      PickupWindowModel(
        start: sameDayOfMonthLastYearUtc,
        end: sameDayOfMonthLastYearUtc.add(const Duration(hours: 1)),
      ).isToday,
      isFalse,
    );
  });
}
