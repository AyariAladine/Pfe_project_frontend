import 'package:flutter/foundation.dart' show kIsWeb, ValueListenable;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../widgets/language_selector.dart';
import '../widgets/network_image_with_auth.dart';
import '../auth/login/login_view.dart';
import '../onboarding/onboarding_view.dart';
import '../settings/settings_view.dart';
import '../property/property_list_view.dart';
import '../property/property_detail_view.dart';
import '../property/edit_property_view.dart';
import '../property/create_property_wizard_view.dart';
import '../property/my_applications_view.dart';
import '../property/incoming_applications_view.dart';
import '../property/application_detail_view.dart';
import '../lawyer/lawyer_list_view.dart';
import '../lawyer/lawyer_detail_view.dart';
import '../lawyer/lawyer_profile_view.dart';
import '../user/user_profile_view.dart';
import '../contract/contracts_list_view.dart';
import '../contract/lawyer_cases_view.dart';
import '../contract/lawyer_work_view.dart';
import '../rentals/active_rentals_view.dart';
import '../../viewmodels/rentals/rentals_viewmodel.dart';
import 'ai_assistant_view.dart';
import 'home_content.dart';

enum NavItem {
  home,
  properties,
  addProperty,
  myApplications,
  incomingApplications,
  lawyers,
  profile,
  work,
  contracts,
  cases,
  activeRentals,
  aiAssistant,
  settings,
}

class MainShell extends StatefulWidget {
  final NavItem initialPage;
  const MainShell({super.key, this.initialPage = NavItem.home});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  late NavItem _currentPage;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  int _propertyListRefreshKey = 0;
  PropertyModel? _selectedProperty;
  PropertyModel? _editingProperty;
  UserModel? _selectedLawyer;
  String? _selectedApplicationId;

  final ValueNotifier<int> _pendingApplicationCount = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _pendingApplicationCount.dispose();
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
      _selectedProperty = null;
      _editingProperty = null;
      _selectedLawyer = null;
      _selectedApplicationId = null;
    });
    final isWideScreen = kIsWeb && MediaQuery.of(context).size.width >= 768;
    if (!isWideScreen && Scaffold.maybeOf(context)?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = kIsWeb && MediaQuery.of(context).size.width >= 768;

    return isWideScreen
        ? _buildWebLayout(l10n, isDark)
        : _buildMobileLayout(l10n, isDark);
  }

  // ─── Web layout ──────────────────────────────────────────────────────────

  Widget _buildWebLayout(AppLocalizations l10n, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: _AppBarTitle(title: _getTitle(l10n)),
        centerTitle: true,
        leading: IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animController,
            color: Colors.white,
          ),
          onPressed: _toggleSidebar,
        ),
        actions: [const LanguageSelector(), const SizedBox(width: 16)],
      ),
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          const sidebarWidth = 280.0;
          return Row(
            children: [
              ClipRect(
                child: SizedBox(
                  width: sidebarWidth * _slideAnimation.value,
                  child: OverflowBox(
                    alignment: AlignmentDirectional.centerStart,
                    minWidth: sidebarWidth,
                    maxWidth: sidebarWidth,
                    child: _buildSidebar(l10n, isDark),
                  ),
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          );
        },
      ),
    );
  }

  // ─── Mobile layout ────────────────────────────────────────────────────────

  Widget _buildMobileLayout(AppLocalizations l10n, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: _AppBarTitle(title: _getTitle(l10n)),
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
        if (_editingProperty != null) return l10n.editProperty;
        if (_selectedProperty != null) return l10n.propertyDetails;
        return l10n.properties;
      case NavItem.addProperty:
        return l10n.addProperty;
      case NavItem.myApplications:
        if (_selectedApplicationId != null) return l10n.applicationDetail;
        return l10n.myApplications;
      case NavItem.incomingApplications:
        if (_selectedApplicationId != null) return l10n.applicationDetail;
        return l10n.incomingApplications;
      case NavItem.lawyers:
        if (_selectedLawyer != null) return l10n.lawyerDetails;
        return l10n.lawyers;
      case NavItem.profile:
        return l10n.myProfile;
      case NavItem.work:
        return l10n.work;
      case NavItem.contracts:
        return l10n.contracts;
      case NavItem.cases:
        return l10n.cases;
      case NavItem.activeRentals:
        return 'Active Rentals';
      case NavItem.aiAssistant:
        return l10n.aiAssistant;
      case NavItem.settings:
        return l10n.settings;
    }
  }

  Widget _buildBody() {
    switch (_currentPage) {
      case NavItem.home:
        return HomeContent(
          onNavigate: (destination, {property}) {
            switch (destination) {
              case 'addProperty':
                setState(() => _currentPage = NavItem.addProperty);
                break;
              case 'properties':
                setState(() => _currentPage = NavItem.properties);
                break;
              case 'aiAssistant':
                setState(() => _currentPage = NavItem.aiAssistant);
                break;
              case 'lawyers':
                setState(() => _currentPage = NavItem.lawyers);
                break;
              case 'propertyDetail':
                if (property != null) {
                  setState(() {
                    _currentPage = NavItem.properties;
                    _selectedProperty = property;
                  });
                }
                break;
            }
          },
        );
      case NavItem.properties:
        if (_editingProperty != null) {
          return EditPropertyContent(
            property: _editingProperty!,
            onBack: () => setState(() => _editingProperty = null),
            onPropertyUpdated: (updated) {
              setState(() {
                _editingProperty = null;
                _selectedProperty = updated;
                _propertyListRefreshKey++;
              });
            },
          );
        }
        if (_selectedProperty != null) {
          return PropertyDetailContent(
            property: _selectedProperty!,
            onBack: () => setState(() => _selectedProperty = null),
            onPropertyUpdated: (updated) {
              setState(() {
                _selectedProperty = updated;
                _propertyListRefreshKey++;
              });
            },
            onPropertyDeleted: (_) {
              setState(() {
                _selectedProperty = null;
                _propertyListRefreshKey++;
              });
            },
            onEditProperty: (property) => setState(() => _editingProperty = property),
          );
        }
        return PropertyListContent(
          key: ValueKey(_propertyListRefreshKey),
          onPropertySelected: (property) => setState(() => _selectedProperty = property),
          onEditProperty: (property) => setState(() => _editingProperty = property),
        );
      case NavItem.addProperty:
        return CreatePropertyWizardContent(
          onPropertyCreated: (_) {
            setState(() {
              _currentPage = NavItem.properties;
              _propertyListRefreshKey++;
            });
          },
        );
      case NavItem.lawyers:
        if (_selectedLawyer != null) {
          return LawyerDetailContent(
            lawyer: _selectedLawyer!,
            onBack: () => setState(() => _selectedLawyer = null),
          );
        }
        return LawyerListContent(
          onLawyerSelected: (lawyer) => setState(() => _selectedLawyer = lawyer),
        );
      case NavItem.profile:
        final authVM = context.read<AuthViewModel>();
        if (authVM.currentUser?.role == UserRole.lawyer) return const LawyerProfileContent();
        return const UserProfileContent();
      case NavItem.work:
        return const LawyerWorkContent();
      case NavItem.contracts:
        final contractAuthVM = context.read<AuthViewModel>();
        return ContractsListContent(
          userRole: contractAuthVM.currentUser?.role ?? UserRole.user,
        );
      case NavItem.cases:
        return const LawyerCasesContent();
      case NavItem.activeRentals:
        return ChangeNotifierProvider(
          create: (_) => RentalsViewModel(),
          child: const ActiveRentalsContent(),
        );
      case NavItem.myApplications:
        if (_selectedApplicationId != null) {
          return ApplicationDetailContent(
            applicationId: _selectedApplicationId!,
            onBack: () => setState(() => _selectedApplicationId = null),
          );
        }
        return MyApplicationsContent(
          onViewProperty: (_) => setState(() => _currentPage = NavItem.properties),
          onApplicationSelected: (id) => setState(() => _selectedApplicationId = id),
        );
      case NavItem.incomingApplications:
        if (_selectedApplicationId != null) {
          return ApplicationDetailContent(
            applicationId: _selectedApplicationId!,
            onBack: () => setState(() => _selectedApplicationId = null),
          );
        }
        return IncomingApplicationsContent(
          onApplicationSelected: (id) => setState(() => _selectedApplicationId = id),
          onPendingCountChanged: (count) => _pendingApplicationCount.value = count,
        );
      case NavItem.aiAssistant:
        return const AiAssistantContent();
      case NavItem.settings:
        return const SettingsContent();
    }
  }

  // ─── Drawer (mobile) ──────────────────────────────────────────────────────

  Widget _buildDrawer(AppLocalizations l10n, bool isDark) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        final user = authVM.currentUser;
        return Drawer(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          child: Column(
            children: [
              _buildUserHeader(user, l10n, isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(icon: Icons.home_rounded, title: l10n.home, item: NavItem.home),
                    _buildDrawerItem(icon: Icons.apartment_rounded, title: l10n.properties, item: NavItem.properties),
                    _buildDrawerItem(icon: Icons.send_rounded, title: l10n.myApplications, item: NavItem.myApplications),
                    _buildDrawerItem(
                      icon: Icons.inbox_rounded,
                      title: l10n.incomingApplications,
                      item: NavItem.incomingApplications,
                      badge: _pendingApplicationCount,
                    ),
                    _buildDrawerItem(icon: Icons.balance_rounded, title: l10n.lawyers, item: NavItem.lawyers),
                    _buildDrawerItem(icon: Icons.person_rounded, title: l10n.myProfile, item: NavItem.profile),
                    _buildDrawerSectionLabel(l10n.work, isDark),
                    _buildDrawerItem(icon: Icons.inbox_outlined, title: l10n.workRequests, item: NavItem.work),
                    _buildDrawerItem(icon: Icons.description_rounded, title: l10n.contracts, item: NavItem.contracts),
                    _buildDrawerItem(icon: Icons.home_work_rounded, title: 'Active Rentals', item: NavItem.activeRentals),
                    _buildDrawerItem(icon: Icons.smart_toy_rounded, title: l10n.aiAssistant, item: NavItem.aiAssistant),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        color: isDark ? AppColors.dividerDark : AppColors.divider,
                      ),
                    ),
                    _buildDrawerOnboardingItem(l10n, context),
                    _buildDrawerItem(icon: Icons.settings_rounded, title: l10n.settings, item: NavItem.settings),
                  ],
                ),
              ),
              _buildLogoutButton(context, authVM, l10n, isDark),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerOnboardingItem(AppLocalizations l10n, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.success),
        ),
        title: Text(l10n.verifyIdentity,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          l10n.verifyIdentitySubtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const OnboardingView()));
        },
      ),
    );
  }

  // ─── Sidebar (web) ────────────────────────────────────────────────────────

  Widget _buildSidebar(AppLocalizations l10n, bool isDark) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        final user = authVM.currentUser;
        return Material(
          elevation: 0,
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.dividerDark : AppColors.divider,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildUserHeader(user, l10n, isDark),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildSidebarItem(icon: Icons.home_rounded, title: l10n.home, item: NavItem.home, isDark: isDark),
                      _buildSidebarItem(icon: Icons.apartment_rounded, title: l10n.properties, item: NavItem.properties, isDark: isDark),
                      _buildSidebarItem(icon: Icons.send_rounded, title: l10n.myApplications, item: NavItem.myApplications, isDark: isDark),
                      _buildSidebarItem(icon: Icons.inbox_rounded, title: l10n.incomingApplications, item: NavItem.incomingApplications, isDark: isDark),
                      _buildSidebarItem(icon: Icons.balance_rounded, title: l10n.lawyers, item: NavItem.lawyers, isDark: isDark),
                      _buildSidebarItem(icon: Icons.person_rounded, title: l10n.myProfile, item: NavItem.profile, isDark: isDark),
                      _buildSidebarSectionLabel(l10n.work, isDark),
                      _buildSidebarItem(icon: Icons.inbox_outlined, title: l10n.workRequests, item: NavItem.work, isDark: isDark),
                      _buildSidebarItem(icon: Icons.description_rounded, title: l10n.contracts, item: NavItem.contracts, isDark: isDark),
                      _buildSidebarItem(icon: Icons.home_work_rounded, title: 'Active Rentals', item: NavItem.activeRentals, isDark: isDark),
                      _buildSidebarItem(icon: Icons.smart_toy_rounded, title: l10n.aiAssistant, item: NavItem.aiAssistant, isDark: isDark),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          color: isDark ? AppColors.dividerDark : AppColors.divider,
                        ),
                      ),
                      _buildSidebarItem(
                        icon: Icons.verified_user_rounded,
                        title: l10n.verifyIdentity,
                        item: null,
                        isDark: isDark,
                        iconColor: AppColors.success,
                        onTap: () {
                          _animController.reverse();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingView()));
                        },
                      ),
                      _buildSidebarItem(icon: Icons.settings_rounded, title: l10n.settings, item: NavItem.settings, isDark: isDark),
                    ],
                  ),
                ),
                _buildLogoutButton(context, authVM, l10n, isDark),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Shared: User header ──────────────────────────────────────────────────

  Widget _buildUserHeader(UserModel? user, AppLocalizations l10n, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF264D7A)],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar with gold ring
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: user?.profileImageUrl != null
                      ? NetworkImageWithAuth(
                          imageUrl: user!.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: () => _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),
              ),
              // Verified badge
              if (user?.isVerified == true)
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user?.fullName ?? l10n.welcomeBack,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          if (user != null) _buildRoleBadge(user.role),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppColors.primaryLight,
      child: const Icon(Icons.person, size: 30, color: Colors.white),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    final Color color;
    final String label;
    final IconData icon;

    switch (role) {
      case UserRole.lawyer:
        color = AppColors.gold;
        label = 'Lawyer';
        icon = Icons.balance_rounded;
        break;
      default:
        color = AppColors.secondary;
        label = 'User';
        icon = Icons.person_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar nav item (web) ───────────────────────────────────────────────

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required NavItem? item,
    required bool isDark,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final isSelected = item != null && _currentPage == item;
    final selectedColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final defaultIconColor = iconColor ??
        (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary);
    final effectiveIconColor = isSelected ? selectedColor : defaultIconColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap ?? (item != null ? () => _navigateTo(item) : null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: isSelected ? selectedColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: effectiveIconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? selectedColor
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: isDark ? AppColors.textHintDark : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: (isDark ? AppColors.dividerDark : AppColors.divider),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Drawer nav item (mobile) ─────────────────────────────────────────────

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required NavItem item,
    ValueListenable<int>? badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentPage == item;
    final selectedColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _navigateTo(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: isSelected ? selectedColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              badge != null
                  ? ValueListenableBuilder<int>(
                      valueListenable: badge,
                      builder: (_, count, _) => _PulsingBadge(
                        count: count,
                        child: Icon(icon, size: 20,
                            color: isSelected ? selectedColor
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
                      ),
                    )
                  : Icon(icon, size: 20,
                      color: isSelected ? selectedColor
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? selectedColor
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: isDark ? AppColors.textHintDark : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? AppColors.dividerDark : AppColors.divider,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared: Logout button ────────────────────────────────────────────────

  Widget _buildLogoutButton(
      BuildContext ctx, AuthViewModel authVM, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _confirmLogout(ctx, authVM, l10n),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Text(
                l10n.logout,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthViewModel authVM, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(l10n.logoutConfirm),
          ],
        ),
        content: Text(l10n.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await authVM.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

// ─── App bar title with subtle brand mark ────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  final String title;
  const _AppBarTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gold, AppColors.goldDark],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.balance_rounded, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Pulsing notification badge ───────────────────────────────────────────────

class _PulsingBadge extends StatefulWidget {
  final int count;
  final Widget child;
  const _PulsingBadge({required this.count, required this.child});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.count > 0) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingBadge old) {
    super.didUpdateWidget(old);
    if (widget.count > 0 && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (widget.count == 0 && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.animateTo(0.0, duration: const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) return widget.child;
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Badge(
        isLabelVisible: true,
        label: Text('${widget.count}'),
        backgroundColor: AppColors.error,
        child: widget.child,
      ),
    );
  }
}
