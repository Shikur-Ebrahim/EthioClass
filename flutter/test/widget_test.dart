import 'package:flutter_test/flutter_test.dart';
import 'package:ethioclass/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EthioClassApp());
    expect(find.text('EthioClass'), findsOneWidget);
  });
}
