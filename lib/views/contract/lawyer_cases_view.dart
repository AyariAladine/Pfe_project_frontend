import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/application_model.dart';
import '../../models/contract_model.dart';
import '../../services/application_service.dart';
import '../../services/token_service.dart';
import '../contract/contract_draft_view.dart';

/// Shows applications assigned to the current lawyer for contract drafting.
/// This replaces the "Cases" placeholder in the navigation.
class LawyerCasesContent extends StatefulWidget {
  const LawyerCasesContent({super.key});

  @override
  State<LawyerCasesContent> createState() => _LawyerCasesContentState();
}

class _LawyerCasesContentState extends State<LawyerCasesContent> {
  final ApplicationService _appService = ApplicationService();
  List<ApplicationModel> _cases = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  // Navigation state
  ApplicationModel? _selectedCase;
  bool _showingContract = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _currentUserId = await TokenService.getUserId();
      // Load incoming applications where the current user is the assigned lawyer
      final all = await _appService.getIncomingApplications();
      _cases = all
          .where((a) =>
              a.assignedLawyerId == _currentUserId &&
              (a.status == ApplicationStatus.contractDrafting ||
               a.status == ApplicationStatus.awaitingLawyer))
          .toList();
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show contract draft view if selected
    if (_showingContract && _selectedCase != null) {
      final contractType =
          _selectedCase!.type == ApplicationType.rent
              ? ContractType.rental
              : ContractType.sale;
      return ContractDraftContent(
        application: _selectedCase!,
        contractType: contractType,
        onBack: () => setState(() {
          _showingContract = false;
          _selectedCase = null;
        }),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_error ?? ''),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      );
    }

    if (_cases.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel_rounded,
                size: 64,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              l10n.noCases,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _cases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) =>
            _buildCaseCard(_cases[i], l10n, isDark),
      ),
    );
  }

  Widget _buildCaseCard(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    final isReady = app.status == ApplicationStatus.contractDrafting;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property address
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    app.propertyAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isReady ? AppColors.primary : AppColors.warning)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isReady
                        ? l10n.contractDrafting
                        : l10n.applicationStatusAwaitingLawyer,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          isReady ? AppColors.primary : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Parties
            Row(
              children: [
                _partyChip(
                  Icons.home_rounded,
                  app.ownerName,
                  isDark,
                ),
                const SizedBox(width: 8),
                Icon(Icons.swap_horiz_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                const SizedBox(width: 8),
                _partyChip(
                  Icons.person_rounded,
                  app.applicantName,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Deal amount
            if (app.dealAmount != null)
              Row(
                children: [
                  Icon(Icons.attach_money_rounded,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${app.dealAmount!.toStringAsFixed(2)} TND',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    app.type == ApplicationType.rent
                        ? l10n.contractTypeRental
                        : l10n.contractTypeSale,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Action button
            if (isReady)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _selectedCase = app;
                    _showingContract = true;
                  }),
                  icon: const Icon(Icons.description_rounded, size: 18),
                  label: Text(l10n.draftContract),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _partyChip(IconData icon, String name, bool isDark) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
