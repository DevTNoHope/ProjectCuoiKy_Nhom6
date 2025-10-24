// lib/utils/slot_utils.dart
import '../models/booking_models.dart';

List<DateTime> generateSlotsForDate(
    List<WorkBlock> blocks,
    DateTime date, {int stepMin = 15}
    ) {
  final slots = <DateTime>[];
  for (final b in blocks) {
    var t = b.startOn(date);
    final end = b.endOn(date);
    while (t.add(Duration(minutes: stepMin)).isBefore(end) ||
        t.add(Duration(minutes: stepMin)).isAtSameMomentAs(end)) {
      slots.add(t);
      t = t.add(Duration(minutes: stepMin));
    }
  }
  return slots;
}

List<DateTime> filterAvailableSlots({
  required List<DateTime> slots,
  required List<BookingShort> bookings,
  required int serviceDurationMin,
}) {
  bool overlaps(DateTime aS, DateTime aE, DateTime bS, DateTime bE) =>
      aE.isAfter(bS) && bE.isAfter(aS);

  return slots.where((start) {
    final end = start.add(Duration(minutes: serviceDurationMin));
    for (final b in bookings) {
      final bs = b.start.toLocal();
      final be = b.end.toLocal();
      if (overlaps(start, end, bs, be)) return false;
    }
    return true;
  }).toList();
}
