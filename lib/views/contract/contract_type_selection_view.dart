import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/application_model.dart';
import '../../models/contract_model.dart';

/// GridView screen for the lawyer to choose which contract template to draft.
///
/// Displays one card per [ContractType]. Each card shows the contract icon,
/// title, description, and an "auto-filled from application" badge so the
/// lawyer knows the parties / property fields will be pre-populated.
///
/// Adding a new contract type requires only adding a new [_ContractTypeOption]
/// to [_options] — the grid reflows automatically.
class ContractTypeSelectionContent extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onBack;
  final void Function(ContractType type) onTypeSelected;

  const ContractTypeSelectionContent({
    super.key,
    required this.application,
    required this.onBack,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = _buildOptions(l10n);

    return Column(
      children: [
        _AppBar(
          title: l10n.selectContractType,
          isDark: isDark,
          onBack: onBack,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Application summary strip
                _ApplicationSummaryCard(
                  application: application,
                  isDark: isDark,
                  l10n: l10n,
                ),
                const SizedBox(height: 20),

                // Contract type grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, i) => _ContractTypeCard(
                    option: options[i],
                    isDark: isDark,
                    autoFilledLabel: l10n.contractAutoFilled,
                    onTap: () => onTypeSelected(options[i].type),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_ContractTypeOption> _buildOptions(AppLocalizations l10n) => [
        _ContractTypeOption(
          type: ContractType.rental,
          icon: Icons.home_rounded,
          color: AppColors.primary,
          title: l10n.contractTypeRental,
          description: l10n.contractTypeRentalDesc,
        ),
        _ContractTypeOption(
          type: ContractType.rentalAnnex,
          icon: Icons.note_add_rounded,
          color: Colors.teal,
          title: l10n.contractTypeRentalAnnex,
          description: l10n.contractTypeRentalAnnexDesc,
        ),
        _ContractTypeOption(
          type: ContractType.sale,
          icon: Icons.sell_rounded,
          color: Colors.orange,
          title: l10n.contractTypeSale,
          description: l10n.contractTypeSaleDesc,
        ),
      ];
}

// ─── Data class ──────────────────────────────────────────────────────────────

class _ContractTypeOption {
  final ContractType type;
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _ContractTypeOption({
    required this.type,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onBack;

  const _AppBar({
    required this.title,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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

class _ApplicationSummaryCard extends StatelessWidget {
  final ApplicationModel application;
  final bool isDark;
  final AppLocalizations l10n;

  const _ApplicationSummaryCard({
    required this.application,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property address
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  application.propertyAddress,
                  maxLines: 1,
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
          const SizedBox(height: 8),
          // Parties
          Row(
            children: [
              _partyChip(Icons.home_rounded, application.ownerName,
                  isDark, context),
              const SizedBox(width: 8),
              Icon(Icons.swap_horiz_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary),
              const SizedBox(width: 8),
              _partyChip(Icons.person_rounded, application.applicantName,
                  isDark, context),
            ],
          ),
          if (application.dealAmount != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money_rounded,
                    size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '${application.dealAmount!.toStringAsFixed(2)} ${l10n.currency}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _partyChip(
      IconData icon, String name, bool isDark, BuildContext context) {
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
}

class _ContractTypeCard extends StatelessWidget {
  final _ContractTypeOption option;
  final bool isDark;
  final String autoFilledLabel;
  final VoidCallback onTap;

  const _ContractTypeCard({
    required this.option,
    required this.isDark,
    required this.autoFilledLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: option.color, size: 26),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                option.title,
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
              const SizedBox(height: 6),

              // Description
              Expanded(
                child: Text(
                  option.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Auto-filled badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 10, color: option.color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        autoFilledLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: option.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
