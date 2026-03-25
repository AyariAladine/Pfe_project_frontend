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

  /// Create a new property
  Future<PropertyModel> createProperty(
    CreatePropertyDto dto,
  ) async {
    try {
      // Get current user's ID for the owner field
      final userId = await TokenService.getUserId();
      if (userId == null) {
        throw ApiException('User not authenticated');
      }

      // Build body from DTO
      final body = <String, dynamic>{
        'owner': userId,
        'Propertyaddresse': dto.propertyAddress,
        'PropertyType': dto.propertyType.toJson(),
      };
      if (dto.propertyStatus != null) {
        body['propertyStatus'] = dto.propertyStatus!.toJson();
      }
      if (dto.description != null && dto.description!.isNotEmpty) {
        body['description'] = dto.description!;
      }
      if (dto.latitude != null) {
        body['latitude'] = dto.latitude!;
      }
      if (dto.longitude != null) {
        body['longitude'] = dto.longitude!;
      }
      if (dto.contractId != null) {
        body['contractId'] = dto.contractId!;
      }

      final response = await _apiService.post(
        ApiConstants.properties,
        body: body,
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

  /// Upload property images (supports multiple)
  Future<PropertyModel> uploadPropertyImages(
    String propertyId, {
    required List<Uint8List> allImageBytes,
    required List<String> allFileNames,
  }) async {
    try {
      final response = await _apiService.uploadMultipleFiles(
        '${ApiConstants.properties}/$propertyId/upload-image',
        allFileBytes: allImageBytes,
        allFileNames: allFileNames,
        fieldName: 'images',
        requiresAuth: true,
      );

      final propertyData = response['property'] ?? response;
      return PropertyModel.fromJson(propertyData);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload single property image (convenience wrapper)
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

      return uploadPropertyImages(
        propertyId,
        allImageBytes: [bytes],
        allFileNames: [fileName],
      );
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
