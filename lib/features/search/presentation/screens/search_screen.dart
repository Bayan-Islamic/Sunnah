import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/dependency_scope.dart';
import '../../../../core/models/hadith.dart';
import '../../../../core/settings/cubit/settings_cubit.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../../core/utils/hadith_formatter.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../hadith_reader/presentation/widgets/hadith_card.dart';
import '../cubit/search_cubit.dart';

/// Full-text search over the hadith corpus.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (_) => SearchCubit(context.deps.search, context.deps.bookmarks),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Debounces input so a fast typist does not fire a query per keystroke.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      final authenticOnly =
          context.read<SettingsCubit>().state.showAuthenticOnly;
      context.read<SearchCubit>().search(value, authenticOnly: authenticOnly);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.showAuthenticOnly != current.showAuthenticOnly,
      listener: (context, state) {
        final query = context.read<SearchCubit>().state.query;
        if (query.isNotEmpty) {
          context
              .read<SearchCubit>()
              .search(query, authenticOnly: state.showAuthenticOnly);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search · بحث'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textDirection: TextDirection.rtl,
                onChanged: _onChanged,
                onSubmitted: (value) {
                  final authenticOnly =
                      context.read<SettingsCubit>().state.showAuthenticOnly;
                  context
                      .read<SearchCubit>()
                      .search(value, authenticOnly: authenticOnly);
                },
                decoration: InputDecoration(
                  hintText: 'ابحث في المتون…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _controller.clear();
                            context.read<SearchCubit>().clear();
                            setState(() {});
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) => _results(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _results(BuildContext context, SearchState state) {
    switch (state.status) {
      case SearchStatus.initial:
        return const StatusView(
          icon: Icons.search_rounded,
          message: 'Search across every collection',
          detail: 'Diacritics and letter variants are ignored automatically.',
        );
      case SearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchStatus.failure:
        return StatusView(
          icon: Icons.error_outline_rounded,
          message: 'Search failed',
          detail: state.errorMessage,
        );
      case SearchStatus.success:
        if (state.results.isEmpty) {
          return const StatusView(
            icon: Icons.search_off_rounded,
            message: 'No matching hadiths',
          );
        }
        return _list(context, state);
    }
  }

  Widget _list(BuildContext context, SearchState state) {
    final scale = context.select<SettingsCubit, double>(
      (cubit) => cubit.state.arabicFontScale,
    );
    final highlight = ArabicNormalizer.normalize(state.query);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: state.results.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${state.results.length} result(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        final hadith = state.results[index - 1];
        return HadithCard(
          hadith: hadith,
          arabicFontScale: scale,
          showBookName: true,
          highlight: highlight,
          onCopy: () => _copy(context, hadith),
          onShare: () => SharePlus.instance.share(
            ShareParams(text: HadithFormatter.toPlainText(hadith)),
          ),
          onBookmark: () => context.read<SearchCubit>().toggleBookmark(hadith),
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
