import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_bike_app/main.dart';

void main() {
  testWidgets('Smart Bike App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartBikeApp(),
      ),
    );
    expect(find.text('SMART BIKE MONITOR'), findsOneWidget);
  });
}
