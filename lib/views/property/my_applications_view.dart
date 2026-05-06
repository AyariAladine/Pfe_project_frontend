import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/application_model.dart';
import '../../viewmodels/property/application_viewmodel.dart';
import '../widgets/network_image_with_auth.dart';

/// Content view showing the user's property applications (no Scaffold)
class MyApplicationsContent extends StatefulWidget {
  /// Called when user taps "View Property" on an application
  final void Function(String propertyId)? onViewProperty;

  /// Called when user taps on an application card to see its detail
  final void Function(String applicationId)? onApplicationSelected;

  const MyApplicationsContent({super.key, this.onViewProperty, this.onApplicationSelected});

  @override
  State<MyApplicationsContent> createState() => _MyApplicationsContentState();
}

class _MyApplicationsContentState extends State<MyApplicationsContent> {
  final ApplicationViewModel _vm = ApplicationViewModel();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
    _vm.loadMyApplications();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vm.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              _vm.error!,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _vm.loadMyApplications(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_vm.applications.isEmpty) {
      return _buildEmptyState(l10n, isDark);
    }

    final visitedApps = _vm.applications
        .where((a) =>
            a.status == ApplicationStatus.visitScheduled && a.visitDate != null)
        .toList()
      ..sort((a, b) => (a.visitDate ?? DateTime(2099))
          .compareTo(b.visitDate ?? DateTime(2099)));

    return RefreshIndicator(
      onRefresh: () => _vm.loadMyApplications(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Upcoming visits section
          if (visitedApps.isNotEmpty) ...[
            Text(
              'Upcoming Visits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visitedApps.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildVisitCard(visitedApps[index], l10n, isDark);
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All Applications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // All applications list
          ..._vm.applications.asMap().entries.map((entry) {
            final index = entry.key;
            final app = entry.value;
            final isLast = index == _vm.applications.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: _buildApplicationCard(app, l10n, isDark),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(Icons.send_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noApplicationsYet,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noApplicationsDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    final statusColor = _getStatusColor(app.status);

    return InkWell(
      onTap: widget.onApplicationSelected != null
          ? () => widget.onApplicationSelected!(app.id)
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image + address row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Property thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: app.propertyFirstImage != null
                        ? NetworkImageWithAuth(
                            imageUrl: _resolveImageUrl(app.propertyFirstImage!),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            child: Icon(
                              Icons.apartment_rounded,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                              size: 32,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Address + type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.propertyAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildSmallBadge(
                            app.type == ApplicationType.rent
                                ? l10n.rent
                                : l10n.buy,
                            AppColors.info,
                          ),
                          const SizedBox(width: 8),
                          _buildSmallBadge(
                            _localizedStatus(l10n, app.status),
                            statusColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),

          // Bottom row: applied date + actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${l10n.appliedOn} ${_formatDate(app.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),

                // View Property button
                if (widget.onViewProperty != null)
                  TextButton.icon(
                    onPressed: () =>
                        widget.onViewProperty!(app.propertyId),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(l10n.viewProperty,
                        style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                // Cancel if pending
                if (app.status == ApplicationStatus.pending) ...[
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: _vm.isApplying
                        ? null
                        : () => _confirmCancel(l10n, isDark, app.id),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: Text(l10n.cancelApplication,
                        style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Optional message
          if (app.message != null && app.message!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                app.message!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildSmallBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _confirmCancel(AppLocalizations l10n, bool isDark, String appId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.cancelApplication),
        content: Text(l10n.cancelApplicationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _vm.cancelApplication(appId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.cancelApplication),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.underReview:
        return AppColors.info;
      case ApplicationStatus.visitScheduled:
        return AppColors.primary;
      case ApplicationStatus.preApproved:
        return const Color(0xFF7C4DFF);
      case ApplicationStatus.accepted:
        return AppColors.success;
      case ApplicationStatus.negotiation:
        return Colors.orange;
      case ApplicationStatus.awaitingLawyer:
        return Colors.indigo;
      case ApplicationStatus.contractDrafting:
        return AppColors.primary;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  String _localizedStatus(AppLocalizations l10n, ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return l10n.applicationStatusPending;
      case ApplicationStatus.underReview:
        return l10n.applicationStatusUnderReview;
      case ApplicationStatus.visitScheduled:
        return l10n.applicationStatusVisitScheduled;
      case ApplicationStatus.preApproved:
        return l10n.applicationStatusPreApproved;
      case ApplicationStatus.accepted:
        return l10n.applicationStatusAccepted;
      case ApplicationStatus.negotiation:
        return l10n.applicationStatusNegotiation;
      case ApplicationStatus.awaitingLawyer:
        return l10n.applicationStatusAwaitingLawyer;
      case ApplicationStatus.contractDrafting:
        return l10n.applicationStatusContractDrafting;
      case ApplicationStatus.rejected:
        return l10n.applicationStatusRejected;
      case ApplicationStatus.cancelled:
        return l10n.applicationStatusCancelled;
    }
  }

  String _resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '${ApiConstants.baseUrl}$path';
    return '${ApiConstants.baseUrl}/uploads/properties/images/$path';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildVisitCard(ApplicationModel app, AppLocalizations l10n, bool isDark) {
    final visitDate = app.visitDate;
    if (visitDate == null) return const SizedBox.shrink();

    final dayStr = visitDate.day.toString();
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = monthNames[visitDate.month - 1];
    final timeStr =
        '${visitDate.hour.toString().padLeft(2, '0')}:${visitDate.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: widget.onApplicationSelected != null
          ? () => widget.onApplicationSelected!(app.id)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Date display
            Column(
              children: [
                Text(
                  dayStr,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  monthStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Time
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Property address snippet
            Text(
              app.propertyAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
