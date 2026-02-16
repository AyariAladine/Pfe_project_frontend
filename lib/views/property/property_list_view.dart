import 'package:flutter/material.dart';
import 'package:pfe_project/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/property_model.dart';
import '../../viewmodels/property/property_list_viewmodel.dart';
import '../widgets/network_image_with_auth.dart';
import 'create_property_wizard_view.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Properties',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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

class _PropertyListBody extends StatelessWidget {
  final void Function(PropertyModel property)? onPropertySelected;
  final void Function(PropertyModel property)? onEditProperty;

  const _PropertyListBody({this.onPropertySelected, this.onEditProperty});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

                if (!viewModel.hasProperties) {
                  return _buildEmptyState(context, isDark);
                }

                return RefreshIndicator(
                  onRefresh: viewModel.refresh,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 100),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final rentalProperties = viewModel.properties
                            .where((p) => p.propertyType == PropertyType.rent)
                            .toList();
                        final saleProperties = viewModel.properties
                            .where((p) => p.propertyType == PropertyType.sale)
                            .toList();

                        // Mobile layout - single column with all properties
                        if (constraints.maxWidth < 600) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: viewModel.properties.map((property) {
                              return _PropertyCard(
                                property: property,
                                isDark: isDark,
                                onTap: () => _navigateToDetail(context, viewModel, property),
                                onEdit: () => _navigateToEdit(context, viewModel, property),
                                onDelete: () => _confirmDelete(context, viewModel, property),
                              );
                            }).toList(),
                          );
                        }

                        // Desktop layout - two columns
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column - Rentals
                            Expanded(
                              child: _PropertyColumn(
                                title: AppLocalizations.of(context)!.forRent,
                                properties: rentalProperties,
                                isDark: isDark,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                onPropertyTap: (property) =>
                                    _navigateToDetail(context, viewModel, property),
                                onPropertyEdit: (property) =>
                                    _navigateToEdit(context, viewModel, property),
                                onPropertyDelete: (property) =>
                                    _confirmDelete(context, viewModel, property),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right column - Sales
                            Expanded(
                              child: _PropertyColumn(
                                title: AppLocalizations.of(context)!.forSale,
                                properties: saleProperties,
                                isDark: isDark,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                onPropertyTap: (property) =>
                                    _navigateToDetail(context, viewModel, property),
                                onPropertyEdit: (property) =>
                                    _navigateToEdit(context, viewModel, property),
                                onPropertyDelete: (property) =>
                                    _confirmDelete(context, viewModel, property),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
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

  Widget _buildEmptyState(BuildContext context, bool isDark) {
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
              'No Properties Yet',
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
              'Add your first property to get started\nmanaging your real estate portfolio',
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

  void _navigateToCreate(BuildContext context) async {
    final result = await Navigator.push<PropertyModel>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePropertyWizardView()),
    );

    if (result != null && context.mounted) {
      context.read<PropertyListViewModel>().addProperty(result);
    }
  }

  void _navigateToDetail(
    BuildContext context,
    PropertyListViewModel viewModel,
    PropertyModel property,
  ) {
    onPropertySelected?.call(property);
  }

  void _navigateToEdit(
    BuildContext context,
    PropertyListViewModel viewModel,
    PropertyModel property,
  ) {
    onEditProperty?.call(property);
  }

  void _confirmDelete(
    BuildContext context,
    PropertyListViewModel viewModel,
    PropertyModel property,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  'Delete Property?',
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
                  'Are you sure you want to delete "${property.propertyAddress}"? This action cannot be undone.',
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
                        child: const Text('Cancel'),
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
                                content: const Text('Property deleted'),
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

class _PropertyColumn extends StatelessWidget {
  final String title;
  final List<PropertyModel> properties;
  final bool isDark;
  final Color color;
  final void Function(PropertyModel) onPropertyTap;
  final void Function(PropertyModel) onPropertyEdit;
  final void Function(PropertyModel) onPropertyDelete;

  const _PropertyColumn({
    required this.title,
    required this.properties,
    required this.isDark,
    required this.color,
    required this.onPropertyTap,
    required this.onPropertyEdit,
    required this.onPropertyDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_outlined, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${properties.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Properties list
        if (properties.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 48,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No properties',
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
          )
        else
          ...properties.map((property) => _PropertyCard(
                property: property,
                isDark: isDark,
                onTap: () => onPropertyTap(property),
                onEdit: () => onPropertyEdit(property),
                onDelete: () => onPropertyDelete(property),
              )),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PropertyCard({
    required this.property,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardBackgroundDark
              : AppColors.cardBackground,
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
            // Property Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 120,
                height: 140,
                child: property.imageUrl != null
                    ? NetworkImageWithAuth(
                        imageUrl: property.imageUrl!,
                        width: 120,
                        height: 140,
                        fit: BoxFit.cover,
                        placeholder: () => _buildImagePlaceholder(),
                        errorBuilder: () => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),

            // Property Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badges row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildSmallBadge(
                          property.propertyType == PropertyType.sale
                              ? AppLocalizations.of(context)!.forSale
                              : AppLocalizations.of(context)!.forRent,
                          property.propertyType == PropertyType.sale
                              ? AppColors.accent
                              : AppColors.secondary,
                        ),
                        _buildSmallBadge(
                          property.propertyStatus.displayName,
                          _getStatusColor(property.propertyStatus),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Property Address
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.propertyAddress,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildIconButton(
                          icon: Icons.visibility_outlined,
                          color: AppColors.primary,
                          onTap: onTap,
                          tooltip: AppLocalizations.of(context)!.view,
                        ),
                        const SizedBox(width: 4),
                        _buildIconButton(
                          icon: Icons.edit_outlined,
                          color: AppColors.info,
                          onTap: onEdit,
                          tooltip: AppLocalizations.of(context)!.edit,
                        ),
                        const SizedBox(width: 4),
                        _buildIconButton(
                          icon: Icons.delete_outline,
                          color: AppColors.error,
                          onTap: onDelete,
                          tooltip: AppLocalizations.of(context)!.delete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 120,
      height: 140,
      color: (isDark ? AppColors.surfaceDark : AppColors.surface),
      child: Center(
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.home_outlined,
            size: 28,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

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
}
