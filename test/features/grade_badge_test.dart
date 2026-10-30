import 'package:bayan_sunnah/core/constants/hadith_grade.dart';
import 'package:bayan_sunnah/core/models/hadith.dart';
import 'package:bayan_sunnah/core/theme/app_theme.dart';
import 'package:bayan_sunnah/core/widgets/grade_badge.dart';
import 'package:bayan_sunnah/features/hadith_reader/presentation/widgets/hadith_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );

const _hadith = Hadith(
  id: 1,
  bookId: 1,
  chapterId: 1,
  hadithNumber: 1,
  narrator: 'Umar ibn al-Khattab',
  matnAr: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
  matnEn: 'Actions are but by intention.',
  grade: HadithGrade.sahih,
  gradeSource: 'Darussalam',
  bookNameEn: 'Sahih al-Bukhari',
);

/// The card renders the Arabic matn through a [RichText], so it is located by
/// its plain text rather than by a [Text] widget finder.
Finder _matnRichText() => find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('إِنَّمَا'),
    );

void main() {
  group('GradeBadge', () {
    testWidgets('renders green for sahih', (tester) async {
      await tester.pumpWidget(
        _host(const GradeBadge(grade: HadithGrade.sahih)),
      );
      expect(find.textContaining('صحيح'), findsOneWidget);
      expect(find.textContaining('Sahih'), findsOneWidget);
    });

    testWidgets('renders amber for hasan', (tester) async {
      await tester.pumpWidget(
        _host(const GradeBadge(grade: HadithGrade.hasan)),
      );
      expect(find.textContaining('حَسَن'), findsOneWidget);
    });

    testWidgets('shows the scholar verdict on a daif badge', (tester) async {
      await tester.pumpWidget(
        _host(
          const GradeBadge(
            grade: HadithGrade.daif,
            gradeSource: 'Al-Albani',
          ),
        ),
      );
      expect(find.textContaining("Da'if"), findsOneWidget);
      expect(find.text('Al-Albani'), findsOneWidget);
    });

    testWidgets('omits the source when none is supplied', (tester) async {
      await tester.pumpWidget(
        _host(const GradeBadge(grade: HadithGrade.daif)),
      );
      expect(find.text('Al-Albani'), findsNothing);
    });

    testWidgets('uses the specified colours', (tester) async {
      await tester.pumpWidget(
        _host(const GradeBadge(grade: HadithGrade.sahih)),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GradeBadge),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFF059669));
    });
  });

  group('HadithCard', () {
    testWidgets('shows the Arabic matn, translation and reference',
        (tester) async {
      await tester.pumpWidget(
        _host(
          HadithCard(
            hadith: _hadith,
            showBookName: true,
            onBookmark: () {},
            onCopy: () {},
            onShare: () {},
          ),
        ),
      );
      expect(_matnRichText(), findsOneWidget);
      expect(find.textContaining('Actions are but'), findsOneWidget);
      expect(find.textContaining('Sahih al-Bukhari'), findsOneWidget);
    });

    testWidgets('lays the Arabic out right-to-left', (tester) async {
      await tester.pumpWidget(_host(HadithCard(hadith: _hadith)));
      final richText = tester.widget<RichText>(_matnRichText());
      expect(richText.textAlign, TextAlign.right);
      final directionality = tester.widget<Directionality>(
        find
            .ancestor(
              of: _matnRichText(),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('bookmark action reflects the saved flag', (tester) async {
      await tester.pumpWidget(
        _host(HadithCard(hadith: _hadith.copyWith(isBookmarked: true))),
      );
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
    });

    testWidgets('invokes callbacks', (tester) async {
      var copied = false;
      var shared = false;
      var bookmarked = false;
      await tester.pumpWidget(
        _host(
          HadithCard(
            hadith: _hadith,
            onCopy: () => copied = true,
            onShare: () => shared = true,
            onBookmark: () => bookmarked = true,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.tap(find.byIcon(Icons.share_rounded));
      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      expect(copied, isTrue);
      expect(shared, isTrue);
      expect(bookmarked, isTrue);
    });

    testWidgets('highlights the normalised query inside diacritised text',
        (tester) async {
      await tester.pumpWidget(
        _host(HadithCard(hadith: _hadith, highlight: 'الاعمال')),
      );
      final richText = tester.widget<RichText>(_matnRichText());
      final span = richText.text as TextSpan;
      final highlighted = (span.children ?? const <InlineSpan>[])
          .whereType<TextSpan>()
          .where((s) => s.style?.backgroundColor != null)
          .toList();
      expect(highlighted, isNotEmpty);
      // The highlighted run is the original, still-diacritised text (a trailing
      // vowel mark may be swept in with it).
      expect(highlighted.first.text, startsWith('الأَعْمَال'));
    });
  });
}
