DateTime msToUtc(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
int utcToMs(DateTime dt) => dt.millisecondsSinceEpoch;
int? utcToMsNullable(DateTime? dt) => dt?.millisecondsSinceEpoch;
