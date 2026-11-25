import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SwImage extends StatelessWidget {
  const SwImage({
    super.key,
    required this.source,
    this.baseUrl = 'http://localhost:5000',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppSpacing.radiusButton,
  });

  final String source;
  final String baseUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final localAsset = AssetResolver.resolveLocalAsset(source);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    Widget child;
    if (localAsset != null) {
      child = Image.asset(
        localAsset,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (ctx, imgChild, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || disableAnimations) {
            return imgChild;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: imgChild,
          );
        },
        errorBuilder: (_, _, _) => _fallbackBox(),
      );
    } else if (source.isEmpty) {
      child = _fallbackBox();
    } else {
      final url = AssetResolver.resolveNetworkUrl(source, baseUrl);
      child = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 220),
        fadeOutDuration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 140),
        fadeInCurve: Curves.easeOutCubic,
        placeholder: (_, _) => Container(
          width: width,
          height: height,
          color: AppColors.surfaceContainerHigh,
        ),
        errorWidget: (_, _, _) => _fallbackBox(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }

  Widget _fallbackBox() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textSubtle,
        size: 24,
      ),
    );
  }
}
