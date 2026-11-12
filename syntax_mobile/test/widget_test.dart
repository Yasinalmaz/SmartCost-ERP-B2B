import 'package:flutter_test/flutter_test.dart';

import 'package:syntax_mobile/main.dart';

void main() {
  testWidgets('Giriş ekranı açılır', (tester) async {
    await tester.pumpWidget(const SmartCostUygulamasi());
    expect(find.text('Giriş Yap'), findsOneWidget);
  });
}
