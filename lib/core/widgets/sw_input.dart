import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SwInput extends StatefulWidget {
  const SwInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixWidget,
    this.obscureText = false,
    this.enablePasswordToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autovalidateMode,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    this.darkSurface = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final bool obscureText;
  final bool enablePasswordToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool darkSurface;

  @override
  State<SwInput> createState() => _SwInputState();
}

class _SwInputState extends State<SwInput> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final labelColor =
        widget.darkSurface ? AppColors.canvas : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMd(color: labelColor),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          autovalidateMode: widget.autovalidateMode,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: AppTypography.bodyLg(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            fillColor: AppColors.ivory,
            filled: true,
            constraints: widget.maxLines == 1
                ? const BoxConstraints(minHeight: AppSpacing.inputHeight)
                : null,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 18, color: AppColors.brandGreen)
                : null,
            suffixIcon: widget.enablePasswordToggle
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.textSubtle,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                    tooltip: _obscured ? 'Tampilkan sandi' : 'Sembunyikan sandi',
                  )
                : widget.suffixWidget,
          ),
        ),
      ],
    );
  }
}

class SwSearchBar extends StatelessWidget {
  const SwSearchBar({
    super.key,
    this.controller,
    this.hint = 'Cari galeri, kostum...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: AppTypography.bodyLg(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        fillColor: AppColors.parchment,
        filled: true,
        constraints: const BoxConstraints(minHeight: AppSpacing.inputHeight),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 19,
          color: AppColors.brandGreen,
        ),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textSubtle,
                onPressed: () {
                  controller!.clear();
                  onClear?.call();
                  onChanged?.call('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: AppColors.warmGray.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: AppColors.warmGray.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
        ),
      ),
    );
  }
}
