// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation — bypasses the printing plugin entirely.
/// Creates a PDF Blob, builds a temporary anchor element, and triggers a
/// browser download. No native channel involved, so no MissingPluginException.
Future<void> webDownloadPdf(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
