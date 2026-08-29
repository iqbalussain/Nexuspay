import 'dart:math';

/// Generates RFC-4122-shaped v4 UUIDs without pulling in the `uuid` package,
/// so this module has zero pub.dev dependencies. Swap for `package:uuid`
/// in the real app if preferred — nothing in the domain layer cares which
/// generator produced the id, only that ids are stable strings.
class IdGenerator {
  static final Random _random = Random.secure();

  static String newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
