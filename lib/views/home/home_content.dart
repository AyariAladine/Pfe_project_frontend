import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/property_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/property/property_list_viewmodel.dart';
import '../widgets/network_image_with_auth.dart';

/// Callback to navigate to a specific section from the dashboard
typedef OnNavigate = void Function(String destination, {PropertyModel? property});

/// Home page content — real dashboard
class HomeContent extends StatefulWidget {
  final OnNavigate? onNavigate;
  const HomeContent({super.key, this.onNavigate});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late PropertyListViewModel _propertyVM;

  @override
  void initState() {
    super.initState();
    _propertyVM = PropertyListViewModel();
    _propertyVM.loadProperties();
  }

  @override
  void dispose() {
    _propertyVM.dispose();
    super.dispose();
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 18) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authVM = context.watch<AuthViewModel>();
    final userName = authVM.currentUser?.name ?? '';

    return ChangeNotifierProvider.value(
      value: _propertyVM,
      child: Consumer<PropertyListViewModel>(
        builder: (context, vm, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final maxWidth = isWide ? 960.0 : constraints.maxWidth;

              return RefreshIndicator(
                onRefresh: vm.refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 20,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Greeting Card ──
                          _buildGreetingCard(l10n, isDark, userName),
                          const SizedBox(height: 24),

                          // ── Stats + Quick Actions (side by side on web) ──
                          if (!vm.isLoading && isWide) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildStatsRow(l10n, isDark, vm),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.quickActions,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildQuickActions(l10n, isDark),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],

                          // ── Stats + Quick Actions (stacked on mobile) ──
                          if (!vm.isLoading && !isWide) ...[
                            _buildStatsRow(l10n, isDark, vm),
                            const SizedBox(height: 24),
                            Text(
                              l10n.quickActions,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildQuickActions(l10n, isDark),
                            const SizedBox(height: 28),
                          ],

                          if (vm.isLoading) ...[
                            const SizedBox(height: 24),
                          ],

                          // ── Nearby Properties ──
                          _buildNearbySection(l10n, isDark, vm, isWide),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Greeting Card ──
  Widget _buildGreetingCard(AppLocalizations l10n, bool isDark, String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(l10n),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName.isNotEmpty ? userName : l10n.welcomeToAqari,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.managePropertiesEasily,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──
  Widget _buildStatsRow(AppLocalizations l10n, bool isDark, PropertyListViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: l10n.myListings,
            value: '${vm.myPropertyCount}',
            icon: Icons.home_work_rounded,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: l10n.availableNow,
            value: '${vm.availablePropertyCount}',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ──
  Widget _buildQuickActions(AppLocalizations l10n, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionChip(
            icon: Icons.add_home_rounded,
            label: l10n.addProperty,
            color: AppColors.primary,
            isDark: isDark,
            onTap: () => widget.onNavigate?.call('addProperty'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionChip(
            icon: Icons.explore_rounded,
            label: l10n.exploreProperties,
            color: AppColors.secondary,
            isDark: isDark,
            onTap: () => widget.onNavigate?.call('properties'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nearby Properties ──
  Widget _buildNearbySection(AppLocalizations l10n, bool isDark, PropertyListViewModel vm, bool isWide) {
    final properties = vm.nearbyProperties;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.near_me_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  l10n.nearbyProperties,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (vm.nearbyProperties.isNotEmpty)
              TextButton(
                onPressed: () => widget.onNavigate?.call('properties'),
                child: Text(l10n.viewAll),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (vm.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (!vm.hasUserLocation)
          _buildLocationPrompt(l10n, isDark, vm)
        else if (vm.nearbyProperties.isEmpty)
          _buildEmptyNearby(l10n, isDark)
        else if (isWide)
          ..._buildNearbyGrid(properties, vm, l10n, isDark)
        else
          ...properties.map((property) {
            final distance = vm.distanceToProperty(property);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNearbyCard(property, distance, l10n, isDark),
            );
          }),
      ],
    );
  }

  /// Builds a 2-column grid of nearby property cards for wide screens
  List<Widget> _buildNearbyGrid(
    List<PropertyModel> properties,
    PropertyListViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final List<Widget> rows = [];
    for (int i = 0; i < properties.length; i += 2) {
      final first = properties[i];
      final second = (i + 1 < properties.length) ? properties[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildNearbyCard(
                  first,
                  vm.distanceToProperty(first),
                  l10n,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: second != null
                    ? _buildNearbyCard(
                        second,
                        vm.distanceToProperty(second),
                        l10n,
                        isDark,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Widget _buildLocationPrompt(AppLocalizations l10n, bool isDark, PropertyListViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off_rounded,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.enableLocationForNearby,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: vm.locationLoading ? null : vm.fetchUserLocation,
            icon: vm.locationLoading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(l10n.useCurrentLocation),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNearby(AppLocalizations l10n, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.location_searching_rounded,
              size: 40,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            l10n.noNearbyProperties,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyCard(
    PropertyModel property,
    double? distance,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => widget.onNavigate?.call('propertyDetail', property: property),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: property.imageUrl != null
                    ? NetworkImageWithAuth(
                        imageUrl: property.imageUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: () => _imagePlaceholder(isDark),
                        errorBuilder: () => _imagePlaceholder(isDark),
                      )
                    : _imagePlaceholder(isDark),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Distance
                    if (distance != null)
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} ${l10n.kmAway}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right_rounded,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      width: 90,
      height: 90,
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Icon(Icons.home_outlined,
          size: 28,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
    );
  }
}
