import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/hadith.dart';
import '../../../bookmarks/data/bookmarks_repository.dart';
import '../../data/hadith_repository.dart';

part 'hadith_reader_state.dart';

/// Drives the hadith feed for a collection or a single chapter.
///
/// Holds the authenticity filter, so toggling "Sahih & Hasan only" re-queries
/// the database instead of filtering in the widget tree. Bookmark flags are
/// merged into the loaded rows.
class HadithReaderCubit extends Cubit<HadithReaderState> {
  HadithReaderCubit(
    this._repository,
    this._bookmarks, {
    this.bookId,
    this.chapterId,
  }) : super(const HadithReaderState());

  final HadithRepository _repository;
  final BookmarksRepository _bookmarks;
  final int? bookId;
  final int? chapterId;

  Future<void> load({bool? authenticOnly}) async {
    final filter = authenticOnly ?? state.authenticOnly;
    emit(state.copyWith(status: HadithReaderStatus.loading, authenticOnly: filter));
    try {
      final hadiths = await _repository.fetchHadiths(
        bookId: bookId,
        chapterId: chapterId,
        authenticOnly: filter,
      );
      emit(
        state.copyWith(
          status: HadithReaderStatus.success,
          hadiths: _withBookmarks(hadiths),
          authenticOnly: filter,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HadithReaderStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Turns the "Sahih & Hasan only" filter on or off and reloads.
  Future<void> setAuthenticOnly(bool value) => load(authenticOnly: value);

  Future<void> toggleBookmark(Hadith hadith) async {
    final updated = await _bookmarks.toggle(hadith.id, _bookmarkIds());
    emit(
      state.copyWith(
        hadiths: [
          for (final item in state.hadiths)
            item.id == hadith.id
                ? item.copyWith(isBookmarked: updated.contains(hadith.id))
                : item,
        ],
      ),
    );
  }

  List<Hadith> _withBookmarks(List<Hadith> hadiths) {
    final ids = _bookmarkIds();
    return [
      for (final hadith in hadiths)
        hadith.copyWith(isBookmarked: ids.contains(hadith.id)),
    ];
  }

  List<int> _bookmarkIds() => _bookmarks.load();
}
