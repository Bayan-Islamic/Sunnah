part of 'chapters_cubit.dart';

enum ChaptersStatus { initial, loading, success, failure }

/// State of the chapter index for one collection.
class ChaptersState extends Equatable {
  const ChaptersState({
    this.status = ChaptersStatus.initial,
    this.chapters = const <Chapter>[],
    this.authenticOnly = false,
    this.errorMessage,
  });

  final ChaptersStatus status;
  final List<Chapter> chapters;

  /// The filter the currently-held [chapters] were loaded with.
  final bool authenticOnly;
  final String? errorMessage;

  ChaptersState copyWith({
    ChaptersStatus? status,
    List<Chapter>? chapters,
    bool? authenticOnly,
    String? errorMessage,
  }) =>
      ChaptersState(
        status: status ?? this.status,
        chapters: chapters ?? this.chapters,
        authenticOnly: authenticOnly ?? this.authenticOnly,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, chapters, authenticOnly, errorMessage];
}
