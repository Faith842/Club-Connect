import 'package:flutter_test/flutter_test.dart';
import 'package:club_hub/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ClubConnectApp());
    await tester.pump();
    expect(find.byType(ClubConnectApp), findsOneWidget);
  });
}
