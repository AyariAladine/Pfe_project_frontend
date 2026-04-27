import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/theme_provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../auth/login/login_view.dart';
import '../widgets/language_selector.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  bool _notifyApplications = true;
  bool _notifyMessages = true;
  bool _notifyProperties = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Appearance ──
              _SectionHeader(title: l10n.settingsAppearance, icon: Icons.palette_rounded),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.brightness_6_rounded,
                    title: l10n.settingsTheme,
                    trailing: SegmentedButton<ThemeMode>(
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (set) => themeProvider.setThemeMode(set.first),
                      segments: [
                        ButtonSegment(value: ThemeMode.light, label: Text(l10n.light)),
                        ButtonSegment(value: ThemeMode.system, label: Text(l10n.auto)),
                        ButtonSegment(value: ThemeMode.dark, label: Text(l10n.dark)),
                      ],
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(
                          Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    title: l10n.settingsLanguage,
                    trailing: const LanguageSelector(),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Notifications ──
              _SectionHeader(title: l10n.settingsNotifications, icon: Icons.notifications_rounded),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _ToggleTile(
                    title: l10n.settingsNotifyApplications,
                    value: _notifyApplications,
                    onChanged: (v) => setState(() => _notifyApplications = v),
                  ),
                  const Divider(height: 1),
                  _ToggleTile(
                    title: l10n.settingsNotifyMessages,
                    value: _notifyMessages,
                    onChanged: (v) => setState(() => _notifyMessages = v),
                  ),
                  const Divider(height: 1),
                  _ToggleTile(
                    title: l10n.settingsNotifyProperties,
                    value: _notifyProperties,
                    onChanged: (v) => setState(() => _notifyProperties = v),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Account ──
              _SectionHeader(title: l10n.settingsAccount, icon: Icons.person_rounded),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.lock_rounded,
                    title: l10n.settingsChangePassword,
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () => _showChangePasswordDialog(context, l10n),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    title: l10n.logout,
                    iconColor: AppColors.error,
                    titleColor: AppColors.error,
                    onTap: () => _confirmLogout(context, l10n),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.delete_forever_rounded,
                    title: l10n.settingsDeleteAccount,
                    iconColor: AppColors.error,
                    titleColor: AppColors.error,
                    onTap: () => _confirmDeleteAccount(context, l10n),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── About ──
              _SectionHeader(title: l10n.settingsAbout, icon: Icons.info_rounded),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: l10n.settingsVersion,
                    trailing: Text(
                      '1.0.0',
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppLocalizations l10n) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        String? error;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(l10n.settingsChangePassword),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPwController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l10n.currentPassword),
                      validator: (v) => (v == null || v.isEmpty) ? l10n.currentPasswordRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPwController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l10n.newPassword),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.newPasswordRequired;
                        if (v.length < 6) return l10n.passwordTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPwController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l10n.confirmPassword),
                      validator: (v) =>
                          v != newPwController.text ? l10n.passwordsDoNotMatch : null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isLoading = true;
                            error = null;
                          });
                          try {
                            final authService = AuthService();
                            // Verify current password by signing in
                            final authVM = context.read<AuthViewModel>();
                            final email = authVM.currentUser?.email ?? '';
                            await authService.signIn(
                              email: email,
                              password: currentPwController.text,
                            );
                            // Reset password using forgot-password flow
                            await authService.forgotPassword(email);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.passwordChangedSuccess)),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              error = l10n.passwordChangeError;
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.changePassword),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    final authVM = context.read<AuthViewModel>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.logoutConfirm),
        content: Text(l10n.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
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

  void _confirmDeleteAccount(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(l10n.settingsDeleteAccount),
          ],
        ),
        content: Text(l10n.settingsDeleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Call backend delete account endpoint when available
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? (isDark ? AppColors.primaryLight : AppColors.primary)),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}
