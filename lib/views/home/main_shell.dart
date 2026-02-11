import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../widgets/language_selector.dart';
import '../auth/login/login_view.dart';
import '../onboarding/onboarding_view.dart';
import '../property/property_list_view.dart';
import '../property/create_property_wizard_view.dart';
import 'home_content.dart';

/// Navigation items enum
enum NavItem {
  home,
  properties,
  addProperty,
  contracts,
  cases,
  aiAssistant,
  settings,
}

/// Main shell with persistent app bar and sidebar (web) / drawer (mobile)
class MainShell extends StatefulWidget {
  final NavItem initialPage;

  const MainShell({super.key, this.initialPage = NavItem.home});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late NavItem _currentPage;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  int _propertyListRefreshKey = 0; // Key to force property list refresh

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
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
    if (_animController.isCompleted ||
        (_animController.isAnimating && _animController.value > 0.5)) {
      _animController.reverse();
    } else {
      _animController.forward();
    }
  }

  void _navigateTo(NavItem item) {
    setState(() {
      _currentPage = item;
    });
    // On narrow screens / mobile close the drawer; on wide web the sidebar stays open
    final isWideScreen = kIsWeb && MediaQuery.of(context).size.width >= 768;
    if (!isWideScreen) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = kIsWeb && MediaQuery.of(context).size.width >= 768;

    if (isWideScreen) {
      return _buildWebLayout(l10n, isDark);
    } else {
      return _buildMobileLayout(l10n, isDark);
    }
  }

  // ─── Web layout with sliding sidebar ───

  Widget _buildWebLayout(AppLocalizations l10n, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle(l10n)),
        centerTitle: true,
        leading: IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animController,
            color: isDark ? AppColors.textPrimaryDark : const Color.fromARGB(255, 255, 255, 255),
          ),
          onPressed: _toggleSidebar,
        ),
        actions: [const LanguageSelector(), const SizedBox(width: 16)],
      ),
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          const sidebarWidth = 280.0;
          final sidebarCurrentWidth = sidebarWidth * _slideAnimation.value;
          return Row(
            children: [
              // Sidebar – clips to animated width
              ClipRect(
                child: SizedBox(
                  width: sidebarCurrentWidth,
                  child: OverflowBox(
                    alignment: AlignmentDirectional.centerStart,
                    minWidth: sidebarWidth,
                    maxWidth: sidebarWidth,
                    child: _buildSidebar(l10n, isDark),
                  ),
                ),
              ),
              // Main content
              Expanded(child: _buildBody()),
            ],
          );
        },
      ),
    );
  }

  // ─── Mobile layout with traditional drawer ───

  Widget _buildMobileLayout(AppLocalizations l10n, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(l10n)),
        centerTitle: true,
        actions: [const LanguageSelector(), const SizedBox(width: 16)],
      ),
      drawer: _buildDrawer(l10n, isDark),
      body: _buildBody(),
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (_currentPage) {
      case NavItem.home:
        return l10n.appName;
      case NavItem.properties:
        return l10n.properties;
      case NavItem.addProperty:
        return l10n.addProperty;
      case NavItem.contracts:
        return l10n.contracts;
      case NavItem.cases:
        return l10n.cases;
      case NavItem.aiAssistant:
        return l10n.aiAssistant;
      case NavItem.settings:
        return l10n.settings;
    }
  }

  Widget _buildBody() {
    switch (_currentPage) {
      case NavItem.home:
        return const HomeContent();
      case NavItem.properties:
        // Use a key that changes to force rebuild and refresh data
        return PropertyListContent(key: ValueKey(_propertyListRefreshKey));
      case NavItem.addProperty:
        return CreatePropertyWizardContent(
          onPropertyCreated: (property) {
            // Navigate back to properties list after creation and refresh
            setState(() {
              _currentPage = NavItem.properties;
              _propertyListRefreshKey++; // Increment to force refresh
            });
          },
        );
      case NavItem.contracts:
        return _buildPlaceholder('Contracts', Icons.description_rounded);
      case NavItem.cases:
        return _buildPlaceholder('Cases', Icons.gavel_rounded);
      case NavItem.aiAssistant:
        return _buildPlaceholder('AI Assistant', Icons.smart_toy_rounded);
      case NavItem.settings:
        return _buildPlaceholder('Settings', Icons.settings_rounded);
    }
  }

  Widget _buildPlaceholder(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              icon,
              size: 50,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(AppLocalizations l10n, bool isDark) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        return Drawer(
          child: Column(
            children: [
              const SizedBox(height: 50),
              _buildDrawerItem(
                icon: Icons.home_rounded,
                title: l10n.home,
                item: NavItem.home,
              ),
              _buildDrawerItem(
                icon: Icons.apartment_rounded,
                title: l10n.properties,
                item: NavItem.properties,
              ),
          
              _buildDrawerItem(
                icon: Icons.description_rounded,
                title: l10n.contracts,
                item: NavItem.contracts,
              ),
              _buildDrawerItem(
                icon: Icons.gavel_rounded,
                title: l10n.cases,
                item: NavItem.cases,
              ),
              _buildDrawerItem(
                icon: Icons.smart_toy_rounded,
                title: l10n.aiAssistant,
                item: NavItem.aiAssistant,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.verified_user_rounded),
                title: Text(l10n.verifyIdentity),
                subtitle: Text(
                  l10n.verifyIdentitySubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingView()),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.settings_rounded,
                title: l10n.settings,
                item: NavItem.settings,
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required NavItem item,
  }) {
    final isSelected = _currentPage == item;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: isSelected,
      onTap: () => _navigateTo(item),
    );
  }

  // ─── Web sidebar ───

  Widget _buildSidebar(AppLocalizations l10n, bool isDark) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        return Material(
          elevation: 8,
          color: isDark ? AppColors.surfaceDark : Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Nav items
              _buildSidebarItem(
                icon: Icons.home_rounded,
                title: l10n.home,
                item: NavItem.home,
                isDark: isDark,
              ),
              _buildSidebarItem(
                icon: Icons.apartment_rounded,
                title: l10n.properties,
                item: NavItem.properties,
                isDark: isDark,
              ),
              _buildSidebarItem(
                icon: Icons.description_rounded,
                title: l10n.contracts,
                item: NavItem.contracts,
                isDark: isDark,
              ),
              _buildSidebarItem(
                icon: Icons.gavel_rounded,
                title: l10n.cases,
                item: NavItem.cases,
                isDark: isDark,
              ),
              _buildSidebarItem(
                icon: Icons.smart_toy_rounded,
                title: l10n.aiAssistant,
                item: NavItem.aiAssistant,
                isDark: isDark,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),

              _buildSidebarItem(
                icon: Icons.verified_user_rounded,
                title: l10n.verifyIdentity,
                item: null,
                isDark: isDark,
                onTap: () {
                  _animController.reverse();
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
                item: NavItem.settings,
                isDark: isDark,
              ),

              const Spacer(),

              // Logout
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            color: AppColors.error, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          l10n.logout,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required NavItem? item,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final isSelected = item != null && _currentPage == item;
    final selectedColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final defaultColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? (item != null ? () => _navigateTo(item) : null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? selectedColor : defaultColor,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? selectedColor
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
