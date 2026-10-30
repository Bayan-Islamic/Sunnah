import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/book.dart';
import '../../data/books_repository.dart';

part 'books_state.dart';

/// Loads the list of bundled collections.
class BooksCubit extends Cubit<BooksState> {
  BooksCubit(this._repository) : super(const BooksState());

  final BooksRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: BooksStatus.loading));
    try {
      final books = await _repository.fetchBooks();
      emit(state.copyWith(status: BooksStatus.success, books: books));
    } catch (error) {
      emit(
        state.copyWith(
          status: BooksStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
