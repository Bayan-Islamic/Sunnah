part of 'search_cubit.dart';

enum SearchStatus { initial, loading, success, failure }

/// State of the search screen.
class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const <Hadith>[],
    this.authenticOnly = false,
    this.errorMessage,
  });

  final SearchStatus status;
  final String query;
  final List<Hadith> results;
  final bool authenticOnly;
  final String? errorMessage;

  /// True when a search has completed and returned nothing.
  bool get isEmptyResult =>
      status == SearchStatus.success && results.isEmpty && query.isNotEmpty;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Hadith>? results,
    bool? authenticOnly,
    String? errorMessage,
  }) =>
      SearchState(
        status: status ?? this.status,
        query: query ?? this.query,
        results: results ?? this.results,
        authenticOnly: authenticOnly ?? this.authenticOnly,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, query, results, authenticOnly, errorMessage];
}
