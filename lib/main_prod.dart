import 'core/config/app_config.dart';
import 'main.dart';

Future<void> main() async {
  await bootstrapSriwedariApp(
    overrideConfig: const AppConfig(
      flavor: AppFlavor.prod,
      baseUrl: 'https://api.galerisriwedari.id',
      appName: 'Galeri Sriwedari',
    ),
  );
}
