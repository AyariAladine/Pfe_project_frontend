import 'package:flutter/material.dart';
import 'package:pfe_project/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/property_model.dart';
import '../../services/favorites_service.dart';
import '../../viewmodels/property/property_list_viewmodel.dart';
import '../widgets/network_image_with_auth.dart';
import 'create_property_wizard_view.dart';
import 'property_map_view.dart';

/// Standalone Property List View with its own Scaffold
class PropertyListView extends StatefulWidget {
  const PropertyListView({super.key});

  @override
  State<PropertyListView> createState() => _PropertyListViewState();
}

class _PropertyListViewState extends State<PropertyListView> {
  late PropertyListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PropertyListViewModel();
    _viewModel.loadProperties();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const _PropertyListViewContent(),
    );
  }
}

class _PropertyListViewContent extends StatelessWidget {
  const _PropertyListViewContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.myProperties,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              context.read<PropertyListViewModel>().refresh();
            },
          ),
        ],
      ),
      body: const _PropertyListBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.addProperty,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) async {
    final result = await Navigator.push<PropertyModel>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePropertyWizardView()),
    );

    if (result != null && context.mounted) {
      context.read<PropertyListViewModel>().addProperty(result);
    }
  }
}

/// Property List Content that can be embedded in a shell (no Scaffold)
class PropertyListContent extends StatefulWidget {
  final void Function(PropertyModel property)? onPropertySelected;
  final void Function(PropertyModel property)? onEditProperty;

  const PropertyListContent({super.key, this.onPropertySelected, this.onEditProperty});

  @override
  State<PropertyListContent> createState() => _PropertyListContentState();
}

class _PropertyListContentState extends State<PropertyListContent> {
  late PropertyListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PropertyListViewModel();
    _viewModel.loadProperties();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: _PropertyListBody(
        onPropertySelected: widget.onPropertySelected,
        onEditProperty: widget.onEditProperty,
      ),
    );
  }
}

class _PropertyListBody extends StatefulWidget {
  final void Function(PropertyModel property)? onPropertySelected;
  final void Function(PropertyModel property)? onEditProperty;

  const _PropertyListBody({this.onPropertySelected, this.onEditProperty});

  @override
  State<_PropertyListBody> createState() => _PropertyListBodyState();
}

class _PropertyListBodyState extends State<_PropertyListBody> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFavoritesOnly = false;
  bool _showMapView = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PropertyListViewModel>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Positioned.fill(
          child: Consumer<PropertyListViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.error != null) {
                  return _buildErrorState(context, viewModel, isDark);
                }

                if (!viewModel.hasProperties && !viewModel.hasAvailableProperties) {
                  return _buildEmptyState(context, isDark);
                }

                // ── Offline / stale-cache banner ──
                final offlineBanner = viewModel.isServingCachedData
                    ? Material(
                        color: Colors.transparent,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: Colors.amber.shade700,
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_off_rounded,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Viewing cached data — connect to refresh',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    viewModel.loadProperties(),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Retry',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink();

                // ── Map View ──
                if (_showMapView) {
                  return Column(
                    children: [
                      offlineBanner,
                      // Map toggle bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.map_rounded,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              l10n.mapView,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.list_rounded),
                              color: AppColors.primary,
                              tooltip: l10n.listView,
                              onPressed: () => setState(() => _showMapView = false),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PropertyMapView(
                          onPropertySelected: widget.onPropertySelected,
                        ),
                      ),
                    ],
                  );
                }

                // ── List View ──

                return Column(
                  children: [
                    offlineBanner,
                    Expanded(child: RefreshIndicator(
                  onRefresh: viewModel.refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // ── My Properties (horizontal) ──
                      SliverToBoxAdapter(
                        child: _buildMyPropertiesSection(
                            context, viewModel, l10n, isDark),
                      ),

                      // ── Search & Filter Bar ──
                      SliverToBoxAdapter(
                        child: _buildSearchAndFilters(context, viewModel, l10n, isDark),
                      ),

                      // ── All / Favorites tabs ──
                      SliverToBoxAdapter(
                        child: _buildTabBar(context, viewModel, l10n, isDark),
                      ),

                      // ── Available Properties header ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            children: [
                              Icon(_showFavoritesOnly ? Icons.star_rounded : Icons.explore_rounded,
                                  color: _showFavoritesOnly ? AppColors.warning : AppColors.primary, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                _showFavoritesOnly ? l10n.favorites : l10n.availableProperties,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_getDisplayProperties(viewModel, context).length}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Map toggle
                              GestureDetector(
                                onTap: () => setState(() => _showMapView = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.map_rounded,
                                          size: 16, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.mapView,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Available Properties (vertical list) ──
                      ..._buildPropertyList(viewModel, l10n, isDark),
                    ],
                  ),
                )),
                  ],
                );
              },
            ),
          ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _navigateToCreate(context),
                backgroundColor: AppColors.primary,
                elevation: 4,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Property',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
    );
  }

  List<PropertyModel> _getDisplayProperties(PropertyListViewModel viewModel, BuildContext ctx) {
    if (!_showFavoritesOnly) return viewModel.availableProperties;
    final favService = ctx.read<FavoritesService>();
    return viewModel.availableProperties
        .where((p) => p.id != null && favService.isFavorite(p.id!))
        .toList();
  }

  Widget _buildTabBar(
    BuildContext context,
    PropertyListViewModel viewModel,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final favService = context.watch<FavoritesService>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          _buildTabChip(
            label: l10n.all,
            isSelected: !_showFavoritesOnly,
            isDark: isDark,
            onTap: () => setState(() => _showFavoritesOnly = false),
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: '${l10n.favorites} (${favService.count})',
            isSelected: _showFavoritesOnly,
            isDark: isDark,
            icon: Icons.star_rounded,
            onTap: () => setState(() => _showFavoritesOnly = true),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPropertyList(
    PropertyListViewModel viewModel,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final properties = _getDisplayProperties(viewModel, context);

    if (properties.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    _showFavoritesOnly
                        ? Icons.star_rounded
                        : Icons.explore_rounded,
                    size: 48,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _showFavoritesOnly
                        ? l10n.noFavorites
                        : (viewModel.searchQuery.isNotEmpty ||
                                viewModel.filterType != null
                            ? l10n.noPropertiesMatch
                            : l10n.noAvailableProperties),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showFavoritesOnly
                        ? l10n.noFavoritesHint
                        : (viewModel.searchQuery.isNotEmpty ||
                                viewModel.filterType != null
                            ? l10n.adjustFilters
                            : ''),
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
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final property = properties[index];
              final distance = viewModel.distanceToProperty(property);
              final isOwned = viewModel.myProperties.any((p) => p.id == property.id);
              return _AvailablePropertyCard(
                property: property,
                isDark: isDark,
                distanceKm: distance,
                isOwned: isOwned,
                onTap: () => widget.onPropertySelected?.call(property),
              );
            },
            childCount: properties.length,
          ),
        ),
      ),
      // Loading more indicator
      if (!_showFavoritesOnly && viewModel.hasMoreItems)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.loadingMore,
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
            ),
          ),
        )
      else
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    PropertyListViewModel viewModel,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: viewModel.setSearchQuery,
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: l10n.searchProperties,
              hintStyle: TextStyle(
                color: isDark ? AppColors.textHintDark : AppColors.textHint,
              ),
              prefixIcon: Icon(Icons.search_rounded,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              suffixIcon: viewModel.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips row
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Type filters
                _buildFilterChip(
                  label: l10n.allTypes,
                  isSelected: viewModel.filterType == null,
                  isDark: isDark,
                  onTap: () => viewModel.setFilterType(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.forRent,
                  isSelected: viewModel.filterType == PropertyType.rent,
                  isDark: isDark,
                  onTap: () => viewModel.setFilterType(PropertyType.rent),
                  icon: Icons.vpn_key_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.forSale,
                  isSelected: viewModel.filterType == PropertyType.sale,
                  isDark: isDark,
                  onTap: () => viewModel.setFilterType(PropertyType.sale),
                  icon: Icons.sell_rounded,
                ),
                const SizedBox(width: 16),
                // Sort toggle
                Container(
                  height: 34,
                  width: 1,
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                const SizedBox(width: 16),
                _buildFilterChip(
                  label: l10n.sortByNewest,
                  isSelected: viewModel.sortMode == PropertySortMode.newest,
                  isDark: isDark,
                  onTap: () => viewModel.setSortMode(PropertySortMode.newest),
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.sortByNearest,
                  isSelected: viewModel.sortMode == PropertySortMode.nearest,
                  isDark: isDark,
                  onTap: () => viewModel.setSortMode(PropertySortMode.nearest),
                  icon: Icons.near_me_rounded,
                  isLoading: viewModel.locationLoading &&
                      viewModel.sortMode == PropertySortMode.nearest,
                ),
                const SizedBox(width: 16),
                Container(
                  height: 34,
                  width: 1,
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                const SizedBox(width: 16),
                // Advanced filters button with badge
                GestureDetector(
                  onTap: () => _showAdvancedFilters(context, viewModel, l10n, isDark),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: viewModel.hasActiveAdvancedFilters
                          ? AppColors.primary
                          : (isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: viewModel.hasActiveAdvancedFilters
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : AppColors.border),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 15,
                          color: viewModel.hasActiveAdvancedFilters
                              ? Colors.white
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: viewModel.hasActiveAdvancedFilters
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: viewModel.hasActiveAdvancedFilters
                                ? Colors.white
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                          ),
                        ),
                      ],
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

  void _showAdvancedFilters(
    BuildContext context,
    PropertyListViewModel viewModel,
    AppLocalizations l10n,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdvancedFilterSheet(
        viewModel: viewModel,
        isDark: isDark,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    IconData? icon,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon,
                  size: 15,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryLight : AppColors.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 50,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noPropertiesYet,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addFirstProperty,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreate(context),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addProperty),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    PropertyListViewModel viewModel,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: viewModel.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── My Properties horizontal section ─────────────────────────────

  Widget _buildMyPropertiesSection(
    BuildContext context,
    PropertyListViewModel viewModel,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Icon(Icons.home_work_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.myProperties,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${viewModel.myProperties.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal list
        if (viewModel.myProperties.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: Text(
                l10n.noOwnedProperties,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: viewModel.myProperties.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final property = viewModel.myProperties[index];
                return _OwnedPropertyCard(
                  property: property,
                  isDark: isDark,
                  onTap: () => widget.onPropertySelected?.call(property),
                  onEdit: () => widget.onEditProperty?.call(property),
                  onDelete: () =>
                      _confirmDelete(context, viewModel, property),
                );
              },
            ),
          ),

        const SizedBox(height: 8),
        const Divider(height: 1),
      ],
    );
  }

  void _navigateToCreate(BuildContext context) async {
    final result = await Navigator.push<PropertyModel>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePropertyWizardView()),
    );

    if (result != null && context.mounted) {
      context.read<PropertyListViewModel>().addProperty(result);
    }
  }



  void _confirmDelete(
    BuildContext context,
    PropertyListViewModel viewModel,
    PropertyModel property,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.error,
                    size: 32,
                  ),
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
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          if (property.id == null) return;
                          final success =
                              await viewModel.deleteProperty(property.id!);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.propertyDeleted),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(AppLocalizations.of(context)!.delete),
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

// ═══════════════════════════════════════════════════════════════════════
// Compact card for horizontal "My Properties" list
// ═══════════════════════════════════════════════════════════════════════

class _OwnedPropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OwnedPropertyCard({
    required this.property,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(property.propertyStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 110,
                child: property.imageUrl != null
                    ? NetworkImageWithAuth(
                        imageUrl: property.imageUrl!,
                        width: 200,
                        height: 110,
                        fit: BoxFit.cover,
                        placeholder: () => _placeholder(),
                        errorBuilder: () => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type + Status badges
                  Row(
                    children: [
                      _badge(
                        property.propertyType == PropertyType.sale
                            ? l10n.forSale
                            : l10n.forRent,
                        property.propertyType == PropertyType.sale
                            ? AppColors.accent
                            : AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      _badge(
                        property.propertyStatus.displayName,
                        statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Address
                  Text(
                    property.propertyAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _iconBtn(Icons.edit_outlined, AppColors.info, onEdit),
                      const SizedBox(width: 4),
                      _iconBtn(
                          Icons.delete_outline, AppColors.error, onDelete),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 110,
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Center(
        child: Icon(Icons.home_outlined,
            size: 32,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Color _statusColor(PropertyStatus s) {
    switch (s) {
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
}

// ═══════════════════════════════════════════════════════════════════════
// Card for vertical "Available Properties" list
// ═══════════════════════════════════════════════════════════════════════

class _AvailablePropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isDark;
  final VoidCallback onTap;
  final double? distanceKm;
  final bool isOwned;

  const _AvailablePropertyCard({
    required this.property,
    required this.isDark,
    required this.onTap,
    this.distanceKm,
    this.isOwned = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                width: 120,
                height: 120,
                child: property.imageUrl != null
                    ? NetworkImageWithAuth(
                        imageUrl: property.imageUrl!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: () => _placeholder(),
                        errorBuilder: () => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge row
                    Row(
                      children: [
                        _badge(
                          property.propertyType == PropertyType.sale
                              ? l10n.forSale
                              : l10n.forRent,
                          property.propertyType == PropertyType.sale
                              ? AppColors.accent
                              : AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        _badge(
                          property.propertyStatus.displayName,
                          AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Address
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Owner info if populated
                    if (property.owner != null &&
                        property.owner!['name'] != null)
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${property.owner!['name']} ${property.owner!['lastName'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (property.owner!['isVerified'] == true)
                            const Tooltip(
                              message: 'Identity Verified',
                              child: Icon(Icons.verified_rounded,
                                  size: 14, color: Colors.teal),
                            ),
                        ],
                      ),
                    // Distance badge
                    if (distanceKm != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.near_me_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${distanceKm!.toStringAsFixed(1)} ${l10n.kmAway}',
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

            // Favorite + Chevron
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Favorite button (hidden for owned properties)
                if (!isOwned)
                  Consumer<FavoritesService>(
                    builder: (context, favService, _) {
                    final isFav = property.id != null && favService.isFavorite(property.id!);
                    return GestureDetector(
                      onTap: () {
                        if (property.id != null) {
                          favService.toggleFavorite(property.id!);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, top: 12),
                        child: Icon(
                          isFav ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isFav ? AppColors.warning : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
                // Chevron
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 12),
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
      width: 120,
      height: 120,
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Center(
        child: Icon(Icons.home_outlined,
            size: 28,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Advanced filter bottom sheet
// ═══════════════════════════════════════════════════════════════════════

class _AdvancedFilterSheet extends StatefulWidget {
  final PropertyListViewModel viewModel;
  final bool isDark;

  const _AdvancedFilterSheet({required this.viewModel, required this.isDark});

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet>
    with SingleTickerProviderStateMixin {
  late PropertyStatus? _status;
  late double? _maxDist;
  late bool _verifiedOnly;
  late bool _photosOnly;
  late final AnimationController _enterAnim;

  @override
  void initState() {
    super.initState();
    final vm = widget.viewModel;
    _status = vm.filterStatus;
    _maxDist = vm.maxDistanceKm;
    _verifiedOnly = vm.verifiedOwnerOnly;
    _photosOnly = vm.hasPhotosOnly;
    _enterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _enterAnim.dispose();
    super.dispose();
  }

  void _apply() {
    final vm = widget.viewModel;
    vm.setFilterStatus(_status);
    vm.setMaxDistanceKm(_maxDist);
    vm.setVerifiedOwnerOnly(_verifiedOnly);
    vm.setHasPhotosOnly(_photosOnly);
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _status = null;
      _maxDist = null;
      _verifiedOnly = false;
      _photosOnly = false;
    });
  }

  Widget _stagger(double start, Widget child) {
    final anim = CurvedAnimation(
      parent: _enterAnim,
      curve: Interval(start, (start + 0.45).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - anim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final vm = widget.viewModel;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            _stagger(0.0, Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
            const SizedBox(height: 16),

            // Header
            _stagger(0.05, Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Advanced Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                const Spacer(),
                TextButton(
                  onPressed: _clear,
                  child: const Text('Clear all', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            )),
            const SizedBox(height: 20),

            // Status section
            _stagger(0.1, Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 3, height: 16, decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    )),
                    const SizedBox(width: 8),
                    Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _statusChip(null, 'Any Status', isDark, textPrimary),
                    _statusChip(PropertyStatus.available, 'Available', isDark, textPrimary),
                    _statusChip(PropertyStatus.rented, 'Rented', isDark, textPrimary),
                    _statusChip(PropertyStatus.sold, 'Sold', isDark, textPrimary),
                    _statusChip(PropertyStatus.pending, 'Pending', isDark, textPrimary),
                  ],
                ),
              ],
            )),
            const SizedBox(height: 20),

            // Distance section (only when location known)
            if (vm.hasUserLocation)
              _stagger(0.2, Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 3, height: 16, decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                      )),
                      const SizedBox(width: 8),
                      Text('Max Distance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _maxDist != null ? '${_maxDist!.round()} km' : 'Any',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxDist ?? 50,
                    min: 1, max: 50, divisions: 49,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primary.withValues(alpha: 0.2),
                    onChanged: (v) => setState(() => _maxDist = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 km', style: TextStyle(fontSize: 11, color: textSecondary)),
                      TextButton(
                        onPressed: () => setState(() => _maxDist = null),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('No limit', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                      ),
                      Text('50 km', style: TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              )),

            // Toggle: verified owners only
            _stagger(0.3, _buildToggle(
              label: 'Verified owners only',
              subtitle: 'Show properties from identity-verified owners',
              icon: Icons.verified_rounded,
              iconColor: Colors.teal,
              value: _verifiedOnly,
              isDark: isDark,
              onChanged: (v) => setState(() => _verifiedOnly = v),
            )),
            const SizedBox(height: 8),

            // Toggle: has photos only
            _stagger(0.4, _buildToggle(
              label: 'Has photos only',
              subtitle: 'Hide listings with no images',
              icon: Icons.photo_rounded,
              iconColor: AppColors.info,
              value: _photosOnly,
              isDark: isDark,
              onChanged: (v) => setState(() => _photosOnly = v),
            )),
            const SizedBox(height: 24),

            // Apply button
            _stagger(0.5, SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Apply Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(PropertyStatus? status, String label, bool isDark, Color textColor) {
    final isSelected = _status == status;
    return GestureDetector(
      onTap: () => setState(() => _status = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
