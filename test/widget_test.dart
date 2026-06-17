import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kozag/main.dart'; // Senin projenin adıyla eşleşen kısım

void main() {
  testWidgets('Açılış ekranı test ediliyor', (WidgetTester tester) async {
    // Uygulamamızı (KozagApp) inşa et ve tetikle.
    await tester.pumpWidget(const KozagApp());

    // Ekranda 'Kozağ' yazısının bulunduğunu doğrula.
    expect(find.text('Kozağ'), findsOneWidget);
  });
}