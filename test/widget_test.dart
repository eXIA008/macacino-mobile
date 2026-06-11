import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_macacino/main.dart';

void main() {
  testWidgets('App compiles smoke test', (WidgetTester tester) async {
    // Basic test to verify compilation
    await tester.pumpWidget(const MacacinoApp());
    expect(true, true);
  });
}
