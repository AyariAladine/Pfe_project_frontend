import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/application_model.dart';
import '../../models/contract_model.dart';
import '../../models/user_model.dart';
import '../../services/application_service.dart';
import '../../services/pdf_service.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/contract/contract_viewmodel.dart';
import 'contract_draft_view.dart';

/// Contracts section — adapts to user role.
///
/// **Lawyer**: template GridView at top (tap → application picker → draft),
///             followed by their existing saved contracts.
/// **Owner / Tenant**: their existing contracts list only.
class ContractsListContent extends StatefulWidget {
  final UserRole userRole;

  const ContractsListContent({super.key, required this.userRole});

  @override
  State<ContractsListContent> createState() => _ContractsListContentState();
}

class _ContractsListContentState extends State<ContractsListContent> {
  final ContractViewModel _vm = ContractViewModel();
  final ApplicationService _appService = ApplicationService();

  List<ApplicationModel> _availableCases = [];
  bool _isLoading = true;

  // Inline drafting state
  ApplicationModel? _draftApp;
  ContractType? _draftType;

  bool get _isLawyer => widget.userRole == UserRole.lawyer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    if (_isLawyer) {
      await _vm.loadLawyerContracts();
      try {
        _availableCases = await _appService.getLawyerCases();
      } catch (e) {
        debugPrint('[ContractsListContent] load cases: $e');
      }
    } else {
      await _vm.loadMyContracts();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Inline contract draft ──
    if (_draftApp != null && _draftType != null) {
      return ContractDraftContent(
        application: _draftApp!,
        contractType: _draftType!,
        onBack: () => setState(() {
          _draftApp = null;
          _draftType = null;
        }),
      );
    }

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId =
            context.read<AuthViewModel>().currentUser?.id ?? '';

        return RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // ── Template grid (lawyer only) ──
              if (_isLawyer) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    label: l10n.contractTemplates,
                    isDark: isDark,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 195,
                    ),
                    delegate: SliverChildListDelegate(
                      _templateOptions(l10n)
                          .map((opt) => _TemplateCard(
                                option: opt,
                                isDark: isDark,
                                onTap: () => _pickApplicationFor(opt.type, l10n),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    label: l10n.contractsSaved,
                    isDark: isDark,
                  ),
                ),
              ],

              // ── Existing contracts ──
              if (_vm.error != null && _vm.contracts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_vm.error ?? ''),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(l10n.tryAgain),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_vm.contracts.isEmpty)
                SliverFillRemaining(
                  child: Center(
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
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ContractCard(
                          contract: _vm.contracts[i],
                          userRole: widget.userRole,
                          isDark: isDark,
                          l10n: l10n,
                          currentUserId: currentUserId,
                          onTap: () =>
                              _openExistingContract(_vm.contracts[i]),
                          onSign: () => _vm.signContract(_vm.contracts[i].id),
                        ),
                      ),
                      childCount: _vm.contracts.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Template definitions ─────────────────────────────────────

  List<_TemplateOption> _templateOptions(AppLocalizations l10n) => [
        _TemplateOption(
          type: ContractType.rental,
          icon: Icons.home_rounded,
          color: AppColors.primary,
          title: l10n.contractTypeRental,
          arabicTitle: 'عقد كراء محل معد للسكنى',
          subtitle: l10n.contractTypeRentalDesc,
        ),
        _TemplateOption(
          type: ContractType.rentalAnnex,
          icon: Icons.note_add_rounded,
          color: Colors.teal,
          title: l10n.contractTypeRentalAnnex,
          arabicTitle: 'ملحق عقد كراء',
          subtitle: l10n.contractTypeRentalAnnexDesc,
        ),
        _TemplateOption(
          type: ContractType.sale,
          icon: Icons.sell_rounded,
          color: Colors.orange,
          title: l10n.contractTypeSale,
          arabicTitle: 'عقد بيع عقار',
          subtitle: l10n.contractTypeSaleDesc,
        ),
      ];

  // ─── Actions ──────────────────────────────────────────────────

  Future<void> _pickApplicationFor(
      ContractType type, AppLocalizations l10n) async {
    // Always show the picker so the lawyer can choose any request or fill manually
    final picked = await showModalBottomSheet<ApplicationModel?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ApplicationPickerSheet(
        cases: _availableCases,
        l10n: l10n,
      ),
    );

    // null = dismissed; id == 'manual' = fill manually (no request)
    if (!mounted || picked == null) return;
    setState(() {
      _draftApp = picked;
      _draftType = type;
    });
  }

  /// Blank stub used when the lawyer chooses "Fill without a request".
  static ApplicationModel _makeBlankApp() => ApplicationModel(
        id: 'manual',
        propertyId: '',
        applicantId: '',
        type: ApplicationType.rent,
        status: ApplicationStatus.contractDrafting,
        createdAt: DateTime.now(),
        property: {},
        applicant: {},
      );

  void _openExistingContract(ContractModel contract) {
    // Prefer an already-loaded case; otherwise build a lightweight stub from
    // the populated relations stored on the ContractModel.
    final app = _availableCases.firstWhere(
      (a) => a.id == contract.applicationId,
      orElse: () => ApplicationModel(
        id: contract.applicationId,
        propertyId: contract.propertyId,
        applicantId: contract.tenantId,
        type: ApplicationType.rent,
        status: ApplicationStatus.contractDrafting,
        createdAt: contract.createdAt,
        dealAmount: contract.dealAmount,
        property: contract.property ??
            {
              'Propertyaddresse': contract.propertyAddress,
              'owner': contract.owner,
            },
        applicant: contract.tenant,
      ),
    );

    setState(() {
      _draftApp = app;
      _draftType = contract.type;
    });
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _TemplateOption {
  final ContractType type;
  final IconData icon;
  final Color color;
  final String title;
  final String arabicTitle;
  final String subtitle;

  const _TemplateOption({
    required this.type,
    required this.icon,
    required this.color,
    required this.title,
    required this.arabicTitle,
    required this.subtitle,
  });
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color:
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final _TemplateOption option;
  final bool isDark;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.option,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: option.color.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      option.color,
                      Color.lerp(option.color, Colors.black, 0.22)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: option.color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(option.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),

              // Arabic title
              Text(
                option.arabicTitle,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Translated title chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  option.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: option.color,
                  ),
                ),
              ),
              const Spacer(),

              // Draft action row
              Row(
                children: [
                  Text(
                    'Draft',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: option.color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: option.color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContractCard extends StatefulWidget {
  final ContractModel contract;
  final UserRole userRole;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final String currentUserId;
  final Future<bool> Function() onSign;

  const _ContractCard({
    required this.contract,
    required this.userRole,
    required this.isDark,
    required this.l10n,
    required this.onTap,
    required this.currentUserId,
    required this.onSign,
  });

  @override
  State<_ContractCard> createState() => _ContractCardState();
}

class _ContractCardState extends State<_ContractCard> {
  bool _isSigning = false;

  Future<void> _handleSign() async {
    setState(() => _isSigning = true);
    final ok = await widget.onSign();
    if (mounted) {
      setState(() => _isSigning = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contract signed — awaiting other party'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;
    final statusColor = _statusColor(c.status);
    final isLawyer = widget.userRole == UserRole.lawyer;

    // Signing state for owner/tenant
    final isOwner = c.ownerId == widget.currentUserId;
    final isTenant = c.tenantId == widget.currentUserId;
    final inSigningPhase = c.status == ContractStatus.pendingSignatures ||
        c.status == ContractStatus.signedByOwner ||
        c.status == ContractStatus.signedByTenant;
    final needsToSign = inSigningPhase &&
        ((isOwner && c.ownerSignatureUrl == null) ||
            (isTenant && c.tenantSignatureUrl == null));
    final awaitingOther = inSigningPhase &&
        ((isOwner && c.ownerSignatureUrl != null) ||
            (isTenant && c.tenantSignatureUrl != null));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: widget.isDark ? const Color(0xFF1E1E2D) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _typeLabel(c.type),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(c.status),
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

              // ── Property ──
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 16,
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c.propertyAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Parties ──
              Row(
                children: [
                  Icon(Icons.people_rounded,
                      size: 16,
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isLawyer
                          ? '${c.ownerName} ↔ ${c.tenantName}'
                          : '${widget.l10n.contractLawyer}: ${c.lawyerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Amount + date ──
              Row(
                children: [
                  const Icon(Icons.attach_money_rounded,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    '${c.dealAmount.toStringAsFixed(2)} TND',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _fmt(c.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // ── Sign button (owner / tenant only) ──
              if (needsToSign) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSigning ? null : _handleSign,
                    icon: _isSigning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.draw_rounded, size: 18),
                    label: const Text('Sign Contract',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],

              // ── Awaiting other party ──
              if (awaitingOther) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.indigo.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          size: 15, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Your signature recorded — awaiting other party',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: widget.isDark ? Colors.white12 : Colors.black12,
              ),
              const SizedBox(height: 6),

              // ── Bottom row: completed badge + PDF ──
              Row(
                children: [
                  if (c.status == ContractStatus.completed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_rounded,
                              size: 13, color: AppColors.success),
                          SizedBox(width: 5),
                          Text(
                            'Fully Signed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  _PdfExportButton(contract: c),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  String _statusLabel(ContractStatus s) {
    switch (s) {
      case ContractStatus.draft:
        return widget.l10n.contractStatusDraft;
      case ContractStatus.pendingReview:
        return widget.l10n.contractStatusPendingReview;
      case ContractStatus.pendingSignatures:
        return widget.l10n.contractStatusPendingSignatures;
      case ContractStatus.signedByOwner:
        return widget.l10n.contractStatusSignedByOwner;
      case ContractStatus.signedByTenant:
        return widget.l10n.contractStatusSignedByTenant;
      case ContractStatus.completed:
        return widget.l10n.contractStatusCompleted;
      case ContractStatus.cancelled:
        return widget.l10n.contractStatusCancelled;
    }
  }

  String _typeLabel(ContractType t) {
    switch (t) {
      case ContractType.rental:
        return widget.l10n.contractTypeRental;
      case ContractType.sale:
        return widget.l10n.contractTypeSale;
      case ContractType.rentalAnnex:
        return widget.l10n.contractTypeRentalAnnex;
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _PdfExportButton extends StatefulWidget {
  final ContractModel contract;

  const _PdfExportButton({required this.contract});

  @override
  State<_PdfExportButton> createState() => _PdfExportButtonState();
}

class _PdfExportButtonState extends State<_PdfExportButton> {
  bool _loading = false;

  Future<void> _export() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await PdfService.shareContractPdf(widget.contract);
    } catch (e) {
      debugPrint('[PdfExportButton] export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _loading ? null : _export,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        foregroundColor: AppColors.primary,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: _loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : const Icon(Icons.picture_as_pdf_rounded, size: 16),
      label: Text(
        'Export PDF',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Bottom sheet listing all available requests so the lawyer can pick one,
/// or choose to fill the contract manually without a linked request.
class _ApplicationPickerSheet extends StatelessWidget {
  final List<ApplicationModel> cases;
  final AppLocalizations l10n;

  const _ApplicationPickerSheet({required this.cases, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle bar
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  l10n.selectCase,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                if (cases.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${cases.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: cases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noRequests,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cases.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final app = cases[i];
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.gavel_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          title: Text(
                            app.propertyAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${app.ownerName} ↔ ${app.applicantName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: app.dealAmount != null
                              ? Text(
                                  '${app.dealAmount!.toStringAsFixed(0)} TND',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange,
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.pop(ctx, app),
                        ),
                      );
                    },
                  ),
          ),
          // ── Fill without a request ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pop(ctx, _ContractsListContentState._makeBlankApp()),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: Text(l10n.fillWithoutRequest),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
