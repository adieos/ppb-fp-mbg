import 'package:cloud_firestore/cloud_firestore.dart';

class UserRole {
  static const String admin = 'admin';
  static const String kitchenOwner = 'kitchen_owner';
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? kitchenId;
  final String fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.kitchenId,
    required this.fcmToken,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isKitchenOwner => role == UserRole.kitchenOwner;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? UserRole.kitchenOwner,
      kitchenId: data['kitchenId'] as String?,
      fcmToken: data['fcmToken'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'kitchenId': kitchenId,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
