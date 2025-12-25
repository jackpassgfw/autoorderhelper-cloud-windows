import '../auto_orders/models.dart' show NoteMedia;

enum MemberStatus { unknown, notMember, member }

MemberStatus memberStatusFromJson(String value) {
  switch (value) {
    case 'unknown':
      return MemberStatus.unknown;
    case 'not_member':
      return MemberStatus.notMember;
    case 'member':
      return MemberStatus.member;
    default:
      return MemberStatus.unknown;
  }
}

String memberStatusToJson(MemberStatus status) {
  switch (status) {
    case MemberStatus.unknown:
      return 'unknown';
    case MemberStatus.notMember:
      return 'not_member';
    case MemberStatus.member:
      return 'member';
  }
}

String memberStatusLabel(MemberStatus status) {
  switch (status) {
    case MemberStatus.unknown:
      return 'Unknown';
    case MemberStatus.notMember:
      return 'Not Member';
    case MemberStatus.member:
      return 'Member';
  }
}

enum BusinessCenterSide { unknown, left, right }

BusinessCenterSide businessCenterSideFromJson(String value) {
  switch (value) {
    case 'left':
      return BusinessCenterSide.left;
    case 'right':
      return BusinessCenterSide.right;
    case 'unknown':
    default:
      return BusinessCenterSide.unknown;
  }
}

String businessCenterSideToJson(BusinessCenterSide side) {
  switch (side) {
    case BusinessCenterSide.unknown:
      return 'unknown';
    case BusinessCenterSide.left:
      return 'left';
    case BusinessCenterSide.right:
      return 'right';
  }
}

String businessCenterSideLabel(BusinessCenterSide side) {
  switch (side) {
    case BusinessCenterSide.unknown:
      return 'Unknown';
    case BusinessCenterSide.left:
      return 'Left';
    case BusinessCenterSide.right:
      return 'Right';
  }
}

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final int page;
  final int pageSize;
  final int total;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
    );
  }
}

class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.memberStatus,
    required this.businessCenterSide,
    this.email,
    this.address,
    this.note,
    this.customerUsanaId,
    this.usanaUsername,
    this.sponsor,
    this.businessCenterId,
    this.media = const [],
  });

  final int id;
  final String name;
  final String phone;
  final MemberStatus memberStatus;
  final BusinessCenterSide businessCenterSide;
  final String? email;
  final String? address;
  final String? note;
  final String? customerUsanaId;
  final String? usanaUsername;
  final String? sponsor;
  final int? businessCenterId;
  final List<NoteMedia> media;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      memberStatus: memberStatusFromJson(
        json['member_status'] as String? ?? 'unknown',
      ),
      businessCenterSide: businessCenterSideFromJson(
        json['business_center_side'] as String? ?? 'unknown',
      ),
      address: json['address'] as String?,
      note: json['note'] as String?,
      customerUsanaId: json['customer_usana_id'] as String?,
      usanaUsername: json['usana_username'] as String?,
      sponsor: json['sponsor'] as String?,
      businessCenterId: json['business_center_id'] as int?,
      media: NoteMedia.fromJsonList(json['media']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'note': note,
      'customer_usana_id': customerUsanaId,
      'usana_username': usanaUsername,
      'sponsor': sponsor,
      'business_center_id': businessCenterId,
      'member_status': memberStatusToJson(memberStatus),
      'business_center_side': businessCenterSideToJson(businessCenterSide),
      'media': media.map((item) => item.toJson()).toList(),
    };
  }
}

class CustomerListResponse {
  CustomerListResponse({required this.items, required this.meta});

  final List<Customer> items;
  final PaginationMeta meta;

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return CustomerListResponse(
      items: itemsJson
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class CustomerFormData {
  CustomerFormData({
    this.id,
    this.name = '',
    this.phone = '',
    this.email,
    this.address,
    this.note,
    this.customerUsanaId,
    this.usanaUsername,
    this.sponsor,
    this.businessCenterId,
    this.memberStatus = MemberStatus.unknown,
    this.businessCenterSide = BusinessCenterSide.unknown,
    this.media = const [],
  });

  final int? id;
  String name;
  String phone;
  String? email;
  String? address;
  String? note;
  String? customerUsanaId;
  String? usanaUsername;
  String? sponsor;
  int? businessCenterId;
  MemberStatus memberStatus;
  BusinessCenterSide businessCenterSide;
  List<NoteMedia> media;

  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{
      'name': name,
      'phone': phone,
      'member_status': memberStatusToJson(memberStatus),
      'business_center_side': businessCenterSideToJson(businessCenterSide),
    };
    if (email != null) payload['email'] = email;
    if (address != null) payload['address'] = address;
    if (note != null) payload['note'] = note;
    if (customerUsanaId != null) {
      payload['customer_usana_id'] = customerUsanaId;
    }
    if (usanaUsername != null) payload['usana_username'] = usanaUsername;
    if (sponsor != null) payload['sponsor'] = sponsor;
    if (businessCenterId != null) {
      payload['business_center_id'] = businessCenterId;
    }
    if (media.isNotEmpty) {
      payload['media'] = media
          .map(
            (item) => {
              'url': item.url,
              'mime_type': item.mimeType,
              'size_bytes': item.sizeBytes,
              'original_name': item.originalName,
              'sort_order': item.sortOrder,
            },
          )
          .toList();
    }
    return payload;
  }

  factory CustomerFormData.fromCustomer(Customer customer) {
    return CustomerFormData(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      note: customer.note,
      customerUsanaId: customer.customerUsanaId,
      usanaUsername: customer.usanaUsername,
      sponsor: customer.sponsor,
      businessCenterId: customer.businessCenterId,
      memberStatus: customer.memberStatus,
      businessCenterSide: customer.businessCenterSide,
      media: customer.media,
    );
  }
}

class BusinessCenter {
  BusinessCenter({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;

  factory BusinessCenter.fromJson(Map<String, dynamic> json) {
    return BusinessCenter(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

class Followup {
  Followup({
    required this.id,
    required this.customerId,
    required this.timestamp,
    required this.content,
  });

  final int id;
  final int customerId;
  final DateTime timestamp;
  final String content;

  factory Followup.fromJson(Map<String, dynamic> json) {
    return Followup(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      content: json['content'] as String? ?? '',
    );
  }
}
