// يتحقّق أن TText يترجم النص العربي الثابت حين تكون اللغة إنجليزية ويتركه
// كما هو بالعربية، وأن القاموس لا يحوي ترجمة فارغة.
//   flutter test test/en_dict_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iraq_pharma_guide/core/l10n/en_dict.dart';
import 'package:iraq_pharma_guide/shared/widgets/t_text.dart';

Widget _app(String lang) => MaterialApp(
      locale: Locale(lang),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(body: TText('زبائني')),
    );

void main() {
  testWidgets('TText يترجم بالإنجليزية', (t) async {
    await t.pumpWidget(_app('en'));
    await t.pump();
    expect(find.text('My Customers'), findsOneWidget);
  });
  testWidgets('TText يبقى عربياً بالعربية', (t) async {
    await t.pumpWidget(_app('ar'));
    await t.pump();
    expect(find.text('زبائني'), findsOneWidget);
  });
  test('لا ترجمة فارغة في القاموس', () {
    expect(kEnDict.values.where((v) => v.trim().isEmpty), isEmpty);
    expect(kEnDict.length, greaterThan(400));
  });
}
