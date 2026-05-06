import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/application_model.dart';
import '../../models/contract_model.dart';
import '../../viewmodels/lawyer/lawyer_cases_viewmodel.dart';
import 'contract_draft_view.dart';
import 'contract_type_selection_view.dart';

/// The **Work** section for lawyers.
///
/// Shows every application assigned to the current lawyer
/// (statuses: awaitingLawyer, contractDrafting).
/// Each request card lets the lawyer view details and choose an action:
///   • Draft Contract → ContractTypeSelectionContent → ContractDraftContent
///   • View Details   → bottom sheet with full request info
class LawyerWorkContent extends StatefulWidget {
  const LawyerWorkContent({super.key});

  @override
  State<LawyerWorkContent> createState() => _LawyerWorkContentState();
}

class _LawyerWorkContentState extends State<LawyerWorkContent> {
  final LawyerCasesViewModel _vm = LawyerCasesViewModel();

  // Inline navigation state
  ApplicationModel? _selectedRequest;
  ContractType? _selectedType;
  bool _showingTypeSelection = false;
  bool _showingContract = false;

  @override
  void initState() {
    super.initState();
    _vm.loadCases();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Contract draft (deepest level)
    if (_showingContract && _selectedRequest != null && _selectedType != null) {
      return ContractDraftContent(
        application: _selectedRequest!,
        contractType: _selectedType!,
        onBack: () => setState(() {
          _showingContract = false;
          _showingTypeSelection = true;
        }),
      );
    }

    // Contract type selection
    if (_showingTypeSelection && _selectedRequest != null) {
      return ContractTypeSelectionContent(
        application: _selectedRequest!,
        onBack: () => setState(() {
          _showingTypeSelection = false;
          _selectedRequest = null;
        }),
        onTypeSelected: (type) => setState(() {
          _selectedType = type;
          _showingTypeSelection = false;
          _showingContract = true;
        }),
      );
    }

    // Requests list — driven by ViewModel
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => _buildList(l10n, isDark),
    );
  }

  Widget _buildList(AppLocalizations l10n, bool isDark) {
    if (_vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vm.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_vm.error!),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _vm.loadCases,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      );
    }

    if (_vm.cases.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              l10n.noRequests,
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
      onRefresh: _vm.loadCases,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _vm.cases.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _RequestCard(
          request: _vm.cases[i],
          isDark: isDark,
          l10n: l10n,
          onViewDetails: () => _showDetails(_vm.cases[i], l10n, isDark),
          onDraftContract: () => _startDraft(_vm.cases[i]),
        ),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────

  void _startDraft(ApplicationModel request) {
    setState(() {
      _selectedRequest = request;
      _showingTypeSelection = true;
    });
  }

  void _showDetails(
      ApplicationModel request, AppLocalizations l10n, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RequestDetailSheet(
        request: request,
        isDark: isDark,
        l10n: l10n,
        onDraftContract: () {
          Navigator.pop(context);
          _startDraft(request);
        },
      ),
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final ApplicationModel request;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onViewDetails;
  final VoidCallback onDraftContract;

  const _RequestCard({
    required this.request,
    required this.isDark,
    required this.l10n,
    required this.onViewDetails,
    required this.onDraftContract,
  });

  @override
  Widget build(BuildContext context) {
    final isContract =
        request.status == ApplicationStatus.contractDrafting;
    final tagColor = isContract ? AppColors.primary : Colors.teal;
    final tagLabel =
        isContract ? l10n.contractRequest : l10n.caseAssignment;
    final tagIcon =
        isContract ? Icons.description_rounded : Icons.work_rounded;

    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: address + work-type tag ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          request.propertyAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tagIcon, size: 12, color: tagColor),
                      const SizedBox(width: 4),
                      Text(
                        tagLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tagColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Parties ──
            Row(
              children: [
                _partyChip(
                    Icons.home_rounded, request.ownerName, isDark),
                Icon(Icons.swap_horiz_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                _partyChip(
                    Icons.person_rounded, request.applicantName, isDark),
              ],
            ),
            const SizedBox(height: 10),

            // ── Deal amount + date ──
            Row(
              children: [
                if (request.dealAmount != null) ...[
                  const Icon(Icons.attach_money_rounded,
                      size: 15, color: Colors.orange),
                  const SizedBox(width: 2),
                  Text(
                    '${request.dealAmount!.toStringAsFixed(0)} TND',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _fmt(request.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Action buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: Text(l10n.viewRequest,
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (isContract) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDraftContract,
                      icon: const Icon(Icons.edit_document, size: 16),
                      label: Text(l10n.draftContract,
                          style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
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
              size: 13,
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
                fontSize: 12,
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Request detail bottom sheet ──────────────────────────────────────────────

class _RequestDetailSheet extends StatelessWidget {
  final ApplicationModel request;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onDraftContract;

  const _RequestDetailSheet({
    required this.request,
    required this.isDark,
    required this.l10n,
    required this.onDraftContract,
  });

  @override
  Widget build(BuildContext context) {
    final isContract =
        request.status == ApplicationStatus.contractDrafting;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.requestDetails,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                _StatusBadge(status: request.status, l10n: l10n),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Property
                _DetailSection(
                  icon: Icons.location_on_rounded,
                  color: AppColors.primary,
                  label: l10n.propertyAddress,
                  value: request.propertyAddress,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // Owner
                _DetailSection(
                  icon: Icons.home_rounded,
                  color: Colors.indigo,
                  label: l10n.contractOwner,
                  value: request.ownerName,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // Tenant / Applicant
                _DetailSection(
                  icon: Icons.person_rounded,
                  color: Colors.teal,
                  label: l10n.contractTenant,
                  value: request.applicantName,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // Deal amount
                if (request.dealAmount != null) ...[
                  _DetailSection(
                    icon: Icons.attach_money_rounded,
                    color: Colors.orange,
                    label: l10n.dealAmount,
                    value:
                        '${request.dealAmount!.toStringAsFixed(2)} TND',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                ],

                // Application type
                _DetailSection(
                  icon: Icons.category_rounded,
                  color: Colors.purple,
                  label: l10n.applicationType,
                  value: request.type == ApplicationType.rent
                      ? l10n.contractTypeRental
                      : l10n.contractTypeSale,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // Applicant message
                if (request.message != null &&
                    request.message!.isNotEmpty) ...[
                  _DetailSection(
                    icon: Icons.message_rounded,
                    color: Colors.grey,
                    label: l10n.applicationMessage,
                    value: request.message!,
                    isDark: isDark,
                    multiline: true,
                  ),
                  const SizedBox(height: 14),
                ],

                // Date
                _DetailSection(
                  icon: Icons.calendar_today_rounded,
                  color: Colors.blueGrey,
                  label: l10n.date,
                  value:
                      '${request.createdAt.day.toString().padLeft(2, '0')}/${request.createdAt.month.toString().padLeft(2, '0')}/${request.createdAt.year}',
                  isDark: isDark,
                ),
                const SizedBox(height: 28),

                // Draft contract button
                if (isContract)
                  ElevatedButton.icon(
                    onPressed: onDraftContract,
                    icon: const Icon(Icons.edit_document, size: 18),
                    label: Text(l10n.draftContract),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Colors.teal, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.applicationStatusAwaitingLawyer,
                            style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final ApplicationStatus status;
  final AppLocalizations l10n;

  const _StatusBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isContract = status == ApplicationStatus.contractDrafting;
    final color = isContract ? AppColors.primary : Colors.teal;
    final label = isContract
        ? l10n.contractDrafting
        : l10n.applicationStatusAwaitingLawyer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;
  final bool multiline;

  const _DetailSection({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: multiline ? 5 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
