import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/dependency_scope.dart';
import '../../../../core/models/hadith.dart';
import '../../../../core/settings/cubit/settings_cubit.dart';
import '../../../../core/utils/hadith_formatter.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../hadith_reader/presentation/widgets/hadith_card.dart';
import '../cubit/bookmarks_cubit.dart';

/// The reader's saved hadiths, stored locally in preferences.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookmarksCubit>(
      create: (_) => BookmarksCubit(context.deps.bookmarks, context.deps.hadiths)
        ..load(),
      child: const _BookmarksView(),
    );
  }
}

class _BookmarksView extends StatelessWidget {
  const _BookmarksView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks · المفضلة')),
      body: BlocBuilder<BookmarksCubit, BookmarksState>(
        builder: (context, state) {
          switch (state.status) {
            case BookmarksStatus.initial:
            case BookmarksStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case BookmarksStatus.failure:
              return StatusView(
                icon: Icons.error_outline_rounded,
                message: 'Could not load bookmarks',
                detail: state.errorMessage,
                onRetry: () => context.read<BookmarksCubit>().load(),
              );
            case BookmarksStatus.success:
              if (state.hadiths.isEmpty) {
                return const StatusView(
                  icon: Icons.bookmark_border_rounded,
                  message: 'No saved hadiths yet',
                  detail: 'Tap the bookmark icon on any hadith to save it here.',
                );
              }
              return _list(context, state);
          }
        },
      ),
    );
  }

  Widget _list(BuildContext context, BookmarksState state) {
    final scale = context.select<SettingsCubit, double>(
      (cubit) => cubit.state.arabicFontScale,
    );
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: state.hadiths.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final hadith = state.hadiths[index];
        return HadithCard(
          hadith: hadith,
          arabicFontScale: scale,
          showBookName: true,
          onBookmark: () => context.read<BookmarksCubit>().remove(hadith),
          onCopy: () => _copy(context, hadith),
          onShare: () => SharePlus.instance.share(
            ShareParams(text: HadithFormatter.toPlainText(hadith)),
          ),
        );
      },
    );
  }

  Future<void> _copy(BuildContext context, Hadith hadith) async {
    await Clipboard.setData(
      ClipboardData(text: HadithFormatter.toPlainText(hadith)),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hadith copied')),
      );
    }
  }
}
