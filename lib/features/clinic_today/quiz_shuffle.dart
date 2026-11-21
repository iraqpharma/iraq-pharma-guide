/// خلط خيارات السؤال.
///
/// بيانات الأسئلة فيها انحياز منهجي في موقع الإجابة الصحيحة: أسئلة
/// الحالات السريرية كلها إجابتها الخيار الأول، وأسئلة التخزين كلها
/// الثاني، وأغلب أسئلة المذيبات الثالث. من يحفظ الموقع يجيب بلا تفكير،
/// فتضيع فائدة السؤال.
///
/// الخلط ثابت لكل سؤال (مشتقّ من معرّفه لا من العشوائية الحيّة)، فالسؤال
/// نفسه يظهر بالترتيب نفسه لكل المستخدمين وفي كل مرة — فلا يربك من يعود
/// إليه — لكنه لم يعد مرتبطاً بموقع ثابت.
class ShuffledQuestion {
  final List<String> options;
  final int answer;
  const ShuffledQuestion(this.options, this.answer);
}

/// مولّد أرقام شبه عشوائي ثابت البذرة (xorshift32) — لا نستعمل Random
/// لأن تسلسله غير مضمون الثبات بين إصدارات دارت.
int _next(int state) {
  var x = state & 0x7FFFFFFF;
  if (x == 0) x = 0x1A2B3C4D;
  x ^= (x << 13) & 0x7FFFFFFF;
  x ^= x >> 17;
  x ^= (x << 5) & 0x7FFFFFFF;
  return x & 0x7FFFFFFF;
}

int _seedOf(String key) {
  var h = 2166136261;
  for (final c in key.codeUnits) {
    h = (h ^ c) & 0x7FFFFFFF;
    h = (h * 16777619) & 0x7FFFFFFF;
  }
  return h == 0 ? 1 : h;
}

ShuffledQuestion shuffleOptions(
  String questionKey,
  List<String> options,
  int answerIndex,
) {
  if (options.length < 2) return ShuffledQuestion(options, answerIndex);

  final idx = List<int>.generate(options.length, (i) => i);
  var s = _seedOf(questionKey);

  // Fisher-Yates بالبذرة الثابتة
  for (var i = idx.length - 1; i > 0; i--) {
    s = _next(s);
    final j = s % (i + 1);
    final t = idx[i];
    idx[i] = idx[j];
    idx[j] = t;
  }

  final shuffled = [for (final i in idx) options[i]];
  var newAnswer = idx.indexOf(answerIndex);
  if (newAnswer < 0) newAnswer = 0;
  return ShuffledQuestion(shuffled, newAnswer);
}
