import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sriwedari_app/core/theme/app_theme.dart';
import 'package:sriwedari_app/core/widgets/core_widgets.dart';
import 'package:sriwedari_app/core/widgets/design_system_showcase.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('Design System Core Widgets', () {
    testWidgets('SwButton merender label, onPressed, dan state loading', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              SwButton(label: 'Masuk Sekarang', onPressed: () => tapped = true),
              const SwButton(label: 'Memuat', isLoading: true),
            ],
          ),
        ),
      );

      expect(find.text('Masuk Sekarang'), findsOneWidget);
      await tester.tap(find.text('Masuk Sekarang'));
      expect(tapped, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('SwInput mendukung toggle visibility kata sandi', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const SwInput(
            label: 'Kata Sandi',
            hint: 'Masukkan kata sandi',
            obscureText: true,
            enablePasswordToggle: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets(
      'SwFilterChip, SwMetricCard, SwStatusBadge, dan SwEmptyState tampil utuh',
      (tester) async {
        var selected = false;
        await tester.pumpWidget(
          wrap(
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    SwFilterChip(
                      label: 'Tari Tradisional',
                      selected: selected,
                      onTap: () => setState(() => selected = !selected),
                    ),
                    const SwMetricCard(
                      label: 'Total Galeri',
                      value: '128',
                      icon: Icons.photo_library_outlined,
                      tone: SwMetricTone.mint,
                    ),
                    SwStatusBadge.fromOrderStatus('Dikonfirmasi'),
                    SwStatusBadge.fromRole('admin'),
                    const SwEmptyState(
                      title: 'Belum Ada Pesanan',
                      description: 'Anda belum menyewa busana adat.',
                    ),
                  ],
                );
              },
            ),
          ),
        );

        expect(find.text('Tari Tradisional'), findsOneWidget);
        expect(find.text('Total Galeri'), findsOneWidget);
        expect(find.text('128'), findsOneWidget);
        expect(find.text('Dikonfirmasi'), findsOneWidget);
        expect(find.text('Admin'), findsOneWidget);
        expect(find.text('Belum Ada Pesanan'), findsOneWidget);

        await tester.tap(find.text('Tari Tradisional'));
        await tester.pump();
      },
    );

    testWidgets(
      'SwConfirmDialog.showLogoutModal mengembalikan false saat Batal dan true saat Ya, Keluar',
      (tester) async {
        bool? dialogResult;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    dialogResult = await SwConfirmDialog.showLogoutModal(
                      context,
                    );
                  },
                  child: const Text('Buka Modal'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Buka Modal'));
        await tester.pumpAndSettle();
        expect(find.text('Keluar dari akun?'), findsOneWidget);
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(dialogResult, isFalse);

        await tester.tap(find.text('Buka Modal'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ya, Keluar'));
        await tester.pumpAndSettle();
        expect(dialogResult, isTrue);
      },
    );

    testWidgets(
      'DesignSystemShowcaseScreen merender di ukuran Mobile (390x844) dan Desktop (1280x800)',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light,
              home: const DesignSystemShowcaseScreen(),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Nusantara Heritage Elegance'), findsOneWidget);

        tester.view.physicalSize = const Size(1280, 800);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light,
              home: const DesignSystemShowcaseScreen(),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Nusantara Heritage Elegance'), findsOneWidget);
      },
    );
  });
}
