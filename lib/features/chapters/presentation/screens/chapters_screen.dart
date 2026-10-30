import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/dependency_scope.dart';
import '../../../../core/models/book.dart';
import '../../../../core/settings/cubit/settings_cubit.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../hadith_reader/presentation/screens/hadith_reader_screen.dart';
import '../cubit/chapters_cubit.dart';

/// The chapter (*kitab*) index for one collection.
class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final authenticOnly = context.select<SettingsCubit, bool>(
      (cubit) => cubit.state.showAuthenticOnly,
    );
    return BlocProvider<ChaptersCubit>(
      create: (_) => ChaptersCubit(
        context.deps.chapters,
        bookId: book.id,
      )..load(authenticOnly: authenticOnly),
      child: _ChaptersView(book: book),
    );
  }
}

class _ChaptersView extends StatelessWidget {
  const _ChaptersView({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    // Reload whenever the shared filter changes, so the counts stay honest.
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.showAuthenticOnly != current.showAuthenticOnly,
      listener: (context, state) {
        context.read<ChaptersCubit>().setAuthenticOnly(state.showAuthenticOnly);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(book.nameAr, textDirection: TextDirection.rtl),
        ),
        body: BlocBuilder<ChaptersCubit, ChaptersState>(
          builder: (context, state) {
            switch (state.status) {
              case ChaptersStatus.initial:
              case ChaptersStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ChaptersStatus.failure:
                return StatusView(
                  icon: Icons.error_outline_rounded,
                  message: 'Could not load chapters',
                  detail: state.errorMessage,
                  onRetry: () => context
                      .read<ChaptersCubit>()
                      .load(authenticOnly: state.authenticOnly),
                );
              case ChaptersStatus.success:
                if (state.chapters.isEmpty) {
                  return const StatusView(
                    icon: Icons.menu_book_rounded,
                    message: 'No chapters found',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: state.chapters.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final chapter = state.chapters[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => HadithReaderScreen(
                              bookId: book.id,
                              chapterId: chapter.id,
                              titleAr: chapter.titleAr,
                            ),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          child: Text(
                            '${chapter.chapterNumber}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          chapter.titleAr,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${chapter.titleEn} · ${chapter.hadithCount} hadiths',
                        ),
                      ),
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }
}
