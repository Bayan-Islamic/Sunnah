import 'package:flutter/material.dart';

import '../constants/hadith_grade.dart';

/// The colour-coded authentication chip shown on every hadith card.
///
/// Sahih renders green, hasan amber and da'if red; a da'if badge also shows the
/// scholar the verdict is attributed to, so a weak narration is never presented
/// without its source.
class GradeBadge extends StatelessWidget {
  const GradeBadge({
    super.key,
    required this.grade,
    this.gradeSource,
    this.compact = false,
  });

  final HadithGrade grade;

  /// Scholar / edition the verdict comes from, e.g. "Al-Albani".
  final String? gradeSource;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final showSource = grade == HadithGrade.daif &&
        gradeSource != null &&
        gradeSource!.trim().isNotEmpty;
    final label = compact
        ? grade.labelEn
        : '${grade.labelAr} · ${grade.labelEn}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: grade.color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(grade.emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (showSource) ...[
            const SizedBox(width: 6),
            Container(width: 1, height: 12, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              gradeSource!.trim(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
