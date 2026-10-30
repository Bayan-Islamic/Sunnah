import 'package:flutter/material.dart';

import '../../../../core/constants/hadith_grade.dart';
import '../../../../core/models/hadith.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../../core/widgets/grade_badge.dart';

/// A single hadith rendered as a card: grade chip, Arabic matn, translation and
/// the reference line.
///
/// Arabic is the primary text and is laid out with the theme's generous
/// [AppTheme.arabicLineHeight]; the translation is secondary and muted.
class HadithCard extends StatelessWidget {
  const HadithCard({
    super.key,
    required this.hadith,
    this.onBookmark,
    this.onShare,
    this.onCopy,
    this.showBookName = false,
    this.arabicFontScale = 1.0,
    this.highlight = '',
  });

  final Hadith hadith;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final VoidCallback? onCopy;
  final bool showBookName;
  final double arabicFontScale;

  /// Normalised query fragment to highlight in the Arabic text.
  final String highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.textTheme.bodySmall?.color;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, muted),
            const SizedBox(height: 12),
            _arabicMatn(context, highlight),
            if (hadith.matnEn.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                hadith.matnEn.trim(),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Divider(color: theme.dividerColor),
            _actions(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Color? muted) {
    final theme = Theme.of(context);
    final location = showBookName && hadith.bookNameEn.isNotEmpty
        ? '${hadith.bookNameEn} · ${hadith.hadithNumber}'
        : '${hadith.hadithNumber}';
    return Row(
      children: [
        GradeBadge(grade: hadith.grade, gradeSource: hadith.gradeSource),
        const Spacer(),
        Flexible(
          child: Text(
            location,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _arabicMatn(BuildContext context, String highlight) {
    final theme = Theme.of(context);
    final baseStyle = TextStyle(
      fontSize: 22 * arabicFontScale,
      height: AppTheme.arabicLineHeight,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
    );
    final spans = _highlightSpans(highlight, baseStyle);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.right,
        text: TextSpan(style: baseStyle, children: spans),
      ),
    );
  }

  /// Wraps occurrences of the normalised [highlight] in a coloured span.
  ///
  /// The display text keeps its diacritics, so the match is located on a
  /// character-by-character normalised copy and the offsets are mapped back to
  /// the original string.
  List<TextSpan> _highlightSpans(String highlight, TextStyle baseStyle) {
    final text = hadith.matnAr.trim();
    final needle = ArabicNormalizer.normalize(highlight);
    if (needle.isEmpty) {
      return [TextSpan(text: text)];
    }

    final (haystack, offsets) = ArabicNormalizer.normalizeWithOffsets(text);

    final spans = <TextSpan>[];
    var cursor = 0; // Index into `haystack`.
    var emitted = 0; // Index into `text`.
    while (true) {
      final match = haystack.indexOf(needle, cursor);
      if (match < 0) {
        break;
      }
      final matchEnd = match + needle.length;
      final startOriginal = offsets[match];
      final endOriginal =
          matchEnd < offsets.length ? offsets[matchEnd] : text.length;
      if (startOriginal > emitted) {
        spans.add(TextSpan(text: text.substring(emitted, startOriginal)));
      }
      spans.add(
        TextSpan(
          text: text.substring(startOriginal, endOriginal),
          style: baseStyle.copyWith(
            backgroundColor: HadithGrade.hasan.color.withValues(alpha: 0.35),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      emitted = endOriginal;
      cursor = matchEnd;
    }
    if (emitted < text.length) {
      spans.add(TextSpan(text: text.substring(emitted)));
    }
    return spans;
  }

  Widget _actions(BuildContext context, bool isDark) {
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: 'Copy',
          onPressed: onCopy,
          icon: Icon(Icons.copy_rounded, size: 20, color: iconColor),
        ),
        IconButton(
          tooltip: 'Share',
          onPressed: onShare,
          icon: Icon(Icons.share_rounded, size: 20, color: iconColor),
        ),
        IconButton(
          tooltip: hadith.isBookmarked ? 'Remove bookmark' : 'Bookmark',
          onPressed: onBookmark,
          icon: Icon(
            hadith.isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            size: 22,
            color: hadith.isBookmarked
                ? Theme.of(context).colorScheme.primary
                : iconColor,
          ),
        ),
      ],
    );
  }
}
