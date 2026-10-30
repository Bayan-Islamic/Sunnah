import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/hadith.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../bookmarks/data/bookmarks_repository.dart';
import '../../data/search_repository.dart';

part 'search_state.dart';

/// Runs normalised full-text search over the hadith corpus.
///
/// The query is debounced by the widget layer; this cubit only guards against
/// out-of-order results by tracking the latest issued query.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repository, this._bookmarks) : super(const SearchState());

  final SearchRepository _repository;
  final BookmarksRepository _bookmarks;

  int _sequence = 0;

  /// Searches for [rawQuery], optionally scoped to a collection.
  Future<void> search(
    String rawQuery, {
    int? bookId,
    bool authenticOnly = false,
  }) async {
    final normalized = ArabicNormalizer.normalizeQuery(rawQuery);
    if (normalized == null) {
      emit(const SearchState());
      return;
    }
    final token = ++_sequence;
    emit(
      state.copyWith(
        status: SearchStatus.loading,
        query: rawQuery,
        authenticOnly: authenticOnly,
      ),
    );
    try {
      final results = await _repository.search(
        rawQuery,
        bookId: bookId,
        authenticOnly: authenticOnly,
      );
      if (token != _sequence) {
        return; // A newer query superseded this one.
      }
      emit(
        state.copyWith(
          status: SearchStatus.success,
          results: _withBookmarks(results),
          query: rawQuery,
          authenticOnly: authenticOnly,
        ),
      );
    } catch (error) {
      if (token != _sequence) {
        return;
      }
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void clear() {
    _sequence++;
    emit(const SearchState());
  }

  /// Adds or removes [hadith] from the saved list and updates its flag.
  Future<void> toggleBookmark(Hadith hadith) async {
    final updated = await _bookmarks.toggle(hadith.id, _bookmarks.load());
    emit(
      state.copyWith(
        results: [
          for (final item in state.results)
            item.id == hadith.id
                ? item.copyWith(isBookmarked: updated.contains(hadith.id))
                : item,
        ],
      ),
    );
  }

  List<Hadith> _withBookmarks(List<Hadith> results) {
    final ids = _bookmarks.load();
    return [
      for (final hadith in results)
        hadith.copyWith(isBookmarked: ids.contains(hadith.id)),
    ];
  }
}
