part of 'bookmarks_cubit.dart';

enum BookmarksStatus { initial, loading, success, failure }

/// State of the saved-hadith list.
class BookmarksState extends Equatable {
  const BookmarksState({
    this.status = BookmarksStatus.initial,
    this.hadiths = const <Hadith>[],
    this.ids = const <int>[],
    this.errorMessage,
  });

  final BookmarksStatus status;
  final List<Hadith> hadiths;
  final List<int> ids;
  final String? errorMessage;

  bool get isEmpty => hadiths.isEmpty;

  BookmarksState copyWith({
    BookmarksStatus? status,
    List<Hadith>? hadiths,
    List<int>? ids,
    String? errorMessage,
  }) =>
      BookmarksState(
        status: status ?? this.status,
        hadiths: hadiths ?? this.hadiths,
        ids: ids ?? this.ids,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, hadiths, ids, errorMessage];
}
