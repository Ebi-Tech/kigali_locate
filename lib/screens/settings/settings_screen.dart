import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.settings)),
        body: EmptySettingsState(context: context),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        children: [
          // Profile card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: profileAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => Text('Error: $e',
                    style:
                        const TextStyle(color: AppColors.textHint)),
                data: (profile) => Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          AppColors.accent.withValues(alpha: 0.2),
                      child: Text(
                        _initials(
                            profile?.fullName ?? user.displayName ?? 'U'),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.fullName ??
                                user.displayName ??
                                'User',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          if (profile?.createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Member since ${DateFormat('MMM yyyy').format(profile!.createdAt)}',
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Email verified badge
                    if (user.emailVerified)
                      const Icon(Icons.verified_rounded,
                          color: AppColors.success, size: 20)
                    else
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 20),
                  ],
                ),
              ),
            ),
          ),

          // Settings sections
          _sectionHeader('Preferences'),

          // Notifications toggle
          _settingsTile(
            icon: Icons.notifications_outlined,
            title: AppStrings.notifications,
            subtitle: AppStrings.notificationsSubtitle,
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (_) =>
                  ref.read(notificationsProvider.notifier).toggle(),
            ),
          ),

          const Divider(indent: 16, endIndent: 16, height: 1),

          _sectionHeader('Account'),

          // Email verification status
          if (!user.emailVerified)
            _settingsTile(
              icon: Icons.mark_email_unread_outlined,
              iconColor: AppColors.warning,
              title: 'Email Not Verified',
              subtitle: 'Tap to resend verification email.',
              onTap: () async {
                await ref
                    .read(authNotifierProvider.notifier)
                    .sendVerificationEmail();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Verification email sent!')),
                  );
                }
              },
            ),

          _settingsTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: AppStrings.logout,
            subtitle: 'Sign out of your account.',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).signOut();
              }
            },
          ),

          const SizedBox(height: 20),
          _sectionHeader('About'),

          _settingsTile(
            icon: Icons.info_outline_rounded,
            title: AppStrings.appName,
            subtitle: 'Version 1.0.0 · Kigali City Directory',
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.textSecondary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: iconColor ?? AppColors.textSecondary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 12),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint)
              : null),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

class EmptySettingsState extends StatelessWidget {
  final BuildContext context;
  const EmptySettingsState({super.key, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline_rounded,
                color: AppColors.textHint, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Sign in to access settings',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log in to view your profile and preferences.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text(AppStrings.login),
            ),
          ],
        ),
      ),
    );
  }
}
