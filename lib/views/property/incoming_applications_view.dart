import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/application_model.dart';
import '../../viewmodels/property/owner_applications_viewmodel.dart';
import '../widgets/network_image_with_auth.dart';

/// Owner's incoming applications list (no Scaffold)
class IncomingApplicationsContent extends StatefulWidget {
  /// Called when owner taps an application to see detail
  final void Function(String applicationId)? onApplicationSelected;
  /// Called whenever the pending application count changes (for drawer badge)
  final void Function(int count)? onPendingCountChanged;

  const IncomingApplicationsContent({
    super.key,
    this.onApplicationSelected,
    this.onPendingCountChanged,
  });

  @override
  State<IncomingApplicationsContent> createState() =>
      _IncomingApplicationsContentState();
}

class _IncomingApplicationsContentState
    extends State<IncomingApplicationsContent> {
  final OwnerApplicationsViewModel _vm = OwnerApplicationsViewModel();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
    _vm.loadIncoming();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
      widget.onPendingCountChanged?.call(_vm.pendingCount);
    }
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
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(_vm.error!,
                style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _vm.loadIncoming(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    if (_vm.incoming.isEmpty) {
      return _buildEmptyState(l10n, isDark);
    }

    return RefreshIndicator(
      onRefresh: () => _vm.loadIncoming(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _vm.incoming.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildCard(_vm.incoming[index], l10n, isDark);
        },
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
              child: const Icon(Icons.inbox_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noIncomingApplications,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noIncomingApplicationsDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    final statusColor = _statusColor(app.status);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.onApplicationSelected?.call(app.id),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Applicant avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      app.applicantName.isNotEmpty
                          ? app.applicantName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.applicantName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          app.propertyAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _badge(
                              app.type == ApplicationType.rent
                                  ? l10n.rent
                                  : l10n.buy,
                              AppColors.info,
                            ),
                            const SizedBox(width: 8),
                            _badge(
                              _localizedStatus(l10n, app.status),
                              statusColor,
                            ),
                            if (app.unreadMessages > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${app.unreadMessages}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chevron
                  Icon(Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                ],
              ),
            ),

            // Bottom: date + property thumbnail
            Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.border),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // Property thumbnail
                  if (app.propertyFirstImage != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: NetworkImageWithAuth(
                            imageUrl:
                                _resolveImageUrl(app.propertyFirstImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  Icon(Icons.calendar_today_outlined,
                      size: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.appliedOn} ${_formatDate(app.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (app.message != null && app.message!.isNotEmpty) ...[
                    const Spacer(),
                    Icon(Icons.message_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _statusColor(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.underReview:
        return AppColors.info;
      case ApplicationStatus.visitScheduled:
        return Colors.deepPurple;
      case ApplicationStatus.preApproved:
        return Colors.teal;
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

  String _localizedStatus(AppLocalizations l10n, ApplicationStatus s) {
    switch (s) {
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

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
