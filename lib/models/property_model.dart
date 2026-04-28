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
  final String? description;
  final String? longitude;
  final String? latitude;
  final PropertyType propertyType;
  final PropertyStatus propertyStatus;
  final String? contractId;
  final List<String> propertyImages;
  final String? registrationDocument;
  final Map<String, dynamic>? owner;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PropertyModel({
    this.id,
    required this.propertyAddress,
    this.description,
    this.longitude,
    this.latitude,
    required this.propertyType,
    this.propertyStatus = PropertyStatus.unavailable,
    this.contractId,
    this.propertyImages = const [],
    this.registrationDocument,
    this.owner,
    this.createdAt,
    this.updatedAt,
  });

  /// Resolve a single image path to a full URL
  static String? _resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    if (imagePath.startsWith('/')) {
      return '${ApiConstants.baseUrl}$imagePath';
    }

    final filename = imagePath.split('/').last;
    return '${ApiConstants.baseUrl}/uploads/properties/images/$filename';
  }

  /// Get full URLs for all property images
  List<String> get imageUrls {
    return propertyImages
        .map((p) => _resolveImageUrl(p))
        .whereType<String>()
        .toList();
  }

  /// Convenience: first image URL (backward compat for list cards etc.)
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // Parse owner - can be a string (ID) or a populated object
    Map<String, dynamic>? ownerData;
    if (json['owner'] is Map<String, dynamic>) {
      ownerData = json['owner'] as Map<String, dynamic>;
    }

    return PropertyModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      propertyAddress: json['Propertyaddresse'] as String? ?? '',
      description: json['description'] as String?,
      longitude: json['longitude'] as String?,
      latitude: json['latitude'] as String?,
      propertyType: PropertyType.fromJson(json['PropertyType'] as String? ?? 'rent'),
      propertyStatus: PropertyStatus.fromJson(
        json['propertyStatus'] as String? ?? 'unavailable',
      ),
      contractId: json['contractId'] as String?,
      propertyImages: _parseImages(json),
      registrationDocument: json['Registrationdocument'] as String?,
      owner: ownerData,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Parse images from JSON – handles both array and legacy single-string
  static List<String> _parseImages(Map<String, dynamic> json) {
    // New format: array (try both casings)
    final images = json['propertyimages'] ?? json['propertyImages'];
    if (images is List && images.isNotEmpty) {
      return images.map((e) => e.toString()).toList();
    }
    // Legacy single-string field (try both casings)
    final single = (json['propertyimage'] ?? json['propertyImage']) as String?;
    if (single != null && single.isNotEmpty) {
      return [single];
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'Propertyaddresse': propertyAddress,
      if (description != null) 'description': description,
      if (longitude != null) 'longitude': longitude,
      if (latitude != null) 'latitude': latitude,
      'PropertyType': propertyType.toJson(),
      'propertyStatus': propertyStatus.toJson(),
      if (contractId != null) 'contractId': contractId,
      if (propertyImages.isNotEmpty) 'propertyimages': propertyImages,
      if (registrationDocument != null) 'Registrationdocument': registrationDocument,
    };
  }

  /// Get owner's ID
  String? get ownerId => owner?['_id'] as String? ?? owner?['id'] as String?;

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
    String? description,
    String? longitude,
    String? latitude,
    PropertyType? propertyType,
    PropertyStatus? propertyStatus,
    String? contractId,
    List<String>? propertyImages,
    String? registrationDocument,
    Map<String, dynamic>? owner,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      description: description ?? this.description,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      propertyType: propertyType ?? this.propertyType,
      propertyStatus: propertyStatus ?? this.propertyStatus,
      contractId: contractId ?? this.contractId,
      propertyImages: propertyImages ?? this.propertyImages,
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
  final String? description;
  final String? longitude;
  final String? latitude;
  final PropertyType propertyType;
  final PropertyStatus? propertyStatus;
  final String? contractId;
  final String? propertyImage;
  final String? registrationDocument;

  CreatePropertyDto({
    required this.propertyAddress,
    this.description,
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
      if (description != null && description!.isNotEmpty) 'description': description,
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
