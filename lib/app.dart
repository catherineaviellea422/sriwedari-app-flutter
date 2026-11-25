import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'core/motion/sw_scroll_behavior.dart';
import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class SriwedariApp extends ConsumerStatefulWidget {
  const SriwedariApp({super.key, this.autoRestoreSession = true});

  final bool autoRestoreSession;

  @override
  ConsumerState<SriwedariApp> createState() => _SriwedariAppState();
}

class _SriwedariAppState extends ConsumerState<SriwedariApp> {
  @override
  void initState() {
    super.initState();
    GoRouter.optionURLReflectsImperativeAPIs = true;
    if (widget.autoRestoreSession) {
      Future.microtask(() {
        ref.read(authProvider.notifier).restoreSession();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: config.isDev,
      theme: AppTheme.light,
      scrollBehavior: const SwScrollBehavior(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
