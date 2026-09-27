import 'package:flutter_test/flutter_test.dart';
import 'package:swift_finder/main.dart';

void main() {
  testWidgets('renders the SwiftFinder discovery screen', (tester) async {
    await tester.pumpWidget(const SwiftFinderApp());
    expect(find.text('SwiftFinder'), findsOneWidget);
    expect(find.text('Find what matters.'), findsOneWidget);
  });
}
