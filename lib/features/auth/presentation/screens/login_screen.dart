import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_heritage_backdrop.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'user'; // 'user' | 'admin'
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_selectedRole == 'admin') {
      final ok = await auth.loginAsAdmin(email: email, password: password);
      if (ok && mounted) {
        context.go(widget.redirectTo?.startsWith('/admin') == true
            ? widget.redirectTo!
            : AppRoutes.adminDashboard);
      }
    } else {
      final ok = await auth.loginAsUser(
        email: email,
        password: password,
        rememberMe: _rememberMe,
      );
      if (ok && mounted) {
        final target = widget.redirectTo;
        if (target != null && !target.startsWith('/admin')) {
          context.go(target);
        } else {
          context.go(AppRoutes.userDashboard);
        }
      }
    }
  }

  Future<void> _fillAndSubmitDemo() async {
    if (_selectedRole == 'admin') {
      _emailController.text = 'admin@galerisriwedari.id';
      _passwordController.text = 'rahasia123';
    } else {
      _emailController.text = 'oliv@example.com';
      _passwordController.text = 'rahasia123';
    }
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final config = ref.watch(appConfigProvider);

    return AuthHeritageBackdrop(
      title: 'GALERI SRIWEDARI',
      subtitle: 'Ruang Dokumentasi Seni Tari & Busana Pusaka Keraton Surakarta',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selamat Datang',
              style: AppTypography.headlineMd(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Silakan masuk untuk melanjutkan ke Galeri Sriwedari.',
              style: AppTypography.bodyMd(
                color: AppColors.canvas.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _RoleTabButton(
                      label: 'Pengguna / Tamu',
                      icon: Icons.person_outline_rounded,
                      selected: _selectedRole == 'user',
                      onTap: () {
                        setState(() => _selectedRole = 'user');
                        ref.read(authProvider.notifier).clearError();
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _RoleTabButton(
                      label: 'Kurator / Admin',
                      icon: Icons.shield_outlined,
                      selected: _selectedRole == 'admin',
                      onTap: () {
                        setState(() => _selectedRole = 'admin');
                        ref.read(authProvider.notifier).clearError();
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
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
            const SizedBox(height: 16),
            SwInput(
              controller: _emailController,
              darkSurface: true,
              label: _selectedRole == 'admin'
                  ? 'Email Staf / Kurator'
                  : 'Email atau Nomor Telepon',
              hint: _selectedRole == 'admin'
                  ? 'admin@galerisriwedari.id'
                  : 'oliv@example.com',
              prefixIcon: _selectedRole == 'admin'
                  ? Icons.admin_panel_settings_outlined
                  : Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: SwValidators.emailOrPhone,
            ),
            const SizedBox(height: 14),
            SwInput(
              controller: _passwordController,
              darkSurface: true,
              label: 'Kata Sandi',
              hint: 'Masukkan kata sandi akun',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              enablePasswordToggle: true,
              validator: (v) => SwValidators.password(v, minLength: 4),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: AppColors.gold,
                  checkColor: AppColors.brandGreenDark,
                  side: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.6),
                  ),
                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                ),
                Expanded(
                  child: Text(
                    'Ingat saya',
                    style: AppTypography.bodyMd(
                      color: AppColors.canvas.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: Text(
                    'Lupa sandi?',
                    style: AppTypography.labelMd(color: AppColors.gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwButton(
              label: _selectedRole == 'admin'
                  ? 'Masuk Panel Kurator'
                  : 'Masuk Sekarang',
              variant: SwButtonVariant.gold,
              trailingIcon: Icons.login_rounded,
              fullWidth: true,
              isLoading: authState.isLoading,
              onPressed: _submit,
            ),
            if (config.showDemoShortcuts) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: authState.isLoading ? null : _fillAndSubmitDemo,
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
                  _selectedRole == 'admin'
                      ? 'Demo 1-Klik Kurator (Dev)'
                      : 'Demo 1-Klik Pengguna (Dev)',
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('login-guest-cta'),
              onPressed: () => context.go(AppRoutes.userDashboard),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.canvas,
                side: BorderSide(
                  color: AppColors.canvas.withValues(alpha: 0.35),
                ),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                ),
              ),
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: Text(
                'Jelajahi sebagai Tamu',
                style: AppTypography.labelMd(color: AppColors.canvas),
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: AppColors.gold.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  'Belum punya akun?',
                  style: AppTypography.bodyMd(
                    color: AppColors.canvas.withValues(alpha: 0.8),
                  ),
                ),
                InkWell(
                  onTap: () => context.push(AppRoutes.register),
                  child: Text(
                    'Daftar di sini',
                    style: AppTypography.labelMd(color: AppColors.gold).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                TextButton(
                  onPressed: () => context.go(AppRoutes.about),
                  child: Text(
                    'Tentang Kami',
                    style: AppTypography.labelSm(
                      color: AppColors.canvas.withValues(alpha: 0.8),
                    ).copyWith(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.blog),
                  child: Text(
                    'Warta Budaya',
                    style: AppTypography.labelSm(
                      color: AppColors.canvas.withValues(alpha: 0.8),
                    ).copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTabButton extends StatelessWidget {
  const _RoleTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.gold : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.brandGreenDark
                    : AppColors.canvas.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd(
                    color: selected
                        ? AppColors.brandGreenDark
                        : AppColors.canvas.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
