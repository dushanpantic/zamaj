import 'package:zamaj/core/deserialization.dart';

/// Where a library exercise originated.
///
/// [user] entries are created by the user; [canonicalSeed] entries ship
/// embedded with the app and are inserted by the idempotent seeding step.
/// Kept as informational metadata to distinguish seeded rows from later
/// user additions.
enum LibrarySource {
  user,
  canonicalSeed;

  String toJson() => name;

  static LibrarySource fromJson(String json) =>
      decodeEnum(LibrarySource.values, json, 'LibrarySource');
}
