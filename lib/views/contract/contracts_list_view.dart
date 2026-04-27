import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/contract_model.dart';
import '../../models/user_model.dart';
import '../../viewmodels/contract/contract_viewmodel.dart';

/// List of contracts — shown in the Contracts nav tab.
/// Adapts to user role: lawyers see their assigned drafts, users see their own.
class ContractsListContent extends StatefulWidget {
  final UserRole userRole;
  final void Function(ContractModel contract)? onContractSelected;

  const ContractsListContent({
    super.key,
    required this.userRole,
    this.onContractSelected,
  });

  @override
  State<ContractsListContent> createState() => _ContractsListContentState();
}

class _ContractsListContentState extends State<ContractsListContent> {
  final ContractViewModel _vm = ContractViewModel();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.userRole == UserRole.lawyer) {
      await _vm.loadLawyerContracts();
    } else {
      await _vm.loadMyContracts();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (_vm.isLoading && _vm.contracts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_vm.error != null && _vm.contracts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_vm.error ?? '',
                    style: const TextStyle(fontSize: 16)),
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

        if (_vm.contracts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined,
                    size: 64,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  l10n.noContracts,
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
            itemCount: _vm.contracts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _buildContractCard(_vm.contracts[i], l10n, isDark),
          ),
        );
      },
    );
  }

  Widget _buildContractCard(
      ContractModel contract, AppLocalizations l10n, bool isDark) {
    final statusColor = _statusColor(contract.status);
    final isLawyer = widget.userRole == UserRole.lawyer;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => widget.onContractSelected?.call(contract),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: type badge + status chip
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _contractTypeLabel(l10n, contract.type),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(l10n, contract.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Property address
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      contract.propertyAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Parties
              Row(
                children: [
                  Icon(Icons.people_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isLawyer
                          ? '${contract.ownerName} ↔ ${contract.tenantName}'
                          : '${l10n.assignLawyer}: ${contract.lawyerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Amount
              Row(
                children: [
                  Icon(Icons.attach_money_rounded,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    '${contract.dealAmount.toStringAsFixed(2)} TND',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(contract.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────

  Color _statusColor(ContractStatus s) {
    switch (s) {
      case ContractStatus.draft:
        return AppColors.warning;
      case ContractStatus.pendingReview:
        return AppColors.info;
      case ContractStatus.pendingSignatures:
        return Colors.orange;
      case ContractStatus.signedByOwner:
      case ContractStatus.signedByTenant:
        return Colors.indigo;
      case ContractStatus.completed:
        return AppColors.success;
      case ContractStatus.cancelled:
        return AppColors.error;
    }
  }

  String _statusLabel(AppLocalizations l10n, ContractStatus s) {
    switch (s) {
      case ContractStatus.draft:
        return l10n.contractStatusDraft;
      case ContractStatus.pendingReview:
        return l10n.contractStatusPendingReview;
      case ContractStatus.pendingSignatures:
        return l10n.contractStatusPendingSignatures;
      case ContractStatus.signedByOwner:
        return l10n.contractStatusSignedByOwner;
      case ContractStatus.signedByTenant:
        return l10n.contractStatusSignedByTenant;
      case ContractStatus.completed:
        return l10n.contractStatusCompleted;
      case ContractStatus.cancelled:
        return l10n.contractStatusCancelled;
    }
  }

  String _contractTypeLabel(AppLocalizations l10n, ContractType t) {
    switch (t) {
      case ContractType.rental:
        return l10n.contractTypeRental;
      case ContractType.sale:
        return l10n.contractTypeSale;
      case ContractType.rentalAnnex:
        return l10n.contractTypeRentalAnnex;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
