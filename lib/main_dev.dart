import 'core/config/app_config.dart';
import 'main.dart';

Future<void> main() async {
  await bootstrapSriwedariApp(
    overrideConfig: AppConfig.fromEnvironment(),
  );
}
