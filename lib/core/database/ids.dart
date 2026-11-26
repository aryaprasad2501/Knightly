import 'dart:math';

final _random = Random.secure();

/// A random RFC 4122 version-4 UUID, e.g. `3f2c9a1e-6b0d-4c2e-9a7f-1d2e3c4b5a69`.
///
/// Every syncable row carries one in its `uuid` column: local integer ids stay
/// the primary key (fast joins, existing code), while the uuid identifies the
/// record across devices, backups and a future optional sync.
String newUuid() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// The same format as [newUuid], generated inside SQLite. Used by migrations
/// to give rows that existed before the `uuid` column one of their own.
const sqlNewUuid =
    "lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || "
    "substr(lower(hex(randomblob(2))), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || "
    "substr(lower(hex(randomblob(2))), 2) || '-' || lower(hex(randomblob(6)))";

/// A UUID in the canonical 8-4-4-4-12 lowercase hex form.
final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
