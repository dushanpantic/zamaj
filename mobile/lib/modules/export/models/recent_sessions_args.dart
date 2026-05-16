import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_sessions_args.freezed.dart';

/// Arguments for the recent-sessions / export screen, scoped to one program.
@freezed
abstract class RecentSessionsArgs with _$RecentSessionsArgs {
  const factory RecentSessionsArgs({required String programId}) =
      _RecentSessionsArgs;
}
