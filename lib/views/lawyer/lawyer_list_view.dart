import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/user_model.dart';
import '../../viewmodels/lawyer/lawyer_list_viewmodel.dart';
import '../widgets/network_image_with_auth.dart';

/// Embeddable lawyer list content (no Scaffold) for use inside MainShell
class LawyerListContent extends StatefulWidget {
  final void Function(UserModel lawyer)? onLawyerSelected;

  const LawyerListContent({super.key, this.onLawyerSelected});

  @override
  State<LawyerListContent> createState() => _LawyerListContentState();
}

class _LawyerListContentState extends State<LawyerListContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LawyerListViewModel>().loadLawyers();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<LawyerListViewModel>().loadMore();
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<LawyerListViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchBar(vm, l10n, isDark),
            ),

            // Sort chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSortChips(vm, l10n, isDark),
            ),

            // Results count
            if (!vm.isLoading && vm.errorMessage == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${vm.totalFilteredCount} ${l10n.lawyersFound}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _buildContent(vm, l10n, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(
      LawyerListViewModel vm, AppLocalizations l10n, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: vm.search,
        style: TextStyle(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchLawyers,
          hintStyle: TextStyle(
            color: isDark ? AppColors.textHintDark : AppColors.textHint,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          suffixIcon: vm.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    vm.clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSortChips(
      LawyerListViewModel vm, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          _buildChip(
            label: l10n.sortLawyersByName,
            icon: Icons.sort_by_alpha_rounded,
            isSelected: vm.sortMode == LawyerSortMode.name,
            isDark: isDark,
            onTap: () => vm.setSortMode(LawyerSortMode.name),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: l10n.sortLawyersByNearest,
            icon: Icons.near_me_rounded,
            isSelected: vm.sortMode == LawyerSortMode.nearest,
            isDark: isDark,
            isLoading: vm.locationLoading && vm.sortMode == LawyerSortMode.nearest,
            onTap: () => vm.setSortMode(LawyerSortMode.nearest),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            ] else ...[
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

  Widget _buildContent(
      LawyerListViewModel vm, AppLocalizations l10n, bool isDark) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return _buildErrorState(vm, l10n, isDark);
    }

    if (vm.lawyers.isEmpty) {
      return _buildEmptyState(vm, l10n, isDark);
    }

    return RefreshIndicator(
      onRefresh: vm.loadLawyers,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: vm.lawyers.length + (vm.hasMoreItems ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= vm.lawyers.length) {
            // Loading more indicator
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
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
            );
          }
          final lawyer = vm.lawyers[index];
          final distance = vm.distanceToLawyer(lawyer);
          return _buildLawyerCard(lawyer, l10n, isDark, distance: distance);
        },
      ),
    );
  }

  Widget _buildLawyerCard(
      UserModel lawyer, AppLocalizations l10n, bool isDark, {double? distance}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (widget.onLawyerSelected != null) {
              widget.onLawyerSelected!(lawyer);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(lawyer, isDark),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lawyer.fullName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (lawyer.isVerified == true) ...[
                            const SizedBox(width: 6),
                            const Tooltip(
                              message: 'Identity Verified',
                              child: Icon(Icons.verified_rounded,
                                  size: 16, color: Colors.teal),
                            ),
                          ],
                          if (lawyer.faceRegistered) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Face Registered',
                              child: Icon(Icons.face_retouching_natural_rounded,
                                  size: 16, color: AppColors.primary),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              lawyer.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (lawyer.phoneNumber.isNotEmpty &&
                          lawyer.phoneNumber != '00000000') ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lawyer.phoneNumber,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Location indicator + Distance + Arrow
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (distance != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me_rounded,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                '${distance.toStringAsFixed(1)} ${l10n.kmAway}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (lawyer.latitude != null && lawyer.longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: AppColors.success,
                        ),
                      ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
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

  Widget _buildAvatar(UserModel lawyer, bool isDark) {
    final initials =
        '${lawyer.name.isNotEmpty ? lawyer.name[0] : ''}${lawyer.lastName.isNotEmpty ? lawyer.lastName[0] : ''}'
            .toUpperCase();
    final hasImage = lawyer.profileImageUrl != null &&
        lawyer.profileImageUrl!.isNotEmpty;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: hasImage
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? NetworkImageWithAuth(
              imageUrl: ApiConstants.getLawyerPictureUrl(
                  lawyer.profileImageUrl),
              fit: BoxFit.cover,
              width: 56,
              height: 56,
              placeholder: () => _buildInitials(initials),
              errorBuilder: () => _buildInitials(initials),
            )
          : _buildInitials(initials),
    );
  }

  Widget _buildInitials(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      LawyerListViewModel vm, AppLocalizations l10n, bool isDark) {
    final isSearching = vm.searchQuery.isNotEmpty;
    return Center(
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
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.person_search_rounded,
              size: 50,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching
                ? l10n.noLawyersMatchSearch
                : l10n.noLawyersAvailable,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? l10n.tryDifferentSearch
                : l10n.noLawyersYet,
            style: TextStyle(
              fontSize: 14,
              color:
                  isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          if (isSearching) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                vm.clearSearch();
              },
              icon: const Icon(Icons.clear_rounded),
              label: Text(l10n.clear),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(
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
          ElevatedButton.icon(
            onPressed: vm.loadLawyers,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}
