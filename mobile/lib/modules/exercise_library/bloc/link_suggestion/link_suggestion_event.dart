import 'package:equatable/equatable.dart';

sealed class LinkSuggestionEvent extends Equatable {
  const LinkSuggestionEvent();
}

final class LinkSuggestionRequested extends LinkSuggestionEvent {
  const LinkSuggestionRequested();

  @override
  List<Object?> get props => [];
}

final class LinkSuggestionRetryRequested extends LinkSuggestionEvent {
  const LinkSuggestionRetryRequested();

  @override
  List<Object?> get props => [];
}

final class LinkSuggestionClusterAccepted extends LinkSuggestionEvent {
  const LinkSuggestionClusterAccepted({required this.normalizedName});

  final String normalizedName;

  @override
  List<Object?> get props => [normalizedName];
}

final class LinkSuggestionClusterSkipped extends LinkSuggestionEvent {
  const LinkSuggestionClusterSkipped({required this.normalizedName});

  final String normalizedName;

  @override
  List<Object?> get props => [normalizedName];
}
