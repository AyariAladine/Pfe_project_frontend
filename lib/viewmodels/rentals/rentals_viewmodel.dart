import 'package:flutter/foundation.dart';
import '../../models/rental_model.dart';
import '../../services/rentals_service.dart';

class RentalsViewModel extends ChangeNotifier {
  final RentalsService _service = RentalsService();

  List<RentalModel> _rentals = [];
  bool _isLoading = false;
  bool _isMarking = false;
  String? _error;

  List<RentalModel> get rentals => _rentals;
  bool get isLoading => _isLoading;
  bool get isMarking => _isMarking;
  String? get error => _error;
  bool get hasActiveRentals => _rentals.isNotEmpty;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _rentals = await _service.getMyRentals();
    } catch (e) {
      _error = e.toString();
      debugPrint('[RentalsViewModel] load: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markPaid(String rentalId) async {
    _isMarking = true;
    notifyListeners();
    try {
      final updated = await _service.markPaid(rentalId);
      final idx = _rentals.indexWhere((r) => r.id == rentalId);
      if (idx != -1) _rentals[idx] = updated;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('[RentalsViewModel] markPaid: $e');
      return false;
    } finally {
      _isMarking = false;
      notifyListeners();
    }
  }
}
