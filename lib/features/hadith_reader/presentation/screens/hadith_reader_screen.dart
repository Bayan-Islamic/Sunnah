import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/dependency_scope.dart';
import '../../../../core/models/hadith.dart';
import '../../../../core/settings/cubit/settings_cubit.dart';
import '../../../../core/utils/hadith_formatter.dart';
import '../../../../core/widgets/status_view.dart';
import '../cubit/hadith_reader_cubit.dart';
import '../widgets/hadith_card.dart';

/// The hadith feed for a collection or a single chapter.
///
/// The AppBar carries the persistent "Sahih & Hasan only" toggle, so a reader
/// can hide weak narrations without leaving the page.
class HadithReaderScreen extends StatelessWidget {
  const HadithReaderScreen({
    super.key,
    this.bookId,
    this.chapterId,
    this.titleAr = 'الأحاديث',
  });

  final int? bookId;
  final int? chapterId;
  final String titleAr;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsCubit>();
    return BlocProvider<HadithReaderCubit>(
      create: (_) => HadithReaderCubit(
        context.deps.hadiths,
        context.deps.bookmarks,
        bookId: bookId,
        chapterId: chapterId,
      )..load(authenticOnly: settings.state.showAuthenticOnly),
      child: _HadithReaderView(titleAr: titleAr),
    );
  }
}

class _HadithReaderView extends StatelessWidget {
  const _HadithReaderView({required this.titleAr});

  final String titleAr;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.showAuthenticOnly != current.showAuthenticOnly,
      listener: (context, state) {
        context
            .read<HadithReaderCubit>()
            .setAuthenticOnly(state.showAuthenticOnly);
      },
      child: BlocBuilder<HadithReaderCubit, HadithReaderState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(titleAr, textDirection: TextDirection.rtl),
              actions: [_AuthenticFilterToggle(active: state.authenticOnly)],
            ),
            body: _body(context, state),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, HadithReaderState state) {
    switch (state.status) {
      case HadithReaderStatus.initial:
      case HadithReaderStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case HadithReaderStatus.failure:
        return StatusView(
          icon: Icons.error_outline_rounded,
          message: 'Could not load hadiths',
          detail: state.errorMessage,
          onRetry: () => context.read<HadithReaderCubit>().load(),
        );
      case HadithReaderStatus.success:
        if (state.hadiths.isEmpty) {
          return StatusView(
            icon: Icons.filter_alt_off_rounded,
            message: state.authenticOnly
                ? 'No authentic hadiths in this section'
                : 'No hadiths found',
            detail: state.authenticOnly
                ? 'Turn off "Sahih & Hasan only" to include weak narrations.'
                : null,
          );
        }
        return _list(context, state);
    }
  }

  Widget _list(BuildContext context, HadithReaderState state) {
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
          onBookmark: () =>
              context.read<HadithReaderCubit>().toggleBookmark(hadith),
          onCopy: () => _copy(context, hadith),
          onShare: () => _share(hadith),
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

  Future<void> _share(Hadith hadith) async {
    await SharePlus.instance.share(
      ShareParams(text: HadithFormatter.toPlainText(hadith)),
    );
  }
}

/// AppBar action toggling the authenticity filter.
class _AuthenticFilterToggle extends StatelessWidget {
  const _AuthenticFilterToggle({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: active ? 'Showing Sahih & Hasan only' : 'Showing all hadiths',
      onPressed: () => context
          .read<SettingsCubit>()
          .setShowAuthenticOnly(!active),
      icon: Icon(
        active ? Icons.verified_rounded : Icons.verified_outlined,
      ),
    );
  }
}
