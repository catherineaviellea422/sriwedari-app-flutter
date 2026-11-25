import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_heritage_backdrop.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(authProvider.notifier).loginAsAdmin(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
    if (ok && mounted) {
      final target = widget.redirectTo;
      if (target != null && target.startsWith('/admin') && target != AppRoutes.adminLogin) {
        context.go(target);
      } else {
        context.go(AppRoutes.adminDashboard);
      }
    }
  }

  Future<void> _demoAdminLogin() async {
    _emailController.text = 'admin@galerisriwedari.id';
    _passwordController.text = 'rahasia123';
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final config = ref.watch(appConfigProvider);

    return AuthHeritageBackdrop(
      title: 'Galeri Sriwedari',
      subtitle: 'Login sebagai Admin',
      badgeText: 'Gerbang Kurator & Operasional (sriwedari-admin-db)',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.login);
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (authState.errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF450A0A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFFCA5A5),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authState.errorMessage!,
                        style: AppTypography.bodyMd(color: const Color(0xFFFEE2E2)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SwInput(
              controller: _emailController,
              darkSurface: true,
              label: 'Email',
              hint: 'admin@galerisriwedari.id',
              prefixIcon: Icons.admin_panel_settings_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: SwValidators.emailOrPhone,
            ),
            const SizedBox(height: 14),
            SwInput(
              controller: _passwordController,
              darkSurface: true,
              label: 'Kata Sandi',
              hint: 'Masukkan kata sandi kurator',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              enablePasswordToggle: true,
              validator: (v) => SwValidators.password(v, minLength: 4),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            SwButton(
              label: 'Masuk',
              variant: SwButtonVariant.gold,
              trailingIcon: Icons.shield_outlined,
              fullWidth: true,
              isLoading: authState.isLoading,
              onPressed: _submit,
            ),
            if (config.showDemoShortcuts) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: authState.isLoading ? null : _demoAdminLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.goldLight,
                  side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                  ),
                ),
                icon: const Icon(Icons.bolt_rounded, size: 17),
                label: Text(
                  'Demo 1-Klik Kurator (Dev)',
                  style: AppTypography.labelMd(color: AppColors.goldLight),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Server Dev: ${config.baseUrl}',
                textAlign: TextAlign.center,
                style: AppTypography.labelSm(
                  color: AppColors.canvas.withValues(alpha: 0.78),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.userDashboard);
                }
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: AppColors.gold,
              ),
              label: Text(
                'Kembali ke Beranda',
                style: AppTypography.labelMd(color: AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
