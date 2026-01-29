/// User roles matching backend enum
enum UserRole { landlord, tenant, lawyer }

/// Extension for UserRole to get display names in Arabic
extension UserRoleExtension on UserRole {
  String get displayNameAr {
    switch (this) {
      case UserRole.landlord:
        return 'مالك';
      case UserRole.tenant:
        return 'مستأجر';
      case UserRole.lawyer:
        return 'محامي';
    }
  }

  String get displayNameEn {
    switch (this) {
      case UserRole.landlord:
        return 'Landlord';
      case UserRole.tenant:
        return 'Tenant';
      case UserRole.lawyer:
        return 'Lawyer';
    }
  }

  String get displayNameFr {
    switch (this) {
      case UserRole.landlord:
        return 'Propriétaire';
      case UserRole.tenant:
        return 'Locataire';
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
    this.createdAt,
    this.updatedAt,
  });

  /// Get full name
  String get fullName => '$name $lastName';

  /// Create UserModel from JSON response
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
    };
  }

  /// Parse role from string
  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.tenant;
    final roleStr = role.toString().toLowerCase();
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == roleStr,
      orElse: () => UserRole.tenant,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, lastName: $lastName, email: $email, role: $role)';
  }
}

/// DTO for creating a new user (signup)
class CreateUserDto {
  final String name;
  final String lastName;
  final String email;
  final String password;
  final UserRole role;
  final String phoneNumber;

  CreateUserDto({
    required this.name,
    required this.lastName,
    required this.email,
    required this.password,
    required this.role,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastName': lastName,
      'identitynumber':
          '00000000', // Placeholder - will be collected during onboarding
      'email': email,
      'password': password,
      'role': role.name,
      'phoneNumber': phoneNumber,
    };
  }
}

/// DTO for login
class LoginDto {
  final String email;
  final String password;

  LoginDto({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

/// Response model for login
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Enum for Google Auth result status
enum GoogleAuthStatus { success, cancelled, roleRequired }

/// Result from Google authentication
class GoogleAuthResult {
  final GoogleAuthStatus status;
  final UserModel? user;
  final bool? isNewUser;
  final bool? accountLinked;
  final String? message;

  // Fields for when role is required (new user)
  final String? idToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  GoogleAuthResult._({
    required this.status,
    this.user,
    this.isNewUser,
    this.accountLinked,
    this.message,
    this.idToken,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  /// User successfully authenticated
  factory GoogleAuthResult.success({
    required UserModel user,
    required bool isNewUser,
    bool? accountLinked,
    String? message,
  }) {
    return GoogleAuthResult._(
      status: GoogleAuthStatus.success,
      user: user,
      isNewUser: isNewUser,
      accountLinked: accountLinked,
      message: message,
    );
  }

  /// User cancelled Google sign-in
  factory GoogleAuthResult.cancelled() {
    return GoogleAuthResult._(status: GoogleAuthStatus.cancelled);
  }

  /// New user needs to select a role
  factory GoogleAuthResult.roleRequired({
    required String idToken,
    required String email,
    String? displayName,
    String? photoUrl,
  }) {
    return GoogleAuthResult._(
      status: GoogleAuthStatus.roleRequired,
      idToken: idToken,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  /// Check if sign-in was successful
  bool get isSuccess => status == GoogleAuthStatus.success;

  /// Check if user cancelled
  bool get isCancelled => status == GoogleAuthStatus.cancelled;

  /// Check if role is required (new user)
  bool get needsRole => status == GoogleAuthStatus.roleRequired;
}
