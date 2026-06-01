import 'package:cloud_firestore/cloud_firestore.dart';

class ReportStatus {
  static const String draft = 'draft';
  static const String submitted = 'submitted';
  static const String verified = 'verified';
  static const String rejected = 'rejected';
}

class MenuItemModel {
  final String name;
  final int portionCount;
  final int? caloriesPerPortion;

  const MenuItemModel({
    required this.name,
    required this.portionCount,
    this.caloriesPerPortion,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map) => MenuItemModel(
        name: map['name'] as String,
        portionCount: map['portionCount'] as int,
        caloriesPerPortion: map['caloriesPerPortion'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'portionCount': portionCount,
        'caloriesPerPortion': caloriesPerPortion,
      };
}

class ReportModel {
  final String id;
  final String kitchenId;
  final String kitchenName;
  final String ownerUid;
  final DateTime date;
  final List<MenuItemModel> menuItems;
  final int totalBeneficiaries;
  final String distributionTime;
  final List<String> proofImageUrls;
  final String status;
  final String? rejectionReason;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final bool isHoliday;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportModel({
    required this.id,
    required this.kitchenId,
    required this.kitchenName,
    required this.ownerUid,
    required this.date,
    required this.menuItems,
    required this.totalBeneficiaries,
    required this.distributionTime,
    required this.proofImageUrls,
    required this.status,
    this.rejectionReason,
    this.verifiedBy,
    this.verifiedAt,
    required this.isHoliday,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      kitchenId: data['kitchenId'] as String? ?? '',
      kitchenName: data['kitchenName'] as String? ?? 'Unknown Kitchen',
      ownerUid: data['ownerUid'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      menuItems: (data['menuItems'] as List<dynamic>? ?? [])
          .map((e) => MenuItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalBeneficiaries: data['totalBeneficiaries'] as int? ?? 0,
      distributionTime: data['distributionTime'] as String? ?? '-',
      proofImageUrls: List<String>.from(data['proofImageUrls'] ?? []),
      status: data['status'] as String? ?? ReportStatus.draft,
      rejectionReason: data['rejectionReason'] as String?,
      verifiedBy: data['verifiedBy'] as String?,
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
      isHoliday: data['isHoliday'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  ReportModel copyWith({
    String? status,
    String? rejectionReason,
    String? verifiedBy,
    DateTime? verifiedAt,
  }) =>
      ReportModel(
        id: id,
        kitchenId: kitchenId,
        kitchenName: kitchenName,
        ownerUid: ownerUid,
        date: date,
        menuItems: menuItems,
        totalBeneficiaries: totalBeneficiaries,
        distributionTime: distributionTime,
        proofImageUrls: proofImageUrls,
        status: status ?? this.status,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        verifiedBy: verifiedBy ?? this.verifiedBy,
        verifiedAt: verifiedAt ?? this.verifiedAt,
        isHoliday: isHoliday,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
