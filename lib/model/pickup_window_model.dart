import 'package:intl/intl.dart';

/// A store's pickup window. The API sends instants as ISO-8601 UTC strings.
class PickupWindowModel {
  static const _marketUtcOffset = Duration(hours: 7);

  final DateTime start;
  final DateTime end;

  const PickupWindowModel({required this.start, required this.end});

  factory PickupWindowModel.fromJson(Map<String, dynamic> json) {
    return PickupWindowModel(
      start: DateTime.parse(json['start'] as String? ?? ''),
      end: DateTime.parse(json['end'] as String? ?? ''),
    );
  }

  DateTime get _marketStart => start.toUtc().add(_marketUtcOffset);
  DateTime get _marketEnd => end.toUtc().add(_marketUtcOffset);

  /// Human readable market-local label, e.g. "17:30 – 21:00".
  String get label => '${DateFormat('HH:mm').format(_marketStart)} – '
      '${DateFormat('HH:mm').format(_marketEnd)}';

  /// Whether pickup starts on today's calendar date in the market timezone.
  bool get isToday {
    final marketNow = DateTime.now().toUtc().add(_marketUtcOffset);
    final marketStart = _marketStart;
    return marketStart.year == marketNow.year &&
        marketStart.month == marketNow.month &&
        marketStart.day == marketNow.day;
  }

  /// Whether the store is currently accepting pickups.
  bool get isOpenNow {
    final now = DateTime.now().toUtc();
    return now.isAfter(start.toUtc()) && now.isBefore(end.toUtc());
  }

  Duration get untilStart =>
      start.toUtc().difference(DateTime.now().toUtc());
}
