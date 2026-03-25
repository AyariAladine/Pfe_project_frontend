import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/property_model.dart';
import '../../services/favorites_service.dart';
import '../../services/token_service.dart';
import '../widgets/network_image_with_auth.dart';

/// Embeddable property detail content (no Scaffold) for use inside MainShell
class PropertyDetailContent extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback onBack;
  final void Function(PropertyModel updatedProperty)? onPropertyUpdated;
  final void Function(String propertyId)? onPropertyDeleted;
  final void Function(PropertyModel property)? onEditProperty;

  const PropertyDetailContent({
    super.key,
    required this.property,
    required this.onBack,
    this.onPropertyUpdated,
    this.onPropertyDeleted,
    this.onEditProperty,
  });

  @override
  State<PropertyDetailContent> createState() => _PropertyDetailContentState();
}

class _PropertyDetailContentState extends State<PropertyDetailContent> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await TokenService.getUserId();
    if (mounted) setState(() => _currentUserId = id);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Convenience accessors
  PropertyModel get property => widget.property;
  bool get _isOwned => _currentUserId != null && property.ownerId == _currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              const Spacer(),
              if (!_isOwned)
                Consumer<FavoritesService>(
                builder: (context, favService, _) {
                  final isFav = property.id != null && favService.isFavorite(property.id!);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.star_rounded : Icons.star_border_rounded,
                    ),
                    color: isFav ? AppColors.warning : AppColors.textSecondary,
                    tooltip: isFav ? l10n.removeFromFavorites : l10n.addToFavorites,
                    onPressed: () {
                      if (property.id != null) {
                        favService.toggleFavorite(property.id!);
                      }
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                color: AppColors.primary,
                tooltip: l10n.translate('share'),
                onPressed: () => _shareProperty(l10n),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.info,
                tooltip: l10n.edit,
                onPressed: () => _navigateToEdit(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                tooltip: l10n.delete,
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Property header card
          _buildPropertyCard(l10n, isDark),
          const SizedBox(height: 20),

          // Property Information card
          _buildInfoCard(
            title: l10n.propertyInformation,
            icon: Icons.home_outlined,
            isDark: isDark,
            children: [
              _buildInfoRow(
                Icons.location_on_outlined,
                l10n.address,
                property.propertyAddress,
                isDark,
              ),
              _buildInfoRow(
                Icons.category_outlined,
                l10n.type,
                property.propertyType == PropertyType.sale
                    ? l10n.forSale
                    : l10n.forRent,
                isDark,
              ),
              _buildInfoRow(
                Icons.info_outline,
                l10n.status,
                property.propertyStatus.displayName,
                isDark,
                valueColor: _getStatusColor(property.propertyStatus),
              ),
              if (property.description != null && property.description!.isNotEmpty)
                _buildInfoRow(
                  Icons.description_outlined,
                  l10n.descriptionOptional,
                  property.description!,
                  isDark,
                ),
              if (property.contractId != null && property.contractId!.isNotEmpty)
                _buildInfoRow(
                  Icons.description_outlined,
                  l10n.contractId,
                  property.contractId!,
                  isDark,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Owner Information card (if available)
          if (property.owner != null) ...[
            _buildInfoCard(
              title: l10n.ownerInformation,
              icon: Icons.person_outline_rounded,
              isDark: isDark,
              children: [
                if (property.owner!['name'] != null ||
                    property.owner!['lastName'] != null)
                  _buildInfoRow(
                    Icons.person_outline,
                    l10n.ownerName,
                    '${property.owner!['name'] ?? ''} ${property.owner!['lastName'] ?? ''}'
                        .trim(),
                    isDark,
                  ),
                if (property.owner!['email'] != null)
                  _buildInfoRow(
                    Icons.email_outlined,
                    l10n.email,
                    property.owner!['email'],
                    isDark,
                  ),
                if (property.owner!['phoneNumber'] != null &&
                    property.owner!['phoneNumber'] != '00000000')
                  _buildInfoRow(
                    Icons.phone_outlined,
                    l10n.phoneNumber,
                    property.owner!['phoneNumber'],
                    isDark,
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Location card
          if (property.latitude != null && property.longitude != null) ...[
            _buildLocationCard(l10n, isDark),
            const SizedBox(height: 16),
          ],

          // Documents card
          if (property.registrationDocument != null &&
              property.registrationDocument!.isNotEmpty) ...[
            _buildInfoCard(
              title: l10n.documents,
              icon: Icons.folder_outlined,
              isDark: isDark,
              children: [
                _buildDocumentRow(l10n, isDark),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Account details (timestamps)
          if (property.createdAt != null)
            _buildInfoCard(
              title: l10n.translate('accountDetails'),
              icon: Icons.info_outline_rounded,
              isDark: isDark,
              children: [
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  l10n.created,
                  _formatDate(property.createdAt!),
                  isDark,
                ),
                if (property.updatedAt != null)
                  _buildInfoRow(
                    Icons.update_outlined,
                    l10n.updated,
                    _formatDate(property.updatedAt!),
                    isDark,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Property Header Card (catalog style) ─────────────────────────

  Widget _buildPropertyCard(AppLocalizations l10n, bool isDark) {
    final images = property.imageUrls;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image gallery ──
          _buildImageGrid(images, isDark),

          // ── Info section ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address
                Text(
                  property.propertyAddress,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Type and Status badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildHeaderBadge(
                      property.propertyType == PropertyType.sale
                          ? l10n.forSale
                          : l10n.forRent,
                      property.propertyType == PropertyType.sale
                          ? Icons.sell_rounded
                          : Icons.vpn_key_rounded,
                      badgeColor: AppColors.primary,
                      isDark: isDark,
                    ),
                    _buildHeaderBadge(
                      property.propertyStatus.displayName,
                      Icons.circle,
                      badgeColor: _getStatusColor(property.propertyStatus),
                      isDark: isDark,
                    ),
                  ],
                ),

                // Location indicator
                if (property.latitude != null &&
                    property.longitude != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          size: 15),
                      const SizedBox(width: 4),
                      Text(
                        '${double.tryParse(property.latitude!)?.toStringAsFixed(4) ?? property.latitude}, ${double.tryParse(property.longitude!)?.toStringAsFixed(4) ?? property.longitude}',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String text, IconData icon,
      {Color? badgeColor, bool isDark = false}) {
    final color = badgeColor ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Image Grid (uniform columns, all images visible) ──────────────

  Widget _buildImageGrid(List<String> images, bool isDark) {
    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SizedBox(height: 240, child: _buildImagePlaceholder()),
      );
    }

    // 1 → 1 col, 2 → 2 cols, 3+ → 3 cols
    final cols = images.length == 1 ? 1 : images.length == 2 ? 2 : 3;
    const cellHeight = 260.0;
    final rows = (images.length / cols).ceil();
    final gridHeight = rows * cellHeight + (rows - 1) * 3;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: gridHeight,
        child: Column(
          children: List.generate(rows, (row) {
            final start = row * cols;
            final end = (start + cols).clamp(0, images.length);
            final rowImages = images.sublist(start, end);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: row > 0 ? 3 : 0),
                child: Row(
                  children: List.generate(rowImages.length, (col) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: col > 0 ? 3 : 0),
                        child: GestureDetector(
                          onTap: () => _openImageViewer(context, images, start + col),
                          child: NetworkImageWithAuth(
                            imageUrl: rowImages[col],
                            fit: BoxFit.cover,
                            placeholder: () => _buildImagePlaceholder(),
                            errorBuilder: () => _buildImagePlaceholder(),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── Fullscreen image lightbox ──────────────────────────────────

  void _openImageViewer(BuildContext context, List<String> images, int initial) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (_) => _ImageLightbox(images: images, initialIndex: initial),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.home_outlined, size: 50, color: Colors.white70),
      ),
    );
  }

  // ─── Info Card (like _buildInfoCard in lawyer_detail_view) ─────────

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

  // ─── Info Row (like _buildInfoRow in lawyer_detail_view) ───────────

  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isDark,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
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
                    color: valueColor ??
                        (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Document Row ─────────────────────────────────────────────────

  Widget _buildDocumentRow(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.registrationDocument,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.uploaded,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.success),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    size: 14, color: AppColors.success),
                SizedBox(width: 4),
                Icon(Icons.verified_rounded,
                    size: 14, color: AppColors.success),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Location card with map + Google Maps link ─────────────────────

  Widget _buildLocationCard(AppLocalizations l10n, bool isDark) {
    final lat = double.tryParse(property.latitude ?? '');
    final lng = double.tryParse(property.longitude ?? '');
    if (lat == null || lng == null) return const SizedBox.shrink();

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
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.propertyLocation,
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
                      const Icon(Icons.my_location_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                        style: const TextStyle(
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
      try {
        await launchUrl(url);
      } catch (_) {}
    }
  }

  void _shareProperty(AppLocalizations l10n) {
    final type = property.propertyType == PropertyType.sale
        ? l10n.forSale
        : l10n.forRent;
    final status = property.propertyStatus.displayName;
    final address = property.propertyAddress;
    final description = property.description ?? '';

    final buffer = StringBuffer();
    buffer.writeln('🏠 $type — $address');
    buffer.writeln('📋 ${l10n.status}: $status');
    if (description.isNotEmpty) {
      buffer.writeln('📝 $description');
    }
    if (property.latitude != null && property.longitude != null) {
      final lat = double.tryParse(property.latitude!);
      final lng = double.tryParse(property.longitude!);
      if (lat != null && lng != null) {
        buffer.writeln(
          '📍 ${ApiConstants.getGoogleMapsUrl(lat, lng)}',
        );
      }
    }
    buffer.writeln('\n— Aqari | عقاري');

    Share.share(buffer.toString());
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return AppColors.success;
      case PropertyStatus.rented:
        return AppColors.info;
      case PropertyStatus.sold:
        return AppColors.secondary;
      case PropertyStatus.pending:
        return AppColors.warning;
      case PropertyStatus.unavailable:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _navigateToEdit(BuildContext context) {
    widget.onEditProperty?.call(property);
  }

  void _confirmDelete(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever_rounded,
                      color: AppColors.error, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.deleteProperty,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.deletePropertyConfirm,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          side: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          if (property.id != null) {
                            widget.onPropertyDeleted?.call(property.id!);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(l10n.delete),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Fullscreen image lightbox widget -------------------------------------

class _ImageLightbox extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageLightbox({required this.images, required this.initialIndex});

  @override
  State<_ImageLightbox> createState() => _ImageLightboxState();
}

class _ImageLightboxState extends State<_ImageLightbox> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _prev() {
    if (_current > 0) _ctrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _next() {
    if (_current < widget.images.length - 1) _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Full image PageView
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: NetworkImageWithAuth(
                  imageUrl: widget.images[i],
                  fit: BoxFit.contain,
                  placeholder: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorBuilder: () => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ),

          // Counter
          if (widget.images.length > 1)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${_current + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

          // Left arrow
          if (_current > 0)
            Positioned(
              left: 12, top: 0, bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _prev,
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 36),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45, shape: const CircleBorder(), padding: const EdgeInsets.all(8)),
                ),
              ),
            ),

          // Right arrow
          if (_current < widget.images.length - 1)
            Positioned(
              right: 12, top: 0, bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _next,
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 36),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45, shape: const CircleBorder(), padding: const EdgeInsets.all(8)),
                ),
              ),
            ),

          // Dot indicators
          if (widget.images.length > 1)
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _current == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _current == i ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}
