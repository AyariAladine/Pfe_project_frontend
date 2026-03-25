import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/user_model.dart';
import '../../viewmodels/lawyer/lawyer_list_viewmodel.dart';
import '../widgets/network_image_with_auth.dart';

/// Embeddable lawyer detail content (no Scaffold) for use inside MainShell
class LawyerDetailContent extends StatefulWidget {
  final UserModel lawyer;
  final VoidCallback onBack;

  const LawyerDetailContent({
    super.key,
    required this.lawyer,
    required this.onBack,
  });

  @override
  State<LawyerDetailContent> createState() => _LawyerDetailContentState();
}

class _LawyerDetailContentState extends State<LawyerDetailContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LawyerListViewModel>().loadLawyerDetail(widget.lawyer.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<LawyerListViewModel>(
      builder: (context, vm, _) {
        final lawyer = vm.selectedLawyer ?? widget.lawyer;

        if (vm.isLoadingDetail) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.detailError != null) {
          return _buildError(vm, l10n, isDark);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Back button row
              Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: Text(l10n.back),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Profile header card
              _buildProfileCard(lawyer, l10n, isDark),
              const SizedBox(height: 20),

              // Contact information card
              _buildInfoCard(
                title: l10n.translate('contactInfo'),
                icon: Icons.contact_mail_rounded,
                isDark: isDark,
                children: [
                  _buildInfoRow(
                    Icons.email_outlined,
                    l10n.email,
                    lawyer.email,
                    isDark,
                  ),
                  if (lawyer.phoneNumber.isNotEmpty &&
                      lawyer.phoneNumber != '00000000')
                    _buildInfoRow(
                      Icons.phone_outlined,
                      l10n.phoneNumber,
                      lawyer.phoneNumber,
                      isDark,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Professional information card
              _buildInfoCard(
                title: l10n.translate('professionalInfo'),
                icon: Icons.work_outline_rounded,
                isDark: isDark,
                children: [
                  _buildInfoRow(
                    Icons.badge_outlined,
                    l10n.translate('role'),
                    l10n.lawyer,
                    isDark,
                  ),
                  if (lawyer.identityNumber.isNotEmpty &&
                      lawyer.identityNumber != '00000000')
                    _buildInfoRow(
                      Icons.credit_card_outlined,
                      l10n.identityNumber,
                      lawyer.identityNumber,
                      isDark,
                    ),
                  // Verification status
                  _buildVerificationBadge(lawyer, l10n, isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Office location card
              if (lawyer.latitude != null && lawyer.longitude != null)
                ...[
                  _buildLocationCard(lawyer, l10n, isDark),
                  const SizedBox(height: 16),
                ],

              // Account details card
              if (lawyer.createdAt != null)
                _buildInfoCard(
                  title: l10n.translate('accountDetails'),
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                  children: [
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      l10n.translate('memberSince'),
                      _formatDate(lawyer.createdAt!, l10n),
                      isDark,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(
      UserModel lawyer, AppLocalizations l10n, bool isDark) {
    final initials =
        '${lawyer.name.isNotEmpty ? lawyer.name[0] : ''}${lawyer.lastName.isNotEmpty ? lawyer.lastName[0] : ''}'
            .toUpperCase();
    final hasImage = lawyer.profileImageUrl != null &&
        lawyer.profileImageUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with image support
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? ClipOval(
                    child: NetworkImageWithAuth(
                      imageUrl: ApiConstants.getLawyerPictureUrl(
                          lawyer.profileImageUrl),
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      placeholder: () => Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      errorBuilder: () => Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            lawyer.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.gavel_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.lawyer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Location indicator
          if (lawyer.latitude != null && lawyer.longitude != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${lawyer.latitude!.toStringAsFixed(4)}, ${lawyer.longitude!.toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ─── Degree preview inside professional info card ──────────────────

  Widget _buildVerificationBadge(
      UserModel lawyer, AppLocalizations l10n, bool isDark) {
    final isVerified = lawyer.isVerified == true;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.help_outline_rounded,
            size: 18,
            color: isVerified ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isVerified ? l10n.verified : l10n.notVerified,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isVerified
                    ? AppColors.success
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
              ),
            ),
          ),
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    l10n.verified,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Office location card with map + Google Maps link ──────────────

  Widget _buildLocationCard(
      UserModel lawyer, AppLocalizations l10n, bool isDark) {
    final lat = lawyer.latitude!;
    final lng = lawyer.longitude!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 20,
                  color:
                      isDark ? AppColors.primaryLight : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.officeLocation,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Map preview
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.aqari.pfe_project',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          size: 40,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Coordinates + Google Maps button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Coordinates row
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.my_location_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Google Maps button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openGoogleMaps(lat, lng),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: Text(l10n.openInGoogleMaps),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final url = Uri.parse(ApiConstants.getGoogleMapsUrl(lat, lng));
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback: try without specifying mode
      try {
        await launchUrl(url);
      } catch (_) {}
    }
  }

  Widget _buildError(
      LawyerListViewModel vm, AppLocalizations l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.unexpectedError,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.back),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    vm.loadLawyerDetail(widget.lawyer.id),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.tryAgain),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
