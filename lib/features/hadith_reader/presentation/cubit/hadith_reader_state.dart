part of 'hadith_reader_cubit.dart';

enum HadithReaderStatus { initial, loading, success, failure }

/// State of the hadith feed.
class HadithReaderState extends Equatable {
  const HadithReaderState({
    this.status = HadithReaderStatus.initial,
    this.hadiths = const <Hadith>[],
    this.authenticOnly = true,
    this.errorMessage,
  });

  final HadithReaderStatus status;
  final List<Hadith> hadiths;

  /// Whether the "Sahih & Hasan only" filter is active.
  final bool authenticOnly;
  final String? errorMessage;

  HadithReaderState copyWith({
    HadithReaderStatus? status,
    List<Hadith>? hadiths,
    bool? authenticOnly,
    String? errorMessage,
  }) =>
      HadithReaderState(
        status: status ?? this.status,
        hadiths: hadiths ?? this.hadiths,
        authenticOnly: authenticOnly ?? this.authenticOnly,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, hadiths, authenticOnly, errorMessage];
}
