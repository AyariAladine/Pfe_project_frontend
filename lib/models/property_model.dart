import 'package:pfe_project/core/constants/api_constants.dart';
enum PropertyType {
  sale,
  rent;

  String get displayName {
    switch (this) {
      case PropertyType.sale:
        return 'Sale';
      case PropertyType.rent:
        return 'Rent';
    }
  }

  String toJson() => name;

  static PropertyType fromJson(String json) {
    return PropertyType.values.firstWhere(
      (e) => e.name.toLowerCase() == json.toLowerCase(),
      orElse: () => PropertyType.rent,
    );
  }
}

/// Property status enum
enum PropertyStatus {
  available,
  rented,
  sold,
  pending,
  unavailable;

  String get displayName {
    switch (this) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.sold:
        return 'Sold';
      case PropertyStatus.pending:
        return 'Pending';
      case PropertyStatus.unavailable:
        return 'Unavailable';
    }
  }

  String toJson() => name;

  static PropertyStatus fromJson(String json) {
    return PropertyStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == json.toLowerCase(),
      orElse: () => PropertyStatus.unavailable,
    );
  }
}


/// Property model
class PropertyModel {
  final String? id;
  final String propertyAddress;
  final String? longitude;
  final String? latitude;
  final PropertyType propertyType;
  final PropertyStatus propertyStatus;
  final String? contractId;
  final String? propertyImage;
  final String? registrationDocument;
  final Map<String, dynamic>? owner;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PropertyModel({
    this.id,
    required this.propertyAddress,
    this.longitude,
    this.latitude,
    required this.propertyType,
    this.propertyStatus = PropertyStatus.unavailable,
    this.contractId,
    this.propertyImage,
    this.registrationDocument,
    this.owner,
    this.createdAt,
    this.updatedAt,
  });

  // Get full image URL
  String? get imageUrl {
    if (propertyImage == null || propertyImage!.isEmpty) return null;
    
    // If already a full URL, return as is (after validation)
    if (propertyImage!.startsWith('http://') || propertyImage!.startsWith('https://')) {
      // Only allow URLs from our own backend
      if (propertyImage!.contains('localhost:3000') || 
          propertyImage!.contains('10.64.158.95:3000')) {
        return propertyImage;
      }
      // External URL - reject for security
      return null;
    }
    
    // Handle relative paths from backend (e.g., /uploads/properties/images/xxx.jpg)
    // or just filenames (e.g., xxx.jpg)
    if (propertyImage!.startsWith('/')) {
      // Remove leading slash and build full URL
      return '${ApiConstants.baseUrl}${propertyImage}';
    }
    
    // Just a filename - construct full path
    final filename = propertyImage!.split('/').last;
    return '${ApiConstants.baseUrl}/uploads/properties/images/$filename';
  }

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // Parse owner - can be a string (ID) or a populated object
    Map<String, dynamic>? ownerData;
    if (json['owner'] is Map<String, dynamic>) {
      ownerData = json['owner'] as Map<String, dynamic>;
    }

    return PropertyModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      propertyAddress: json['Propertyaddresse'] as String? ?? '',
      longitude: json['longitude'] as String?,
      latitude: json['latitude'] as String?,
      propertyType: PropertyType.fromJson(json['PropertyType'] as String? ?? 'rent'),
      propertyStatus: PropertyStatus.fromJson(
        json['propertyStatus'] as String? ?? 'unavailable',
      ),
      contractId: json['contractId'] as String?,
      propertyImage: json['propertyimage'] as String?,
      registrationDocument: json['Registrationdocument'] as String?,
      owner: ownerData,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Propertyaddresse': propertyAddress,
      if (longitude != null) 'longitude': longitude,
      if (latitude != null) 'latitude': latitude,
      'PropertyType': propertyType.toJson(),
      'propertyStatus': propertyStatus.toJson(),
      if (contractId != null) 'contractId': contractId,
      if (propertyImage != null) 'propertyimage': propertyImage,
      if (registrationDocument != null) 'Registrationdocument': registrationDocument,
    };
  }

  /// Get owner's display name
  String? get ownerName {
    if (owner == null) return null;
    final name = owner!['name'] as String? ?? '';
    final lastName = owner!['lastName'] as String? ?? '';
    return '$name $lastName'.trim();
  }

  /// Get owner's email
  String? get ownerEmail => owner?['email'] as String?;

  PropertyModel copyWith({
    String? id,
    String? propertyAddress,
    String? longitude,
    String? latitude,
    PropertyType? propertyType,
    PropertyStatus? propertyStatus,
    String? contractId,
    String? propertyImage,
    String? registrationDocument,
    Map<String, dynamic>? owner,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      propertyType: propertyType ?? this.propertyType,
      propertyStatus: propertyStatus ?? this.propertyStatus,
      contractId: contractId ?? this.contractId,
      propertyImage: propertyImage ?? this.propertyImage,
      registrationDocument: registrationDocument ?? this.registrationDocument,
      owner: owner ?? this.owner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// DTO for creating a property
class CreatePropertyDto {
  final String propertyAddress;
  final String? longitude;
  final String? latitude;
  final PropertyType propertyType;
  final PropertyStatus? propertyStatus;
  final String? contractId;
  final String? propertyImage;
  final String? registrationDocument;

  CreatePropertyDto({
    required this.propertyAddress,
    this.longitude,
    this.latitude,
    required this.propertyType,
    this.propertyStatus,
    this.contractId,
    this.propertyImage,
    this.registrationDocument,
  });

  Map<String, dynamic> toJson() {
    return {
      'Propertyaddresse': propertyAddress,
      if (longitude != null) 'longitude': longitude,
      if (latitude != null) 'latitude': latitude,
      'PropertyType': propertyType.toJson(),
      if (propertyStatus != null) 'propertyStatus': propertyStatus!.toJson(),
      if (contractId != null) 'contractId': contractId,
      if (propertyImage != null) 'propertyimage': propertyImage,
      if (registrationDocument != null) 'Registrationdocument': registrationDocument,
    };
  }
}
