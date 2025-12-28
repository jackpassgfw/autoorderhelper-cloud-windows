import 'package:intl/intl.dart';

import '../customers/models.dart';

enum ScheduleStatus { active, paused, cancelled }

ScheduleStatus scheduleStatusFromJson(String value) {
  switch (value) {
    case 'active':
      return ScheduleStatus.active;
    case 'paused':
      return ScheduleStatus.paused;
    case 'cancelled':
      return ScheduleStatus.cancelled;
    default:
      return ScheduleStatus.active;
  }
}

String scheduleStatusToJson(ScheduleStatus status) {
  return switch (status) {
    ScheduleStatus.active => 'active',
    ScheduleStatus.paused => 'paused',
    ScheduleStatus.cancelled => 'cancelled',
  };
}

String scheduleStatusLabel(ScheduleStatus status) {
  return switch (status) {
    ScheduleStatus.active => 'Active',
    ScheduleStatus.paused => 'Paused',
    ScheduleStatus.cancelled => 'Cancelled',
  };
}

enum CycleColor { red, green, blue, yellow }

CycleColor cycleColorFromJson(String value) {
  switch (value) {
    case 'red':
      return CycleColor.red;
    case 'green':
      return CycleColor.green;
    case 'blue':
      return CycleColor.blue;
    case 'yellow':
      return CycleColor.yellow;
    default:
      return CycleColor.red;
  }
}

class CycleFilter {
  const CycleFilter({required this.value, required this.color});

  final int value;
  final CycleColor color;

  String label() => 'Cycle $value - ${color.name}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleFilter &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          color == other.color;

  @override
  int get hashCode => Object.hash(value, color);
}

class AutoOrder {
  AutoOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerUsanaId,
    required this.deductionDate,
    required this.cycleValue,
    required this.cycleColor,
    required this.status,
    this.note,
    this.noteMedia = const [],
    this.memberPrice,
    this.autoorderPrice,
    this.points,
    this.freightFee,
    this.discount,
  });

  final int id;
  final int customerId;
  final String customerName;
  final String customerUsanaId;
  final DateTime deductionDate;
  final int cycleValue;
  final CycleColor cycleColor;
  final ScheduleStatus status;
  final String? note;
  final List<NoteMedia> noteMedia;
  // Pricing metadata (optional)
  final double? memberPrice;
  final double? autoorderPrice;
  final int? points;
  final double? freightFee;
  final double? discount;

  factory AutoOrder.fromJson(Map<String, dynamic> json) {
    return AutoOrder(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String? ?? '',
      customerUsanaId: json['customer_usana_id'] as String? ?? '',
      deductionDate: DateTime.parse(json['deduction_date'] as String),
      cycleValue: json['cycle_value'] as int? ?? 1,
      cycleColor: cycleColorFromJson(json['cycle_color'] as String? ?? 'red'),
      status: scheduleStatusFromJson(json['status'] as String? ?? 'active'),
      note: json['note'] as String?,
      noteMedia: NoteMedia.fromJsonList(json['media']),
      memberPrice: (json['member_price'] as num?)?.toDouble(),
      autoorderPrice: (json['autoorder_price'] as num?)?.toDouble(),
      points: json['points'] as int?,
      freightFee: (json['freight_fee'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
    );
  }
}

class AutoOrderListResponse {
  AutoOrderListResponse({required this.items, required this.meta});

  final List<AutoOrder> items;
  final PaginationMeta meta;

  factory AutoOrderListResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return AutoOrderListResponse(
      items: itemsJson
          .map((e) => AutoOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class NoteMedia {
  NoteMedia({
    this.id,
    required this.url,
    required this.mimeType,
    required this.sizeBytes,
    required this.originalName,
    required this.sortOrder,
  });

  final int? id;
  final String url;
  final String mimeType;
  final int sizeBytes;
  final String originalName;
  final int sortOrder;

  factory NoteMedia.fromJson(Map<String, dynamic> json) {
    return NoteMedia(
      id: json['id'] as int?,
      url: json['url'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      sizeBytes: json['size_bytes'] as int? ?? 0,
      originalName: json['original_name'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  static List<NoteMedia> fromJsonList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(NoteMedia.fromJson)
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'url': url,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'original_name': originalName,
      'sort_order': sortOrder,
    };
  }
}

class DeductionOption {
  DeductionOption({
    required this.date,
    required this.cycleValue,
    required this.cycleColor,
  });

  final DateTime date;
  final int cycleValue;
  final CycleColor cycleColor;

  factory DeductionOption.fromJson(Map<String, dynamic> json) {
    return DeductionOption(
      date: DateTime.parse(json['date'] as String),
      cycleValue: json['cycle_value'] as int? ?? 1,
      cycleColor: cycleColorFromJson(json['cycle_color'] as String? ?? 'red'),
    );
  }

  String label() {
    final formatter = DateFormat('yyyy-MM-dd');
    return '${formatter.format(date)} • Cycle $cycleValue • ${cycleColor.name}';
  }
}

class AutoOrderFormData {
  AutoOrderFormData({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.customerUsanaId,
    required this.deductionDate,
    required this.cycleValue,
    required this.cycleColor,
    this.note,
    this.noteMedia = const [],
    this.memberPrice,
    this.autoorderPrice,
    this.points,
    this.freightFee,
    this.discount,
    this.status = ScheduleStatus.active,
  });

  final int? id;
  int customerId;
  String customerName;
  String customerUsanaId;
  DateTime deductionDate;
  int cycleValue;
  CycleColor cycleColor;
  String? note;
  List<NoteMedia> noteMedia;
  double? memberPrice;
  double? autoorderPrice;
  int? points;
  double? freightFee;
  double? discount;
  ScheduleStatus status;

  Map<String, dynamic> toCreatePayload() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_usana_id': customerUsanaId,
      'deduction_date': DateFormat('yyyy-MM-dd').format(deductionDate),
      'cycle_value': cycleValue,
      'status': scheduleStatusToJson(status),
      'note': note,
      'media': noteMedia.map((media) => media.toJson()).toList(),
      'member_price': memberPrice,
      'autoorder_price': autoorderPrice,
      'points': points,
      'freight_fee': freightFee,
      'discount': discount,
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'customer_name': customerName,
      'customer_usana_id': customerUsanaId,
      'deduction_date': DateFormat('yyyy-MM-dd').format(deductionDate),
      'cycle_value': cycleValue,
      'status': scheduleStatusToJson(status),
      'note': note,
      'media': noteMedia.map((media) => media.toJson()).toList(),
      'member_price': memberPrice,
      'autoorder_price': autoorderPrice,
      'points': points,
      'freight_fee': freightFee,
      'discount': discount,
    };
  }

  factory AutoOrderFormData.fromAutoOrder(AutoOrder order) {
    return AutoOrderFormData(
      id: order.id,
      customerId: order.customerId,
      customerName: order.customerName,
      customerUsanaId: order.customerUsanaId,
      deductionDate: order.deductionDate,
      cycleValue: order.cycleValue,
      cycleColor: order.cycleColor,
      note: order.note,
      noteMedia: order.noteMedia,
      memberPrice: order.memberPrice,
      autoorderPrice: order.autoorderPrice,
      points: order.points,
      freightFee: order.freightFee,
      discount: order.discount,
      status: order.status,
    );
  }
}
