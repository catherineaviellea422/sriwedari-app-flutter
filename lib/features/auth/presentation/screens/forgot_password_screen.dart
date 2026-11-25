import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/sw_page_transitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_heritage_backdrop.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _requestFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _completed = false;
  String? _statusMessage;
  String? _devResetCode;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!_requestFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(_identifierController.text.trim());
      setState(() {
        _codeSent = true;
        _statusMessage = result.message;
        _devResetCode = result.resetCode;
        if (result.resetCode != null) {
          _codeController.text = result.resetCode!;
        }
      });
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Gagal mengirim permintaan pemulihan.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final msg = await ref.read(authRepositoryProvider).confirmPasswordReset(
            identifier: _identifierController.text.trim(),
            code: _codeController.text.trim(),
            newPassword: _newPasswordController.text.trim(),
          );
      setState(() {
        _completed = true;
        _statusMessage = msg;
      });
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Gagal mengatur ulang kata sandi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageKey = _completed
        ? const ValueKey('forgot-stage-2')
        : _codeSent
            ? const ValueKey('forgot-stage-1')
            : const ValueKey('forgot-stage-0');

    return AuthHeritageBackdrop(
      title: 'Pemulihan Sandi',
      subtitle:
          'Masukkan email atau nomor WhatsApp terdaftar Anda untuk mengatur ulang kata sandi',
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF450A0A).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.6)),
              ),
              child: Text(
                _errorMessage!,
                style: AppTypography.bodyMd(color: const Color(0xFFFEE2E2)),
              ),
            ),
          ],
          SwDirectionalSwitcher(
            isForward: true,
            child: KeyedSubtree(
              key: stageKey,
              child: _completed
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF064E3B).withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF34D399)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            _statusMessage ?? 'Kata sandi berhasil diperbarui.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMd(
                              color: const Color(0xFFD1FAE5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwButton(
                          label: 'Kembali ke Halaman Masuk',
                          variant: SwButtonVariant.gold,
                          trailingIcon: Icons.arrow_forward_rounded,
                          fullWidth: true,
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.login);
                            }
                          },
                        ),
                      ],
                    )
                  : _codeSent
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF064E3B)
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF34D399)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _statusMessage ??
                                        'Instruksi pemulihan telah dikirim.',
                                    style: AppTypography.bodyMd(
                                      color: const Color(0xFFD1FAE5),
                                    ),
                                  ),
                                  if (_devResetCode != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Kode Simulasi Dev: $_devResetCode',
                                      style: AppTypography.labelMd(
                                        color: AppColors.goldLight,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Form(
                              key: _resetFormKey,
                              child: Column(
                                children: [
                                  SwInput(
                                    controller: _codeController,
                                    darkSurface: true,
                                    label: 'Kode Verifikasi 6 Digit',
                                    hint: 'Masukkan 6 digit kode',
                                    prefixIcon: Icons.pin_outlined,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: SwInputFormatters.otpCode,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    validator: SwValidators.otpCode,
                                  ),
                                  const SizedBox(height: 12),
                                  SwInput(
                                    controller: _newPasswordController,
                                    darkSurface: true,
                                    label: 'Kata Sandi Baru',
                                    hint: 'Minimal 6 karakter',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    obscureText: true,
                                    enablePasswordToggle: true,
                                    validator: (v) =>
                                        SwValidators.password(v, minLength: 6),
                                  ),
                                  const SizedBox(height: 16),
                                  SwButton(
                                    label: 'Simpan Kata Sandi Baru',
                                    variant: SwButtonVariant.gold,
                                    fullWidth: true,
                                    isLoading: _isLoading,
                                    onPressed: _confirmReset,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Form(
                          key: _requestFormKey,
                          child: Column(
                            children: [
                              SwInput(
                                controller: _identifierController,
                                darkSurface: true,
                                label: 'Email atau Nomor WhatsApp',
                                hint: 'misal: oliv@example.com / 081234567890',
                                prefixIcon: Icons.contact_mail_outlined,
                                inputFormatters: SwInputFormatters.noWhitespace,
                                validator: SwValidators.emailOrPhone,
                              ),
                              const SizedBox(height: 16),
                              SwButton(
                                label: 'Kirim Instruksi Pemulihan',
                                variant: SwButtonVariant.gold,
                                trailingIcon: Icons.send_rounded,
                                fullWidth: true,
                                isLoading: _isLoading,
                                onPressed: _requestReset,
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          if (!_completed) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.login);
                }
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: AppColors.gold,
              ),
              label: Text(
                'Batalkan & Kembali',
                style: AppTypography.labelMd(color: AppColors.gold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
