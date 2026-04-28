import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/application_model.dart';
import '../../models/contract_model.dart';
import '../../viewmodels/contract/contract_viewmodel.dart';

/// Contract drafting screen.
///
/// Launched from the application detail view when the lawyer starts working on
/// a contract. Shows the generated Arabic template with editable fields and
/// allows the lawyer to review, edit, save, and send for signatures.
class ContractDraftContent extends StatefulWidget {
  final ApplicationModel application;
  final ContractType contractType;
  final VoidCallback onBack;
  /// When non-null, the view loads an existing contract instead of generating.
  final String? existingContractId;

  const ContractDraftContent({
    super.key,
    required this.application,
    required this.contractType,
    required this.onBack,
    this.existingContractId,
  });

  @override
  State<ContractDraftContent> createState() => _ContractDraftContentState();
}

class _ContractDraftContentState extends State<ContractDraftContent> {
  final ContractViewModel _vm = ContractViewModel();
  late TextEditingController _contentController;

  // Shared field controllers
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _paymentDayController = TextEditingController(text: '5');
  final _durationController = TextEditingController(text: '12');

  // Rental-specific controllers
  final _syndicAmountController = TextEditingController();
  final _annualIncreaseRateController = TextEditingController(text: '5');
  final _propertyTypeController = TextEditingController(text: 'السكنى');
  final _jurisdictionCourtController =
      TextEditingController(text: 'محكمة الناحية');

  // Annex-specific controllers
  final _originalContractDateController = TextEditingController();
  final _registrationDateController = TextEditingController();
  final _taxOfficeController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _registrationNumberController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.existingContractId != null) {
      await _vm.loadContract(widget.existingContractId!);
      if (_vm.selected != null) {
        _contentController.text = _vm.selected!.content;
        _startDate = _vm.selected!.startDate;
        _endDate = _vm.selected!.endDate;
        if (_startDate != null) {
          _startDateController.text = _formatDate(_startDate!);
        }
        if (_endDate != null) {
          _endDateController.text = _formatDate(_endDate!);
        }
      }
    } else {
      // Generate from template
      _vm.generateFromTemplate(
        type: widget.contractType,
        application: widget.application,
      );
      _contentController.text = _vm.generatedContent;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.dispose();
    _contentController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _paymentDayController.dispose();
    _durationController.dispose();
    _syndicAmountController.dispose();
    _annualIncreaseRateController.dispose();
    _propertyTypeController.dispose();
    _jurisdictionCourtController.dispose();
    _originalContractDateController.dispose();
    _registrationDateController.dispose();
    _taxOfficeController.dispose();
    _receiptNumberController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Column(
          children: [
            // ── Top bar ──
            _buildAppBar(l10n, isDark),

            // ── Body ──
            Expanded(
              child: _vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Contract type header
                          _buildTypeHeader(l10n, isDark),
                          const SizedBox(height: 16),

                          // Parties summary card
                          _buildPartiesCard(l10n, isDark),
                          const SizedBox(height: 16),

                          // Editable fields
                          _buildFieldsCard(l10n, isDark),
                          const SizedBox(height: 16),

                          // Date fields (rental + sale)
                          if (widget.contractType != ContractType.rentalAnnex) ...[
                            _buildDatesCard(l10n, isDark),
                            const SizedBox(height: 16),
                          ],

                          // Contract body (Arabic text)
                          _buildContractBody(l10n, isDark),
                          const SizedBox(height: 16),

                          // Action buttons
                          _buildActions(l10n, isDark),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.existingContractId != null
                  ? l10n.contractEdit
                  : l10n.contractDraft,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (!_isEditing &&
              (_vm.selected == null || _vm.selected!.isEditable))
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: l10n.edit,
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check_rounded, color: AppColors.success),
              tooltip: l10n.confirmAction,
              onPressed: () {
                _vm.setContent(_contentController.text);
                setState(() => _isEditing = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTypeHeader(AppLocalizations l10n, bool isDark) {
    final typeLabel = switch (widget.contractType) {
      ContractType.rental => l10n.contractTypeRental,
      ContractType.sale => l10n.contractTypeSale,
      ContractType.rentalAnnex => l10n.contractTypeRentalAnnex,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.description_rounded,
              color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.dealAmount}: ${widget.application.dealAmount?.toStringAsFixed(2) ?? '—'} ${l10n.currency}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_vm.selected != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.contractSaved,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPartiesCard(AppLocalizations l10n, bool isDark) {
    final app = widget.application;
    return _card(
      isDark: isDark,
      icon: Icons.people_rounded,
      title: l10n.contractParties,
      child: Column(
        children: [
          _partyRow(
            l10n.contractOwner,
            app.ownerName,
            Icons.home_rounded,
            isDark,
          ),
          const Divider(height: 16),
          _partyRow(
            l10n.contractTenant,
            app.applicantName,
            Icons.person_rounded,
            isDark,
          ),
          if (app.assignedLawyerName != null) ...[
            const Divider(height: 16),
            _partyRow(
              l10n.contractLawyer,
              app.assignedLawyerName!,
              Icons.gavel_rounded,
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _partyRow(
      String role, String name, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary)),
            Text(name,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldsCard(AppLocalizations l10n, bool isDark) {
    final isRental = widget.contractType == ContractType.rental;
    final isAnnex = widget.contractType == ContractType.rentalAnnex;
    final isSale = widget.contractType == ContractType.sale;
    return _card(
      isDark: isDark,
      icon: Icons.tune_rounded,
      title: l10n.contractDetails,
      child: Column(
        children: [
          // ── Rental fields ──
          if (isRental) ...[
            _fieldRow(
              label: l10n.contractPaymentDay,
              controller: _paymentDayController,
              isDark: isDark,
              onChanged: (_) => _regenerate(),
            ),
            const SizedBox(height: 12),
            _fieldRow(
              label: l10n.contractSyndicAmount,
              controller: _syndicAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              suffix: l10n.currency,
              isDark: isDark,
              onChanged: (_) => _regenerate(),
            ),
            const SizedBox(height: 12),
            _fieldRow(
              label: l10n.contractAnnualIncrease,
              controller: _annualIncreaseRateController,
              keyboardType: TextInputType.number,
              suffix: '%',
              isDark: isDark,
              onChanged: (_) => _regenerate(),
            ),
            const SizedBox(height: 12),
            _fieldRow(
              label: l10n.contractJurisdiction,
              controller: _jurisdictionCourtController,
              isDark: isDark,
              onChanged: (_) => _regenerate(),
            ),
          ],

          // ── Sale fields ──
          if (isSale) ...[
            _fieldRow(
              label: l10n.contractJurisdiction,
              controller: _jurisdictionCourtController,
              isDark: isDark,
              onChanged: (_) => _regenerate(),
            ),
          ],

          // ── Annex fields: original contract reference ──
          if (isAnnex) ...[
            _fieldRow(
              label: l10n.contractOriginalDate,
              controller: _originalContractDateController,
              isDark: isDark,
              onChanged: (_) => _regenerate(),
            ),
            const SizedBox(height: 12),
            _fieldRow(
              label: l10n.contractRegistrationDate,
              controller: _registrationDateController,
              isDark: isDark,
              onChanged: (_) => _regenerate(),
            ),
            const SizedBox(height: 12),
            _fieldRow(
              label: l10n.contractTaxOffice,
              controller: _taxOfficeController,
              isDark: isDark,
              onChanged: (_) => _regenerate(),
            ),
            const SizedBox(height: 12),
            _fieldRow(
              label: l10n.contractReceiptNumber,
              controller: _receiptNumberController,
              keyboardType: TextInputType.number,
              isDark: isDark,
              onChanged: (_) => _regenerate(),
            ),
            const SizedBox(height: 12),
            _fieldRow(
              label: l10n.contractRegistrationNumber,
              controller: _registrationNumberController,
              keyboardType: TextInputType.number,
              isDark: isDark,
              onChanged: (_) => _regenerate(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatesCard(AppLocalizations l10n, bool isDark) {
    return _card(
      isDark: isDark,
      icon: Icons.calendar_month_rounded,
      title: l10n.contractDates,
      child: Column(
        children: [
          _dateField(
            label: l10n.contractStartDate,
            controller: _startDateController,
            isDark: isDark,
            onTap: () => _pickDate(isStart: true),
          ),
          const SizedBox(height: 12),
          _dateField(
            label: l10n.contractEndDate,
            controller: _endDateController,
            isDark: isDark,
            onTap: () => _pickDate(isStart: false),
          ),
        ],
      ),
    );
  }

  Widget _buildContractBody(AppLocalizations l10n, bool isDark) {
    final text =
        _isEditing ? null : (_vm.generatedContent.isNotEmpty ? _vm.generatedContent : _contentController.text);

    return _card(
      isDark: isDark,
      icon: Icons.article_rounded,
      title: l10n.contractContent,
      child: _isEditing
          ? TextField(
              controller: _contentController,
              maxLines: null,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 14,
                height: 1.8,
                fontFamily: 'serif',
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                hintText: l10n.contractContentHint,
              ),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE0D8CC),
                ),
              ),
              child: SelectableText(
                text ?? '',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.8,
                  fontFamily: 'serif',
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ),
    );
  }

  Widget _buildActions(AppLocalizations l10n, bool isDark) {
    final saved = _vm.selected != null;
    final isEditable = !saved || _vm.selected!.isEditable;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        // Regenerate from template
        if (isEditable)
          OutlinedButton.icon(
            onPressed: _vm.isLoading ? null : _regenerate,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.contractRegenerate),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
          ),

        // Save draft
        if (!saved)
          ElevatedButton.icon(
            onPressed: _vm.isLoading ? null : _saveDraft,
            icon: _vm.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(l10n.contractSave),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
          ),

        // Update existing
        if (saved && isEditable)
          ElevatedButton.icon(
            onPressed: _vm.isLoading ? null : _updateDraft,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(l10n.contractUpdate),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
          ),

        // Send for signatures
        if (saved && isEditable)
          ElevatedButton.icon(
            onPressed: _vm.isLoading ? null : _sendForSignatures,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(l10n.contractSendForSignatures),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
          ),
      ],
    );
  }

  // ─── Card helper ──────────────────────────────────────────────

  Widget _card({
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _fieldRow({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    TextInputType? keyboardType,
    String? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
    );
  }

  Widget _dateField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────

  void _regenerate() {
    _vm.generateFromTemplate(
      type: widget.contractType,
      application: widget.application,
      overrides: {
        'paymentDay': _paymentDayController.text,
        'contractDuration': _durationController.text,
        'syndicAmount': _syndicAmountController.text,
        'annualIncreaseRate': _annualIncreaseRateController.text,
        'propertyType': _propertyTypeController.text,
        'jurisdictionCourt': _jurisdictionCourtController.text,
        'originalContractDate': _originalContractDateController.text,
        'registrationDate': _registrationDateController.text,
        'taxOfficeName': _taxOfficeController.text,
        'receiptNumber': _receiptNumberController.text,
        'registrationNumber': _registrationNumberController.text,
        if (_startDate != null) 'startDate': _formatDate(_startDate!),
        if (_endDate != null) 'endDate': _formatDate(_endDate!),
      },
    );
    _contentController.text = _vm.generatedContent;
    setState(() {});
  }

  Future<void> _saveDraft() async {
    final ok = await _vm.createContract(
      applicationId: widget.application.id,
      type: widget.contractType,
      dealAmount: widget.application.dealAmount ?? 0,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.contractSaved),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _updateDraft() async {
    if (_vm.selected == null) return;
    final ok = await _vm.updateContract(
      id: _vm.selected!.id,
      content: _contentController.text,
      fields: _vm.editableFields,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.contractUpdate),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _sendForSignatures() async {
    if (_vm.selected == null) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.contractSendForSignatures),
        content: Text(l10n.contractSendConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.confirmAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await _vm.sendForSignatures(_vm.selected!.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.contractSentForSignatures),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(const Duration(days: 365)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        _startDateController.text = _formatDate(picked);
      } else {
        _endDate = picked;
        _endDateController.text = _formatDate(picked);
      }
    });

    _regenerate();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
