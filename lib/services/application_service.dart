import '../core/constants/api_constants.dart';
import '../models/application_model.dart';
import 'api_service.dart';

/// Service to manage property applications (postulations)
class ApplicationService {
  final ApiService _apiService = ApiService();

  // ─── Applicant actions ─────────────────────────────────────────

  /// Apply (postulate) for a property
  Future<ApplicationModel> applyForProperty({
    required String propertyId,
    required ApplicationType type,
    String? message,
  }) async {
    final body = <String, dynamic>{
      'propertyId': propertyId,
      'type': type.toJson(),
    };
    if (message != null && message.isNotEmpty) {
      body['message'] = message;
    }

    final response = await _apiService.post(
      ApiConstants.applications,
      body: body,
      requiresAuth: true,
    );

    return ApplicationModel.fromJson(response);
  }

  /// Get current user's applications (as applicant)
  Future<List<ApplicationModel>> getMyApplications() async {
    final response = await _apiService.get(
      ApiConstants.myApplications,
      requiresAuth: true,
    );

    final list =
        response is List ? response : (response['data'] as List?) ?? [];
    return list
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cancel an application (applicant withdraws)
  Future<void> cancelApplication(String applicationId) async {
    await _apiService.patch(
      ApiConstants.applicationCancel(applicationId),
      body: {},
      requiresAuth: true,
    );
  }

  /// Check if user already applied for a property
  Future<ApplicationModel?> getMyApplicationForProperty(
      String propertyId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.applications}/property/$propertyId/mine',
        requiresAuth: true,
      );
      if (response == null || (response is Map && response.isEmpty)) {
        return null;
      }
      return ApplicationModel.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ─── Owner actions ─────────────────────────────────────────────

  /// Get all incoming applications for properties the current user owns
  Future<List<ApplicationModel>> getIncomingApplications() async {
    final response = await _apiService.get(
      ApiConstants.incomingApplications,
      requiresAuth: true,
    );

    final list =
        response is List ? response : (response['data'] as List?) ?? [];
    return list
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get applications for a specific property (for owners)
  Future<List<ApplicationModel>> getPropertyApplications(
      String propertyId) async {
    final response = await _apiService.get(
      ApiConstants.propertyApplications(propertyId),
      requiresAuth: true,
    );

    final list =
        response is List ? response : (response['data'] as List?) ?? [];
    return list
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single application by ID (full detail with populated data)
  Future<ApplicationModel> getApplicationById(String applicationId) async {
    final response = await _apiService.get(
      ApiConstants.applicationById(applicationId),
      requiresAuth: true,
    );

    return ApplicationModel.fromJson(response as Map<String, dynamic>);
  }

  /// Update application status (owner action)
  Future<ApplicationModel> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
    String? note,
    String? rejectionReason,
    String? visitDate,
  }) async {
    final body = <String, dynamic>{
      'status': newStatus.toJson(),
    };
    if (note != null && note.isNotEmpty) body['note'] = note;
    if (rejectionReason != null && rejectionReason.isNotEmpty) {
      body['rejectionReason'] = rejectionReason;
    }
    if (visitDate != null) body['visitDate'] = visitDate;

    final response = await _apiService.patch(
      ApiConstants.applicationStatus(applicationId),
      body: body,
      requiresAuth: true,
    );

    return ApplicationModel.fromJson(response);
  }

  // ─── Negotiation / Contract ────────────────────────────────────

  /// Set the deal amount (owner confirms the price)
  Future<ApplicationModel> setDealAmount({
    required String applicationId,
    required double amount,
  }) async {
    final response = await _apiService.patch(
      ApiConstants.applicationSetAmount(applicationId),
      body: {'dealAmount': amount},
      requiresAuth: true,
    );
    return ApplicationModel.fromJson(response);
  }

  /// Assign a lawyer to draft the contract
  Future<ApplicationModel> assignLawyer({
    required String applicationId,
    required String lawyerId,
  }) async {
    final response = await _apiService.patch(
      ApiConstants.applicationAssignLawyer(applicationId),
      body: {'lawyerId': lawyerId},
      requiresAuth: true,
    );
    return ApplicationModel.fromJson(response);
  }

  // ─── Messaging ─────────────────────────────────────────────────

  /// Get messages for an application
  Future<List<ApplicationMessage>> getMessages(String applicationId) async {
    final response = await _apiService.get(
      ApiConstants.applicationMessages(applicationId),
      requiresAuth: true,
    );

    final list =
        response is List ? response : (response['data'] as List?) ?? [];
    return list
        .map((e) => ApplicationMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Send a message in an application conversation
  Future<ApplicationMessage> sendMessage({
    required String applicationId,
    required String content,
  }) async {
    final response = await _apiService.post(
      ApiConstants.applicationMessages(applicationId),
      body: {'content': content},
      requiresAuth: true,
    );

    return ApplicationMessage.fromJson(response);
  }
}
