import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

class StorageRepository {
  final SupabaseClient _client;
  StorageRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Upload trade screenshot. Returns the public/signed URL.
  Future<String> uploadScreenshot({
    required String tradeId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final path = '$_userId/$tradeId/$fileName';
    await _client.storage
        .from(SupabaseConfig.screenshotBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    // Create a signed URL valid for 1 hour
    final signedUrl = await _client.storage
        .from(SupabaseConfig.screenshotBucket)
        .createSignedUrl(path, 3600);
    return signedUrl;
  }

  /// Delete screenshot for a trade.
  Future<void> deleteScreenshot(String tradeId, String fileName) async {
    final path = '$_userId/$tradeId/$fileName';
    await _client.storage.from(SupabaseConfig.screenshotBucket).remove([path]);
  }

  /// Generate a fresh signed URL (call when old one expires).
  Future<String> refreshSignedUrl(String path) async {
    return _client.storage
        .from(SupabaseConfig.screenshotBucket)
        .createSignedUrl(path, 3600);
  }
}
