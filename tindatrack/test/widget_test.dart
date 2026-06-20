import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/app.dart';

void main() {
  testWidgets('renders the offline starter screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MainApp()));

    expect(find.text('TindaTrack'), findsOneWidget);
    expect(find.text('Offline inventory tracker'), findsOneWidget);
  });
}
