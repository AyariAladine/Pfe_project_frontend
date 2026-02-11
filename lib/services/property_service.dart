import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/constants/api_constants.dart';
import '../models/property_model.dart';
import 'api_service.dart';
import 'token_service.dart';

/// Service for property CRUD operations
class PropertyService {
  final ApiService _apiService = ApiService();

  /// Create a new property (multipart form-data with optional image)
  Future<PropertyModel> createProperty(
    CreatePropertyDto dto, {
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      // Get current user's ID for the owner field
      final userId = await TokenService.getUserId();
      if (userId == null) {
        throw ApiException('User not authenticated');
      }

      // Build form fields from DTO
      final fields = <String, String>{
        'owner': userId,
        'Propertyaddresse': dto.propertyAddress,
        'PropertyType': dto.propertyType.toJson(),
      };
      if (dto.propertyStatus != null) {
        fields['propertyStatus'] = dto.propertyStatus!.toJson();
      }
      if (dto.latitude != null) {
        fields['latitude'] = dto.latitude!;
      }
      if (dto.longitude != null) {
        fields['longitude'] = dto.longitude!;
      }
      if (dto.contractId != null) {
        fields['contractId'] = dto.contractId!;
      }

      final response = await _apiService.postMultipart(
        ApiConstants.properties,
        fields: fields,
        fileBytes: imageBytes,
        fileName: imageFileName,
        fieldName: 'image',
        requiresAuth: true,
      );

      return PropertyModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all properties
  Future<List<PropertyModel>> getAllProperties() async {
    try {
      final response = await _apiService.get(
        ApiConstants.properties,
        requiresAuth: true,
      );

      List<dynamic> list;
      if (response is List) {
        list = response;
      } else if (response is Map<String, dynamic>) {
        list = response['data'] ?? response['properties'] ?? [];
      } else {
        return [];
      }

      return list
          .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user's properties
  Future<List<PropertyModel>> getMyProperties() async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.properties}/my-properties',
        requiresAuth: true,
      );

      List<dynamic> list;
      if (response is List) {
        list = response;
      } else if (response is Map<String, dynamic>) {
        list = response['data'] ?? response['properties'] ?? [];
      } else {
        return [];
      }

      return list
          .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get properties by owner ID
  Future<List<PropertyModel>> getPropertiesByOwner(String ownerId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.properties}/owner/$ownerId',
        requiresAuth: true,
      );

      List<dynamic> list;
      if (response is List) {
        list = response;
      } else if (response is Map<String, dynamic>) {
        list = response['data'] ?? response['properties'] ?? [];
      } else {
        return [];
      }

      return list
          .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single property by ID
  Future<PropertyModel> getProperty(String id) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.properties}/$id',
        requiresAuth: true,
      );

      return PropertyModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update a property
  Future<PropertyModel> updateProperty(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiService.patch(
        '${ApiConstants.properties}/$id',
        body: updates,
        requiresAuth: true,
      );

      return PropertyModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a property
  Future<void> deleteProperty(String id) async {
    try {
      await _apiService.delete(
        '${ApiConstants.properties}/$id',
        requiresAuth: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Upload property image
  Future<PropertyModel> uploadPropertyImage(
    String propertyId, {
    File? imageFile,
    Uint8List? imageBytes,
    required String fileName,
  }) async {
    try {
      Uint8List bytes;
      if (imageBytes != null) {
        bytes = imageBytes;
      } else if (imageFile != null && !kIsWeb) {
        bytes = await imageFile.readAsBytes();
      } else {
        throw ApiException('No image data provided');
      }

      final response = await _apiService.uploadFile(
        '${ApiConstants.properties}/$propertyId/upload-image',
        fileBytes: bytes,
        fileName: fileName,
        fieldName: 'image',
        requiresAuth: true,
      );

      final propertyData = response['property'] ?? response;
      return PropertyModel.fromJson(propertyData);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload registration document
  Future<PropertyModel> uploadDocument(
    String propertyId, {
    File? documentFile,
    Uint8List? documentBytes,
    required String fileName,
  }) async {
    try {
      Uint8List bytes;
      if (documentBytes != null) {
        bytes = documentBytes;
      } else if (documentFile != null && !kIsWeb) {
        bytes = await documentFile.readAsBytes();
      } else {
        throw ApiException('No document data provided');
      }

      final response = await _apiService.uploadFile(
        '${ApiConstants.properties}/$propertyId/upload-document',
        fileBytes: bytes,
        fileName: fileName,
        fieldName: 'document',
        requiresAuth: true,
      );

      final propertyData = response['property'] ?? response;
      return PropertyModel.fromJson(propertyData);
    } catch (e) {
      rethrow;
    }
  }
}
