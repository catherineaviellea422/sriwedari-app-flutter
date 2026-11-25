import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class GamelanPreset {
  const GamelanPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.laras,
    required this.tempoNote,
  });

  final String id;
  final String name;
  final String description;
  final String laras;
  final String tempoNote;
}

const List<GamelanPreset> gamelanPresets = [
  GamelanPreset(
    id: 'slendro',
    name: 'Ladrang Wilujeng',
    description: 'Suasana damai peneduh jiwa khas pendopo kraton Surakarta.',
    laras: 'Slendro Manyura',
    tempoNote: 'Irama lambat–khidmat • Kendang sabet & rebab dominan',
  ),
  GamelanPreset(
    id: 'pelog',
    name: 'Ketawang Subakastawa',
    description: 'Nada agung nan sakral pengiring tari klasik keraton.',
    laras: 'Pelog Nem',
    tempoNote: 'Irama agung • Vokal sindhen & gender barung lembut',
  ),
  GamelanPreset(
    id: 'sriwedari',
    name: 'Ayak-Ayak Sriwedari',
    description: 'Alunan dinamis pengiring adegan wayang wong dan tari heroik.',
    laras: 'Slendro Sanga',
    tempoNote: 'Irama dinamis • Bonang penerus & saron bersahutan',
  ),
];

/// Kartu informasi laras dan gending pengiring khas Galeri Sriwedari.
class HeritageAudioPlayer extends StatefulWidget {
  const HeritageAudioPlayer({super.key});

  @override
  State<HeritageAudioPlayer> createState() => _HeritageAudioPlayerState();
}

class _HeritageAudioPlayerState extends State<HeritageAudioPlayer> {
  bool _isExpanded = false;
  int _selectedPresetIndex = 0;

  @override
  Widget build(BuildContext context) {
    final preset = gamelanPresets[_selectedPresetIndex];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGreenGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.goldLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'REKOMENDASI GENDING PENGIRING',
                          style: AppTypography.labelSm(color: AppColors.goldLight)
                              .copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${preset.name} (${preset.laras})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd(color: Colors.white),
                      ),
                      Text(
                        preset.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd(
                          color: AppColors.canvas.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.goldLight,
                  ),
                ),
              ],
            ),
          ),
          SwAnimatedExpand(
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Divider(color: AppColors.gold.withValues(alpha: 0.22)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(gamelanPresets.length, (idx) {
                          final item = gamelanPresets[idx];
                          final active = idx == _selectedPresetIndex;
                          return ChoiceChip(
                            label: Text(item.name),
                            selected: active,
                            selectedColor: AppColors.gold,
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.25),
                            labelStyle: AppTypography.labelMd(
                              color: active
                                  ? AppColors.brandGreenDark
                                  : AppColors.canvas,
                            ),
                            side: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedPresetIndex = idx),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        preset.tempoNote,
                        style: AppTypography.labelSm(color: AppColors.goldLight),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
