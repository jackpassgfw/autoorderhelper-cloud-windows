import 'package:intl/intl.dart';

import '../auto_orders/models.dart' show NoteMedia;
import '../customers/models.dart';

class Delivery {
  Delivery({
    required this.id,
    required this.pickupDate,
    required this.pickupPeople,
    required this.delivered,
    required this.backorder,
    required this.itemsByCustomer,
    this.note,
    this.createDate,
    this.media = const [],
  });

  final int id;
  final DateTime? createDate;
  final DateTime? pickupDate;
  final String pickupPeople;
  final bool delivered;
  final bool backorder;
  final String? note;
  final List<DeliveryCustomerGroup> itemsByCustomer;
  final List<NoteMedia> media;

  factory Delivery.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final itemsJson = json['items_by_customer'] as List<dynamic>? ?? [];
    return Delivery(
      id: json['id'] as int? ?? 0,
      note: json['note'] as String?,
      createDate: parseDate(json['create_date']),
      pickupDate: parseDate(json['pickup_date']),
      backorder: json['backorder'] as bool? ?? false,
      pickupPeople: json['pickup_people'] as String? ?? '',
      delivered: json['delivered'] as bool? ?? false,
      itemsByCustomer: itemsJson
          .map((e) => DeliveryCustomerGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      media: NoteMedia.fromJsonList(json['media']),
    );
  }
}

class DeliveryCustomerGroup {
  DeliveryCustomerGroup({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
  });

  final int customerId;
  final String customerName;
  final String customerPhone;
  final List<DeliveryOrderItem> items;

  factory DeliveryCustomerGroup.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return DeliveryCustomerGroup(
      customerId: json['customer_id'] as int? ?? 0,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      items: itemsJson
          .map((e) => DeliveryOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DeliveryOrderItem {
  DeliveryOrderItem({required this.id, required this.orderNo});

  final int id;
  final String orderNo;

  factory DeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItem(
      id: json['id'] as int? ?? 0,
      orderNo: json['order_no'] as String? ?? '',
    );
  }
}

class DeliveryListResponse {
  DeliveryListResponse({required this.items, required this.meta});

  final List<Delivery> items;
  final PaginationMeta meta;

  factory DeliveryListResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return DeliveryListResponse(
      items: itemsJson
          .map((e) => Delivery.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class DeliveryFormData {
  DeliveryFormData({
    this.id,
    required this.pickupDate,
    required this.pickupPeople,
    required this.delivered,
    required this.backorder,
    this.note,
    this.attachments = const [],
    this.customers = const [],
  });

  final int? id;
  DateTime pickupDate;
  String pickupPeople;
  bool delivered;
  bool backorder;
  String? note;
  List<NoteMedia> attachments;
  List<DeliveryFormCustomer> customers;

  factory DeliveryFormData.newDelivery() {
    return DeliveryFormData(
      pickupDate: DateTime.now(),
      pickupPeople: '',
      delivered: false,
      backorder: false,
      attachments: const [],
      customers: const [],
    );
  }

  factory DeliveryFormData.fromDelivery(Delivery delivery) {
    return DeliveryFormData(
      id: delivery.id,
      pickupDate: delivery.pickupDate ?? DateTime.now(),
      pickupPeople: delivery.pickupPeople,
      delivered: delivery.delivered,
      backorder: delivery.backorder,
      note: delivery.note,
      attachments: delivery.media,
      customers: delivery.itemsByCustomer
          .map(
            (group) => DeliveryFormCustomer(
              customerId: group.customerId,
              customerName: group.customerName,
              customerPhone: group.customerPhone,
              orders: group.items
                  .map((item) => DeliveryFormOrder(orderNo: item.orderNo))
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  DeliveryCreateData toCreateData() {
    return DeliveryCreateData(
      pickupDate: pickupDate,
      pickupPeople: pickupPeople,
      delivered: delivered,
      backorder: backorder,
      note: note,
      attachments: attachments,
      items: _buildItems(),
    );
  }

  List<DeliveryCreateItem> _buildItems() {
    return [
      for (final customer in customers)
        for (final order in customer.orders)
          if (customer.customerId != null && order.orderNo.isNotEmpty)
            DeliveryCreateItem(
              customerId: customer.customerId!,
              orderNo: order.orderNo,
            ),
    ];
  }

  DeliveryUpdateData toUpdateData() {
    if (id == null) {
      throw StateError('Delivery id is required for update');
    }
    return DeliveryUpdateData(
      id: id!,
      pickupDate: pickupDate,
      pickupPeople: pickupPeople,
      delivered: delivered,
      backorder: backorder,
      note: note,
      attachments: attachments,
      items: _buildItems(),
    );
  }
}

class DeliveryFormCustomer {
  DeliveryFormCustomer({
    required this.customerName,
    required this.customerPhone,
    this.customerId,
    this.orders = const [],
  });

  final int? customerId;
  final String customerName;
  final String customerPhone;
  final List<DeliveryFormOrder> orders;
}

class DeliveryFormOrder {
  DeliveryFormOrder({required this.orderNo});

  final String orderNo;
}

class DeliveryCreateData {
  DeliveryCreateData({
    required this.pickupDate,
    required this.pickupPeople,
    required this.delivered,
    required this.backorder,
    required this.items,
    this.attachments = const [],
    this.note,
  });

  final DateTime pickupDate;
  final String pickupPeople;
  final bool delivered;
  final bool backorder;
  final String? note;
  final List<DeliveryCreateItem> items;
  final List<NoteMedia> attachments;

  Map<String, dynamic> toPayload() {
    return {
      'pickup_date': DateFormat('yyyy-MM-dd').format(pickupDate),
      'pickup_people': pickupPeople,
      'delivered': delivered,
      'backorder': backorder,
      'note': note,
      'items': items.map((item) => item.toJson()).toList(),
      'media': attachments.map((media) => media.toJson()).toList(),
    };
  }
}

class DeliveryCreateItem {
  DeliveryCreateItem({required this.customerId, required this.orderNo});

  final int customerId;
  final String orderNo;

  Map<String, dynamic> toJson() {
    return {'customer_id': customerId, 'order_no': orderNo};
  }
}

class DeliveryUpdateData {
  DeliveryUpdateData({
    required this.id,
    required this.pickupDate,
    required this.pickupPeople,
    required this.delivered,
    required this.backorder,
    this.attachments = const [],
    this.items = const [],
    this.note,
  });

  final int id;
  DateTime pickupDate;
  String pickupPeople;
  bool delivered;
  bool backorder;
  String? note;
  List<NoteMedia> attachments;
  List<DeliveryCreateItem> items;

  factory DeliveryUpdateData.fromDelivery(Delivery delivery) {
    return DeliveryUpdateData(
      id: delivery.id,
      pickupDate: delivery.pickupDate ?? DateTime.now(),
      pickupPeople: delivery.pickupPeople,
      delivered: delivery.delivered,
      backorder: delivery.backorder,
      note: delivery.note,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'pickup_date': DateFormat('yyyy-MM-dd').format(pickupDate),
      'pickup_people': pickupPeople,
      'delivered': delivered,
      'backorder': backorder,
      'note': note,
      'items': items.map((item) => item.toJson()).toList(),
      'media': attachments.map((media) => media.toJson()).toList(),
    };
  }
}
