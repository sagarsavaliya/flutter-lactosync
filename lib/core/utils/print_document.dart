import 'print_document_stub.dart'
    if (dart.library.html) 'print_document_web.dart' as impl;

Future<void> printDocument(String text, {String title = 'Document'}) {
  return impl.printDocument(text, title: title);
}
