import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/en_dict.dart';

/// ترجمة نص عربي ثابت إلى الإنجليزية حين تكون لغة التطبيق إنجليزية.
/// النص غير الموجود في القاموس يبقى كما هو.
String trS(BuildContext context, String ar) =>
    context.s.isAr ? ar : (kEnDict[ar] ?? ar);

/// مثل [trS] لكن يقبل null (حقول اختيارية مثل hintText).
String? trN(BuildContext context, String? ar) =>
    ar == null ? null : trS(context, ar);

/// بديل مطابق لـ [Text] يمرّ نصّه على [trS].
///
/// الشاشات التي نصوصها جداول ثابتة (const) بالعربية تستعمله بدل Text،
/// فتُترجم عند العرض دون تغيير بنية البيانات ولا فقدان const.
class TText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const TText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  @override
  Widget build(BuildContext context) => Text(
        trS(context, data),
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );
}
