// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> printDocument(String text, {String title = 'Document'}) async {
  final escaped = text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  final escapedTitle = title
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  final htmlContent = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>$escapedTitle</title>
    <style>
      body { font-family: Arial, sans-serif; padding: 24px; color: #1E2A1E; }
      pre { white-space: pre-wrap; font-size: 14px; line-height: 1.5; }
    </style>
    <script>
      window.addEventListener('load', function () {
        window.focus();
        window.print();
      });
    </script>
  </head>
  <body><pre>$escaped</pre></body>
</html>
''';

  final iframe = html.IFrameElement()
    ..style.position = 'fixed'
    ..style.right = '0'
    ..style.bottom = '0'
    ..style.width = '0'
    ..style.height = '0'
    ..style.border = '0'
    ..srcdoc = htmlContent;

  html.document.body?.append(iframe);

  await Future<void>.delayed(const Duration(milliseconds: 800));

  final frameWindow = iframe.contentWindow;
  if (frameWindow is html.Window) {
    frameWindow.print();
  }

  await Future<void>.delayed(const Duration(seconds: 1));
  iframe.remove();
}
