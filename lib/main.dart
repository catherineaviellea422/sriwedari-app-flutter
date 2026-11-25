import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/storage_backend.dart';

Future<void> bootstrapSriwedariApp({AppConfig? overrideConfig}) async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final config = overrideConfig ?? AppConfig.fromEnvironment();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        keyValueStoreProvider.overrideWithValue(
          SharedPrefsKeyValueStore(prefs),
        ),
      ],
      child: const SriwedariApp(),
    ),
  );
}

Future<void> main() async {
  await bootstrapSriwedariApp();
}
