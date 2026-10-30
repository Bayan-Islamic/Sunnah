part of 'books_cubit.dart';

enum BooksStatus { initial, loading, success, failure }

/// State of the collection list.
class BooksState extends Equatable {
  const BooksState({
    this.status = BooksStatus.initial,
    this.books = const <Book>[],
    this.errorMessage,
  });

  final BooksStatus status;
  final List<Book> books;
  final String? errorMessage;

  BooksState copyWith({
    BooksStatus? status,
    List<Book>? books,
    String? errorMessage,
  }) =>
      BooksState(
        status: status ?? this.status,
        books: books ?? this.books,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, books, errorMessage];
}
