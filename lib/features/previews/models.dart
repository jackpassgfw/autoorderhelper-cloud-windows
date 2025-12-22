import 'package:intl/intl.dart';

import '../auto_orders/models.dart';

class PreviewOccurrence {
  PreviewOccurrence({
    required this.date,
    required this.scheduleId,
    required this.customerId,
    required this.customerName,
    required this.customerUsanaId,
    required this.cycleValue,
    required this.cycleColor,
    required this.status,
    this.note,
  });

  final DateTime date;
  final int scheduleId;
  final int customerId;
  final String customerName;
  final String customerUsanaId;
  final int cycleValue;
  final CycleColor cycleColor;
  final ScheduleStatus status;
  final String? note;

  factory PreviewOccurrence.fromJson(Map<String, dynamic> json) {
    return PreviewOccurrence(
      date: DateTime.parse(json['date'] as String),
      scheduleId: json['schedule_id'] as int? ?? 0,
      customerId: json['customer_id'] as int? ?? 0,
      customerName: json['customer_name'] as String? ?? '',
      customerUsanaId: json['customer_usana_id'] as String? ?? '',
      cycleValue: json['cycle_value'] as int? ?? 1,
      cycleColor: cycleColorFromJson(json['cycle_color'] as String? ?? 'red'),
      status: scheduleStatusFromJson(json['status'] as String? ?? 'active'),
      note: json['note'] as String?,
    );
  }
}

class PreviewResponse {
  PreviewResponse({required this.occurrences});

  final List<PreviewOccurrence> occurrences;

  factory PreviewResponse.fromJson(Map<String, dynamic> json) {
    final list = json['occurrences'] as List<dynamic>? ?? [];
    return PreviewResponse(
      occurrences: list
          .map((e) => PreviewOccurrence.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

String formatYmd(DateTime date) {
  final formatter = DateFormat('yyyy-MM-dd');
  return formatter.format(date);
}
