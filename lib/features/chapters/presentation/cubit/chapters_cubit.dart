import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/chapter.dart';
import '../../data/chapters_repository.dart';

part 'chapters_state.dart';

/// Loads the chapters of one collection, honouring the authenticity filter so
/// the per-chapter counts match what the reader will actually show.
class ChaptersCubit extends Cubit<ChaptersState> {
  ChaptersCubit(this._repository, {required this.bookId})
      : super(const ChaptersState());

  final ChaptersRepository _repository;
  final int bookId;

  Future<void> load({bool authenticOnly = false}) async {
    emit(
      state.copyWith(
        status: ChaptersStatus.loading,
        authenticOnly: authenticOnly,
      ),
    );
    try {
      final chapters = await _repository.fetchChapters(
        bookId,
        authenticOnly: authenticOnly,
      );
      emit(
        state.copyWith(
          status: ChaptersStatus.success,
          chapters: chapters,
          authenticOnly: authenticOnly,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ChaptersStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Re-queries when the authenticity filter changes.
  Future<void> setAuthenticOnly(bool value) {
    if (value == state.authenticOnly) {
      return Future<void>.value();
    }
    return load(authenticOnly: value);
  }
}
