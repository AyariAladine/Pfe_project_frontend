/// User roles matching backend enum
/// LANDLORD and TENANT are NOT static roles - they depend on case involvement
enum UserRole { user, lawyer }

/// Extension for UserRole to get display names
extension UserRoleExtension on UserRole {
  String get displayNameAr {
    switch (this) {
      case UserRole.user:
        return 'مستخدم';
      case UserRole.lawyer:
        return 'محامي';
    }
  }

  String get displayNameEn {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.lawyer:
        return 'Lawyer';
    }
  }

  String get displayNameFr {
    switch (this) {
      case UserRole.user:
        return 'Utilisateur';
      case UserRole.lawyer:
        return 'Avocat';
    }
  }
}

/// User model matching the NestJS backend schema
class UserModel {
  final String id;
  final String name;
  final String lastName;
  final String identityNumber;
  final String email;
  final UserRole role;
  final String phoneNumber;
  final String? profileImageUrl;
  final bool? isVerified;
  final bool faceRegistered;
  final String? signatureUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.lastName,
    required this.identityNumber,
    required this.email,
    required this.role,
    required this.phoneNumber,
    this.profileImageUrl,
    this.isVerified,
    this.faceRegistered = false,
    this.signatureUrl,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$name $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      identityNumber: json['identitynumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: _parseRole(json['role']),
      phoneNumber: json['phoneNumber'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      isVerified: json['isVerified'] as bool?,
      faceRegistered: json['faceRegistered'] as bool? ?? false,
      signatureUrl: json['signatureUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// Convert UserModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastName': lastName,
      'identitynumber': identityNumber,
      'email': email,
      'role': role.name,
      'phoneNumber': phoneNumber,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (isVerified != null) 'isVerified': isVerified,
      'faceRegistered': faceRegistered,
      if (signatureUrl != null) 'signatureUrl': signatureUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  /// Parse role from string
  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.user;
    final roleStr = role.toString().toLowerCase();
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == roleStr,
      orElse: () => UserRole.user,
    );
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? lastName,
    String? identityNumber,
    String? email,
    UserRole? role,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isVerified,
    bool? faceRegistered,
    String? signatureUrl,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      identityNumber: identityNumber ?? this.identityNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      faceRegistered: faceRegistered ?? this.faceRegistered,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, lastName: $lastName, email: $email, role: $role)';
  }
}
