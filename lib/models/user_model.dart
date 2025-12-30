// lib/models/user_model.dart

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  // Factory: Create User from Firestore Data
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  // Method: Convert User to Map for Uploading (if needed)
  Map<String, dynamic> toMap() {
    return {'fullName': fullName, 'email': email, 'phone': phone};
  }
}
