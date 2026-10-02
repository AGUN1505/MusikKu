import 'package:flutter_test/flutter_test.dart';
import 'package:musikku/app.dart';

void main() {
  testWidgets('MusikKu smoke test renders home', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MusikKuApp());

    // Verify that the title MusikKu renders
    expect(find.text('MusikKu'), findsOneWidget);
  });
}
