import 'dart:typed_data';

/// Stub for native platforms (Android, iOS, Desktop).
/// On native, PDFs are handled by the [printing] package — this is a no-op.
Future<void> webDownloadPdf(Uint8List bytes, String filename) async {}
