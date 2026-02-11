import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../widgets/language_selector.dart';
import '../widgets/network_image_with_auth.dart';
import '../auth/login/login_view.dart';
import '../onboarding/onboarding_view.dart';
import '../property/property_list_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    if (_animController.isCompleted || _animController.isAnimating && _animController.value > 0.5) {
      _animController.reverse();
    } else {
      _animController.forward();
    }
  }

  bool get _useWebSidebar => kIsWeb;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_useWebSidebar) {
      return _buildWebLayout(context, l10n, isDark);
    } else {
      return _buildMobileLayout(context, l10n, isDark);
    }
  }

  Widget _buildWebLayout(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(l10n.appName),
        centerTitle: true,
        leading: IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animController,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: _toggleSidebar,
        ),
        actions: [
          const LanguageSelector(),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          _buildBody(context, l10n, isDark),

          // Overlay — always in tree, animated opacity + hit test
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              if (_slideAnimation.value == 0.0) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: Colors.black
                      .withValues(alpha: 0.3 * _slideAnimation.value),
                ),
              );
            },
          ),

          // Sidebar — always in tree, animated position
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              const sidebarWidth = 280.0;
              return Positioned(
                left: -sidebarWidth + (sidebarWidth * _slideAnimation.value),
                top: 0,
                bottom: 0,
                width: sidebarWidth,
                child: child!,
              );
            },
            child: _buildSidebar(context, l10n, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        centerTitle: true,
        actions: [
          const LanguageSelector(),
          const SizedBox(width: 16),
        ],
      ),
      drawer: _buildDrawer(context, l10n, isDark),
      body: _buildBody(context, l10n, isDark),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        final user = authVM.currentUser;
        return Material(
          elevation: 8,
          child: Container(
            width: 280,
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            child: Column(
              children: [
                // User header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: const BoxDecoration(color: AppColors.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: user?.profileImageUrl != null
                            ? ClipOval(
                                child: NetworkImageWithAuth(
                                  imageUrl: user!.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: () => const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.fullName ?? l10n.welcomeBack,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                _buildSidebarItem(
                  icon: Icons.home_rounded,
                  title: l10n.home,
                  isSelected: true,
                  onTap: _toggleSidebar,
                ),
                _buildSidebarItem(
                  icon: Icons.apartment_rounded,
                  title: l10n.properties,
                  onTap: () {
                    _toggleSidebar();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PropertyListView()),
                    );
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.description_rounded,
                  title: l10n.contracts,
                  onTap: _toggleSidebar,
                ),
                _buildSidebarItem(
                  icon: Icons.gavel_rounded,
                  title: l10n.cases,
                  onTap: _toggleSidebar,
                ),
                _buildSidebarItem(
                  icon: Icons.smart_toy_rounded,
                  title: l10n.aiAssistant,
                  onTap: _toggleSidebar,
                ),

                const Divider(height: 24, indent: 16, endIndent: 16),

                _buildSidebarItem(
                  icon: Icons.verified_user_rounded,
                  title: l10n.verifyIdentity,
                  onTap: () {
                    _toggleSidebar();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OnboardingView()),
                    );
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.settings_rounded,
                  title: l10n.settings,
                  onTap: _toggleSidebar,
                ),

                const Spacer(),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 22,
                    ),
                    title: Text(
                      l10n.logout,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () async {
                      await authVM.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginView()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          size: 22,
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary),
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        dense: true,
        onTap: onTap,
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        final user = authVM.currentUser;
        return Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: AppColors.primary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: user?.profileImageUrl != null
                          ? ClipOval(
                              child: NetworkImageWithAuth(
                                imageUrl: user!.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: () => const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? l10n.welcomeBack,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_rounded),
                title: Text(l10n.home),
                selected: true,
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.apartment_rounded),
                title: Text(l10n.properties),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PropertyListView()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_rounded),
                title: Text(l10n.contracts),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.gavel_rounded),
                title: Text(l10n.cases),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.smart_toy_rounded),
                title: Text(l10n.aiAssistant),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.verified_user_rounded),
                title: Text(l10n.verifyIdentity),
                subtitle: Text(
                  l10n.translate('verifyIdentitySubtitle'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OnboardingView()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: Text(l10n.settings),
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  l10n.logout,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () async {
                  await authVM.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginView()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        final maxContentWidth = isWideScreen ? 600.0 : constraints.maxWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
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
                        Text(
                          l10n.welcomeToAqari,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.managePropertiesEasily,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    l10n.quickActions,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _buildQuickActionCard(
                        context,
                        icon: Icons.add_home_rounded,
                        title: l10n.addProperty,
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                        isDark: isDark,
                        onTap: () {},
                      ),
                      _buildQuickActionCard(
                        context,
                        icon: Icons.description_rounded,
                        title: l10n.newContract,
                        color: AppColors.secondary,
                        isDark: isDark,
                        onTap: () {},
                      ),
                      _buildQuickActionCard(
                        context,
                        icon: Icons.document_scanner_rounded,
                        title: l10n.damageInspection,
                        color: AppColors.accent,
                        isDark: isDark,
                        onTap: () {},
                      ),
                      _buildQuickActionCard(
                        context,
                        icon: Icons.chat_rounded,
                        title: l10n.legalConsultation,
                        color: AppColors.info,
                        isDark: isDark,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    l10n.recentActivity,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(
                    context,
                    icon: Icons.notifications_rounded,
                    title: l10n.noRecentActivity,
                    subtitle: l10n.notificationsWillAppear,
                    time: '',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardBackgroundDark
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryLight : AppColors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (time.isNotEmpty)
            Text(time, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
