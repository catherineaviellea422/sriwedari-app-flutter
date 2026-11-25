import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_heritage_backdrop.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(authProvider.notifier).registerUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
        );
    if (ok && mounted) {
      context.go(AppRoutes.userDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AuthHeritageBackdrop(
      title: 'Daftar Akun Baru',
      subtitle: 'Bergabung untuk reservasi tiket pentas & sewa busana keraton',
      badgeText: 'Bonus +50 Poin Budaya Awal',
      showBackButton: true,
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
              controller: _nameController,
              darkSurface: true,
              label: 'Nama Lengkap / Sanggar',
              hint: 'misal: Raden Bagus Wicaksono',
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              inputFormatters: SwInputFormatters.personName,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => SwValidators.personName(v, 'Nama lengkap'),
            ),
            const SizedBox(height: 12),
            SwInput(
              controller: _emailController,
              darkSurface: true,
              label: 'Alamat Email',
              hint: 'nama@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              inputFormatters: SwInputFormatters.noWhitespace,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: SwValidators.email,
            ),
            const SizedBox(height: 12),
            SwInput(
              controller: _phoneController,
              darkSurface: true,
              label: 'Nomor WhatsApp / HP',
              hint: '081234567890',
              prefixIcon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              inputFormatters: SwInputFormatters.phoneDigits,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: SwValidators.phoneId,
            ),
            const SizedBox(height: 12),
            SwInput(
              controller: _passwordController,
              darkSurface: true,
              label: 'Kata Sandi',
              hint: 'Minimal 6 karakter',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              enablePasswordToggle: true,
              validator: (v) => SwValidators.password(v, minLength: 6),
            ),
            const SizedBox(height: 12),
            SwInput(
              controller: _confirmController,
              darkSurface: true,
              label: 'Ulangi Kata Sandi',
              hint: 'Ketik ulang kata sandi',
              prefixIcon: Icons.lock_reset_rounded,
              obscureText: true,
              enablePasswordToggle: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Konfirmasi sandi wajib diisi';
                if (v != _passwordController.text) {
                  return 'Konfirmasi kata sandi tidak cocok';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            SwButton(
              label: 'Daftar & Masuk Aplikasi',
              variant: SwButtonVariant.gold,
              trailingIcon: Icons.arrow_forward_rounded,
              fullWidth: true,
              isLoading: authState.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.gold.withValues(alpha: 0.2)),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  'Sudah memiliki akun terdaftar?',
                  style: AppTypography.bodyMd(
                    color: AppColors.canvas.withValues(alpha: 0.72),
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  child: Text(
                    'Masuk di sini',
                    style: AppTypography.labelMd(color: AppColors.gold).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.gold,
                    ),
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
