import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A file the user picked in the system file picker.
class PickedDocument {
  const PickedDocument({required this.bytes, this.name});

  final Uint8List bytes;

  /// Display name, e.g. "knightly-backup-2026-11-26-1830.json", when known.
  final String? name;
}

/// Why a document could not be saved or opened. [message] is user-facing.
class DocumentException implements Exception {
  const DocumentException(this.message);

  final String message;

  @override
  String toString() => 'DocumentException: $message';
}

/// Saving and opening user-chosen files through Android's system file picker
/// (Storage Access Framework, see `MainActivity.kt`). No storage permission,
/// no network: the user decides where the file lives.
class DocumentFiles {
  const DocumentFiles([this._channel = const MethodChannel('knightly/documents')]);

  final MethodChannel _channel;

  /// Lets the user choose where to save [bytes] as [name]. Returns the saved
  /// file's display name, or null if they closed the picker.
  Future<String?> save(String name, Uint8List bytes, {String mimeType = 'application/json'}) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('save', {
        'name': name,
        'bytes': bytes,
        'mimeType': mimeType,
      });
      if (result == null) return null;
      return result['name'] as String? ?? name;
    } on PlatformException catch (e) {
      throw DocumentException(_message(e));
    } on MissingPluginException {
      throw const DocumentException('Saving files is not available on this device.');
    }
  }

  /// Lets the user pick a file to open. Returns null if they closed the picker.
  Future<PickedDocument?> open() async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('open');
      if (result == null) return null;
      return PickedDocument(bytes: result['bytes']! as Uint8List, name: result['name'] as String?);
    } on PlatformException catch (e) {
      throw DocumentException(_message(e));
    } on MissingPluginException {
      throw const DocumentException('Opening files is not available on this device.');
    }
  }

  static String _message(PlatformException e) => switch (e.code) {
    'too_large' => 'That file is too large to be a Knightly backup.',
    'busy' => 'A file window is already open.',
    _ => 'The file could not be read or written. Try another location.',
  };
}

/// Overridden in tests with a fake.
final documentFilesProvider = Provider<DocumentFiles>((ref) => const DocumentFiles());
