import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Service for regular user profile operations
class UserService {
  final ApiService _apiService = ApiService();

  /// Update user profile via JSON PATCH
  Future<UserModel> updateUserProfile(
    String id, {
    String? name,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? identitynumber,
  }) async {
    final body = <String, dynamic>{};

    if (name != null && name.isNotEmpty) body['name'] = name;
    if (lastName != null && lastName.isNotEmpty) body['lastName'] = lastName;
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      body['phoneNumber'] = phoneNumber;
    }
    if (identitynumber != null && identitynumber.isNotEmpty) {
      body['identitynumber'] = identitynumber;
    }

    final response = await _apiService.patch(
      ApiConstants.userProfile(id),
      body: body,
      requiresAuth: true,
    );

    return UserModel.fromJson(response);
  }
}
