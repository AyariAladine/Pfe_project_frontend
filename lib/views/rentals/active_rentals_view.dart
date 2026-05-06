import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/rental_model.dart';
import '../../viewmodels/rentals/rentals_viewmodel.dart';

class ActiveRentalsContent extends StatefulWidget {
  const ActiveRentalsContent({super.key});

  @override
  State<ActiveRentalsContent> createState() => _ActiveRentalsContentState();
}

class _ActiveRentalsContentState extends State<ActiveRentalsContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Consumer<RentalsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.error != null && vm.rentals.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(vm.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => vm.load(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n?.tryAgain ?? 'Try Again'),
                ),
              ],
            ),
          );
        }

        if (vm.rentals.isEmpty) {
          return _EmptyRentals(isDark: isDark);
        }

        return RefreshIndicator(
          onRefresh: vm.load,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: vm.rentals.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _RentalCard(
                rental: vm.rentals[i],
                isDark: isDark,
                isMarking: vm.isMarking,
                onMarkPaid: () => vm.markPaid(vm.rentals[i].id),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyRentals extends StatelessWidget {
  final bool isDark;
  const _EmptyRentals({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home_work_outlined,
              size: 38,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Rentals',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Completed rental contracts will appear here',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Rental card ──────────────────────────────────────────────────────────────

class _RentalCard extends StatefulWidget {
  final RentalModel rental;
  final bool isDark;
  final bool isMarking;
  final Future<bool> Function() onMarkPaid;

  const _RentalCard({
    required this.rental,
    required this.isDark,
    required this.isMarking,
    required this.onMarkPaid,
  });

  @override
  State<_RentalCard> createState() => _RentalCardState();
}

class _RentalCardState extends State<_RentalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.rental;
    final dueColor = r.isOverdue
        ? AppColors.error
        : r.isDueSoon
            ? AppColors.warning
            : AppColors.success;

    final dueLabel = r.isOverdue
        ? 'Overdue by ${-r.daysUntilDue} day${-r.daysUntilDue == 1 ? '' : 's'}'
        : r.daysUntilDue == 0
            ? 'Due today'
            : 'Due in ${r.daysUntilDue} day${r.daysUntilDue == 1 ? '' : 's'}';

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: r.isOverdue
            ? Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.5)
            : r.isDueSoon
                ? Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.5)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main card content ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.home_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.propertyAddress.isEmpty
                                ? 'Rental Property'
                                : r.propertyAddress,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.ownerName} ↔ ${r.tenantName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Due date badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: dueColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: dueColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        dueLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: dueColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Amount + due date row
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      label: '${r.monthlyAmount.toStringAsFixed(0)} TND/month',
                      isDark: widget.isDark,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: _fmt(r.nextDueDate),
                      isDark: widget.isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Mark as paid button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.isMarking
                        ? null
                        : () async {
                            final ok = await widget.onMarkPaid();
                            if (ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Payment marked — next due date updated'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                    icon: widget.isMarking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded,
                            size: 18),
                    label: const Text('Mark as Paid',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                if (r.paymentHistory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Expand/collapse payment history
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Payment history (${r.paymentHistory.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Payment history (collapsible) ──
          if (_expanded && r.paymentHistory.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: r.paymentHistory.reversed
                    .take(6)
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _fmt(p.paidAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              '${p.amount.toStringAsFixed(0)} TND',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
