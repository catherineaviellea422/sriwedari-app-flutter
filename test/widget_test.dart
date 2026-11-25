import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sriwedari_app/app.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SriwedariApp boots cleanly with GoRouter into LoginScreen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SriwedariApp(autoRestoreSession: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GALERI SRIWEDARI'), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
  });
}
