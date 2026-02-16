import 'package:flutter/material.dart';
import 'package:pfe_project/core/localization/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../models/property_model.dart';
import '../widgets/network_image_with_auth.dart';

/// Embeddable property detail content (no Scaffold) for use inside MainShell
class PropertyDetailContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Back button row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(AppLocalizations.of(context)!.translate('back')),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.info,
                tooltip: AppLocalizations.of(context)!.edit,
                onPressed: () => _navigateToEdit(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                tooltip: AppLocalizations.of(context)!.delete,
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 240,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              property.imageUrl != null
                                  ? NetworkImageWithAuth(
                                      imageUrl: property.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: () => _buildImagePlaceholder(context, isDark),
                                      errorBuilder: () => _buildImagePlaceholder(context, isDark),
                                    )
                                  : _buildImagePlaceholder(context, isDark),
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                              // Badges
                              Positioned(
                                left: 16,
                                bottom: 16,
                                child: Row(
                                  children: [
                                    _buildBadge(
                                      property.propertyType == PropertyType.sale
                                          ? AppLocalizations.of(context)!.forSale
                                          : AppLocalizations.of(context)!.forRent,
                                      property.propertyType == PropertyType.sale
                                          ? AppColors.accent
                                          : AppColors.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildBadge(
                                      property.propertyStatus.displayName,
                                      _getStatusColor(property.propertyStatus),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Details
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Address
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 18,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  property.propertyAddress,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Quick info cards
                          _buildQuickInfoCards(context, isDark),
                          const SizedBox(height: 20),

                          // Location section
                          _buildLocationSection(context, isDark),
                          const SizedBox(height: 20),

                          // Details section
                          _buildDetailsSection(context, isDark),
                          const SizedBox(height: 20),

                          // Documents
                          if (property.registrationDocument != null) ...[
                            _buildDocumentsSection(context, isDark),
                            const SizedBox(height: 20),
                          ],

                          // Timestamps
                          _buildTimestampsSection(context, isDark),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Reuse the same helper methods from PropertyDetailView
  Widget _buildImagePlaceholder(BuildContext context, bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Center(
        child: Icon(Icons.home_outlined, size: 50,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildQuickInfoCards(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildInfoCard(icon: Icons.category_outlined,
          label: AppLocalizations.of(context)!.type,
          value: property.propertyType == PropertyType.sale
              ? AppLocalizations.of(context)!.forSale : AppLocalizations.of(context)!.forRent,
          isDark: isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoCard(icon: Icons.info_outline,
          label: AppLocalizations.of(context)!.status,
          value: property.propertyStatus.displayName, isDark: isDark)),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
      ]),
    );
  }

  Widget _buildLocationSection(BuildContext context, bool isDark) {
    final hasCoordinates = property.latitude != null && property.longitude != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context)!.location, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              height: 120, width: double.infinity,
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.1)],
              )),
              child: Stack(alignment: Alignment.center, children: [
                Icon(Icons.map, size: 40, color: AppColors.primary.withValues(alpha: 0.3)),
                if (hasCoordinates) const Icon(Icons.location_pin, size: 28, color: AppColors.error),
                if (!hasCoordinates) Text(AppLocalizations.of(context)!.locationNotSet,
                  style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              ]),
            ),
          ),
          if (hasCoordinates) Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(child: Row(children: [
                const Icon(Icons.north, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(child: Text('${AppLocalizations.of(context)!.latitude}: ${property.latitude}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary))),
              ])),
              Expanded(child: Row(children: [
                const Icon(Icons.east, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(child: Text('${AppLocalizations.of(context)!.longitude}: ${property.longitude}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary))),
              ])),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildDetailsSection(BuildContext context, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context)!.propertyDetails, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          _buildDetailRow(AppLocalizations.of(context)!.address, property.propertyAddress, isDark),
          _buildDetailRow(AppLocalizations.of(context)!.type,
            property.propertyType == PropertyType.sale ? AppLocalizations.of(context)!.forSale : AppLocalizations.of(context)!.forRent, isDark),
          _buildDetailRow(AppLocalizations.of(context)!.status, property.propertyStatus.displayName, isDark),
          if (property.contractId != null)
            _buildDetailRow(AppLocalizations.of(context)!.contractId, property.contractId!, isDark, isLast: true),
        ]),
      ),
    ]);
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool isLast = false}) {
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))),
        ],
      )),
      if (!isLast) Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.border),
    ]);
  }

  Widget _buildDocumentsSection(BuildContext context, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context)!.documents, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context)!.registrationDocument, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            Text(AppLocalizations.of(context)!.uploaded, style: const TextStyle(fontSize: 12, color: AppColors.success)),
          ])),
        ]),
      ),
    ]);
  }

  Widget _buildTimestampsSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark.withValues(alpha: 0.5) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        if (property.createdAt != null) Row(children: [
          Icon(Icons.calendar_today_outlined, size: 15,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('${AppLocalizations.of(context)!.created}: ${_formatDate(property.createdAt!)}',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
        ]),
        if (property.updatedAt != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.update_outlined, size: 15,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text('${AppLocalizations.of(context)!.updated}: ${_formatDate(property.updatedAt!)}',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
          ]),
        ],
      ]),
    );
  }

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available: return AppColors.success;
      case PropertyStatus.rented: return AppColors.info;
      case PropertyStatus.sold: return AppColors.secondary;
      case PropertyStatus.pending: return AppColors.warning;
      case PropertyStatus.unavailable: return AppColors.error;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  void _navigateToEdit(BuildContext context) {
    onEditProperty?.call(property);
  }

  void _confirmDelete(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 32)),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.deleteProperty, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.deletePropertyConfirm, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text(AppLocalizations.of(context)!.cancel))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    if (property.id != null) onPropertyDeleted?.call(property.id!);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text(AppLocalizations.of(context)!.delete))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}