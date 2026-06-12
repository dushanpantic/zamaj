import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

sealed class LinkSuggestionState extends Equatable {
  const LinkSuggestionState();
}

final class LinkSuggestionInitial extends LinkSuggestionState {
  const LinkSuggestionInitial();

  @override
  List<Object?> get props => [];
}

final class LinkSuggestionLoading extends LinkSuggestionState {
  const LinkSuggestionLoading();

  @override
  List<Object?> get props => [];
}

final class LinkSuggestionLoaded extends LinkSuggestionState {
  const LinkSuggestionLoaded({
    required this.clusters,
    required this.dismissedNormalizedNames,
    this.applyingNormalizedName,
    this.lastError,
  });

  final List<LinkSuggestionCluster> clusters;

  /// Names the user has either skipped or successfully linked this session.
  /// Removed from the visible list so they don't keep reappearing while the
  /// user works through the queue.
  final Set<String> dismissedNormalizedNames;

  /// Cluster currently being applied; renders a spinner in its action area.
  final String? applyingNormalizedName;

  final DomainError? lastError;

  List<LinkSuggestionCluster> get visibleClusters => clusters
      .where((c) => !dismissedNormalizedNames.contains(c.normalizedName))
      .toList();

  LinkSuggestionLoaded copyWith({
    List<LinkSuggestionCluster>? clusters,
    Set<String>? dismissedNormalizedNames,
    String? Function()? applyingNormalizedName,
    DomainError? Function()? lastError,
  }) {
    return LinkSuggestionLoaded(
      clusters: clusters ?? this.clusters,
      dismissedNormalizedNames:
          dismissedNormalizedNames ?? this.dismissedNormalizedNames,
      applyingNormalizedName: applyingNormalizedName != null
          ? applyingNormalizedName()
          : this.applyingNormalizedName,
      lastError: lastError != null ? lastError() : this.lastError,
    );
  }

  @override
  List<Object?> get props => [
    clusters,
    dismissedNormalizedNames,
    applyingNormalizedName,
    lastError,
  ];
}

final class LinkSuggestionFailure extends LinkSuggestionState {
  const LinkSuggestionFailure({required this.error});

  final DomainError error;

  @override
  List<Object?> get props => [error];
}
