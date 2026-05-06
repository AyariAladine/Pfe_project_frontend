import '../core/constants/api_constants.dart';
import '../models/rental_model.dart';
import 'api_service.dart';

class RentalsService {
  final ApiService _api = ApiService();

  Future<List<RentalModel>> getMyRentals() async {
    final response = await _api.get(ApiConstants.myRentals, requiresAuth: true);
    if (response is List) {
      return response
          .map((j) => RentalModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<RentalModel> markPaid(String rentalId) async {
    final response = await _api.patch(
      ApiConstants.rentalMarkPaid(rentalId),
      body: {},
      requiresAuth: true,
    );
    return RentalModel.fromJson(response);
  }
}
