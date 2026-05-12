import 'package:clock/clock.dart';

class TimestampOracle {
  const TimestampOracle(this._clock);

  final Clock _clock;

  DateTime nextUpdatedAt({
    required DateTime? previousUpdatedAt,
    required DateTime createdAt,
  }) {
    final now = _clock.now().toUtc();
    final flooredByPrevious = previousUpdatedAt == null
        ? now
        : (now.isAfter(previousUpdatedAt)
              ? now
              : previousUpdatedAt.add(const Duration(milliseconds: 1)));
    return flooredByPrevious.isAfter(createdAt) ? flooredByPrevious : createdAt;
  }
}
