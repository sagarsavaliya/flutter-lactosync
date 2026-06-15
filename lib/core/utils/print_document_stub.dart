import 'package:share_plus/share_plus.dart';

Future<void> printDocument(String text, {String title = 'Document'}) async {
  await Share.share(text, subject: title);
}
