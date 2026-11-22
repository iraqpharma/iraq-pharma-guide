import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';

/// روابط صفحة التطبيق في المتجرين — مصدر واحد لكل الشاشات.
///
/// كانت نوافذ التحديث تفتح رابط Google Play بمعرّف حزمة خاطئ حتى على
/// الآيفون، فيضغط المستخدم «تحديث الآن» ولا يصل إلى شيء.
class StoreLinks {
  StoreLinks._();

  static const appStoreId     = '6800479716';
  static const androidPackage = 'com.iraqpharmaguide.app';

  static const appStore  = 'https://apps.apple.com/app/id$appStoreId';
  static const playStore =
      'https://play.google.com/store/apps/details?id=$androidPackage';

  static String get forThisPlatform => Platform.isIOS ? appStore : playStore;

  /// يفتح صفحة التطبيق في متجر هذا الجهاز. [override] رابط من السيرفر
  /// (إن وُجد وكان صالحاً) يُقدَّم على الرابط المبني في التطبيق.
  static Future<bool> open({String? override}) async {
    final candidates = <String>[
      if (override != null && override.trim().startsWith('http'))
        override.trim(),
      // على أندرويد نفتح تطبيق المتجر مباشرة إن أمكن.
      if (Platform.isAndroid) 'market://details?id=$androidPackage',
      forThisPlatform,
    ];
    for (final c in candidates) {
      try {
        final ok = await launchUrl(Uri.parse(c),
            mode: LaunchMode.externalApplication);
        if (ok) return true;
      } catch (_) {/* نجرّب التالي */}
    }
    return false;
  }
}
