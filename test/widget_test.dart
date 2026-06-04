import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lactosync/main.dart';

void main() {
  testWidgets('App renders showcase page', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LactoSyncApp()));
    await tester.pumpAndSettle();
    expect(find.text('Design Showcase'), findsOneWidget);
  });
}
