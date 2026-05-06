import 'package:flutter/foundation.dart';

import '../../models/application_model.dart';
import '../../services/application_service.dart';
import '../../services/api_service.dart';

/// Holds the list of applications assigned to the current lawyer.
///
/// Used by both [LawyerWorkContent] (Work tab) and [ContractsListContent]
/// (Contracts tab) so both see the same dataset without duplicate fetches
/// when placed under a shared [ChangeNotifierProvider].
class LawyerCasesViewModel extends ChangeNotifier {
  final ApplicationService _service = ApplicationService();

  List<ApplicationModel> _cases = [];
  bool _isLoading = false;
  String? _error;

  List<ApplicationModel> get cases => _cases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Cases waiting for the lawyer to accept / review
  List<ApplicationModel> get awaitingCases => _cases
      .where((a) => a.status == ApplicationStatus.awaitingLawyer)
      .toList();

  /// Cases where the lawyer is actively drafting a contract
  List<ApplicationModel> get draftingCases => _cases
      .where((a) => a.status == ApplicationStatus.contractDrafting)
      .toList();

  Future<void> loadCases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final all = await _service.getLawyerCases();
      _cases = all..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _cases = [];
      } else {
        _error = e.toString();
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
