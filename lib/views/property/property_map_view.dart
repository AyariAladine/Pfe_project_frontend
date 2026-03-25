import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/property_model.dart';
import '../../viewmodels/property/property_list_viewmodel.dart';
import '../widgets/network_image_with_auth.dart';

/// Full-screen map showing all available properties as pins
class PropertyMapView extends StatefulWidget {
  final void Function(PropertyModel property)? onPropertySelected;

  const PropertyMapView({super.key, this.onPropertySelected});

  @override
  State<PropertyMapView> createState() => _PropertyMapViewState();
}

class _PropertyMapViewState extends State<PropertyMapView> {
  final MapController _mapController = MapController();
  PropertyModel? _selectedProperty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PropertyListViewModel>(
      builder: (context, viewModel, _) {
        final properties = viewModel.availableProperties
            .where((p) =>
                p.latitude != null &&
                p.longitude != null &&
                double.tryParse(p.latitude!) != null &&
                double.tryParse(p.longitude!) != null)
            .toList();

        // Default center: Tunisia (Tunis)
        final defaultCenter = LatLng(36.8065, 10.1815);

        // Center on user location if available, otherwise first property or Tunisia
        LatLng center;
        if (viewModel.hasUserLocation) {
          center = LatLng(viewModel.userLat!, viewModel.userLng!);
        } else if (properties.isNotEmpty) {
          center = LatLng(
            double.parse(properties.first.latitude!),
            double.parse(properties.first.longitude!),
          );
        } else {
          center = defaultCenter;
        }

        return Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 11,
                onTap: (_, __) {
                  setState(() => _selectedProperty = null);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.aqari.app',
                ),
                // Property markers
                MarkerLayer(
                  markers: properties.map((property) {
                    final lat = double.parse(property.latitude!);
                    final lng = double.parse(property.longitude!);
                    final isSelected = _selectedProperty?.id == property.id;

                    return Marker(
                      point: LatLng(lat, lng),
                      width: isSelected ? 48 : 40,
                      height: isSelected ? 48 : 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedProperty = property);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : property.propertyType == PropertyType.sale
                                    ? AppColors.primary
                                    : AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            property.propertyType == PropertyType.sale
                                ? Icons.sell_rounded
                                : Icons.vpn_key_rounded,
                            color: Colors.white,
                            size: isSelected ? 22 : 18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // User location marker
                if (viewModel.hasUserLocation)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(viewModel.userLat!, viewModel.userLng!),
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.info.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Legend
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceDark : AppColors.surface)
                      .withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${properties.length} ${l10n.translate('propertiesOnMap')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legendDot(AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(l10n.forRent,
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary)),
                        const SizedBox(width: 12),
                        _legendDot(AppColors.primary),
                        const SizedBox(width: 4),
                        Text(l10n.forSale,
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Property info card (bottom sheet style)
            if (_selectedProperty != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _PropertyInfoCard(
                  property: _selectedProperty!,
                  isDark: isDark,
                  distance: viewModel.distanceToProperty(_selectedProperty!),
                  onTap: () {
                    widget.onPropertySelected?.call(_selectedProperty!);
                  },
                  onClose: () {
                    setState(() => _selectedProperty = null);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}

/// Compact property card shown at bottom of map when a pin is tapped
class _PropertyInfoCard extends StatelessWidget {
  final PropertyModel property;
  final bool isDark;
  final double? distance;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _PropertyInfoCard({
    required this.property,
    required this.isDark,
    required this.onTap,
    required this.onClose,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 100,
                height: 100,
                child: property.imageUrl != null
                    ? NetworkImageWithAuth(
                        imageUrl: property.imageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: () => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (property.propertyType == PropertyType.sale
                                ? AppColors.accent
                                : AppColors.secondary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        property.propertyType == PropertyType.sale
                            ? l10n.forSale
                            : l10n.forRent,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: property.propertyType == PropertyType.sale
                              ? AppColors.accent
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Address
                    Text(
                      property.propertyAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${distance!.toStringAsFixed(1)} ${l10n.kmAway}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Close + chevron
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: Icon(Icons.close_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 100,
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Center(
        child: Icon(Icons.home_outlined,
            size: 28,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
      ),
    );
  }
}
