import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/hadith.dart';
import '../../../hadith_reader/data/hadith_repository.dart';
import '../../data/bookmarks_repository.dart';

part 'bookmarks_state.dart';

/// Loads the hadiths the reader has bookmarked.
///
/// Only the ids are persisted; the hadith bodies are re-read from the offline
/// database so no content is duplicated in preferences.
class BookmarksCubit extends Cubit<BookmarksState> {
  BookmarksCubit(this._repository, this._hadiths)
      : super(const BookmarksState());

  final BookmarksRepository _repository;
  final HadithRepository _hadiths;

  Future<void> load() async {
    emit(state.copyWith(status: BookmarksStatus.loading));
    try {
      final ids = _repository.load();
      final hadiths = await _hadiths.fetchByIds(ids);
      emit(
        state.copyWith(
          status: BookmarksStatus.success,
          hadiths: [
            for (final hadith in hadiths) hadith.copyWith(isBookmarked: true),
          ],
          ids: ids,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: BookmarksStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Removes [hadith] from the saved list.
  Future<void> remove(Hadith hadith) async {
    final updated = await _repository.toggle(hadith.id, state.ids);
    emit(
      state.copyWith(
        ids: updated,
        hadiths: [
          for (final item in state.hadiths)
            if (item.id != hadith.id) item,
        ],
      ),
    );
  }
}
