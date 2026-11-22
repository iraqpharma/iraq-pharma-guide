import '../../core/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';

/// لوحة المتصدّرين في «الحاسبة السريعة».
///
/// أعلى عشرة: الأول ذهبي والثاني فضّي والثالث برونزي، والبقية بلون واحد.
/// تتغيّر بتغيّر المدّة (اليوم / الأسبوع / الشهر)، فمن لم يدخل الشهر كله
/// يبقى له أمل في صدارة اليوم.
class Leaderboard extends StatefulWidget {
  /// true داخل بطاقة مستقلة في لوحة «عيادتك اليوم».
  final bool framed;
  const Leaderboard({super.key, this.framed = true});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

enum _Period { day, week, month }

class _LeaderboardState extends State<Leaderboard> {
  _Period _period = _Period.week;
  late Future<List<Map<String, dynamic>>> _future = _load();

  static const _gold   = Color(0xFFD4A017);
  static const _silver = Color(0xFF9AA5B1);
  static const _bronze = Color(0xFFB07A42);

  DateTime get _since {
    final n = DateTime.now();
    switch (_period) {
      case _Period.day:
        return DateTime(n.year, n.month, n.day);
      case _Period.week:
        return n.subtract(const Duration(days: 7));
      case _Period.month:
        return n.subtract(const Duration(days: 30));
    }
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final rows = await Supabase.instance.client
          .from('speed_scores')
          .select('display_name, score, correct, total, user_id')
          .gte('created_at', _since.toUtc().toIso8601String())
          .order('score', ascending: false)
          .limit(60);

      // أفضل نتيجة لكل مستخدم فقط، فلا يحتلّ شخص واحد اللوحة كلها.
      final best = <String, Map<String, dynamic>>{};
      for (final r in (rows as List).cast<Map<String, dynamic>>()) {
        final uid = (r['user_id'] ?? '').toString();
        final cur = best[uid];
        if (cur == null ||
            ((r['score'] ?? 0) as num) > ((cur['score'] ?? 0) as num)) {
          best[uid] = r;
        }
      }
      final list = best.values.toList()
        ..sort((a, b) =>
            ((b['score'] ?? 0) as num).compareTo((a['score'] ?? 0) as num));
      return list.take(10).toList();
    } catch (_) {
      return const [];
    }
  }

  void _setPeriod(_Period p) {
    setState(() {
      _period = p;
      _future = _load();
    });
  }

  Color _medal(int rank) => switch (rank) {
        0 => _gold,
        1 => _silver,
        2 => _bronze,
        _ => const Color(0xFF7D8A97),
      };

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.emoji_events_rounded, size: 19, color: _gold),
          const SizedBox(width: 8),
          Text((context.s.isAr ? 'لوحة المتصدّرين' : 'Leaderboard'),
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh_rounded, size: 17),
          ),
        ]),
        const SizedBox(height: 9),
        Row(children: [
          _tab((context.s.isAr ? 'اليوم' : 'Today'), _Period.day),
          const SizedBox(width: 6),
          _tab((context.s.isAr ? 'الأسبوع' : 'Week'), _Period.week),
          const SizedBox(width: 6),
          _tab((context.s.isAr ? 'الشهر' : 'Month'), _Period.month),
        ]),
        const SizedBox(height: 10),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2)),
                ),
              );
            }
            final rows = snap.data ?? const <Map<String, dynamic>>[];
            if (rows.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(children: [
                  Icon(Icons.bolt_rounded,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        context.s.isAr
                        ? 'لا نتائج في هذه المدّة، كن أول المتصدّرين من الحاسبة السريعة'
                        : 'No scores in this period yet. Be the first from the Speed Calculator',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ]),
              );
            }
            return Column(children: [
              for (var i = 0; i < rows.length; i++) _row(i, rows[i], isDark),
            ]);
          },
        ),
      ],
    );

    if (!widget.framed) return body;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFECEFF2)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: _gold.withOpacity(0.14),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: body,
    );
  }

  Widget _tab(String label, _Period p) {
    final active = _period == p;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _setPeriod(p),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? _gold.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active
                    ? _gold.withOpacity(0.45)
                    : Theme.of(context).dividerColor.withOpacity(0.4)),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active
                    ? const Color(0xFFB8860B)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              )),
        ),
      ),
    );
  }

  Widget _row(int i, Map<String, dynamic> r, bool isDark) {
    final c    = _medal(i);
    final top3 = i < 3;
    final name = (r['display_name'] ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(children: [
        Container(
          width: top3 ? 27 : 24,
          height: top3 ? 27 : 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.withOpacity(top3 ? 0.18 : 0.10),
            border: top3 ? Border.all(color: c.withOpacity(0.55)) : null,
          ),
          child: Text('${i + 1}',
              style: TextStyle(
                  fontSize: top3 ? 12 : 11,
                  fontWeight: FontWeight.bold,
                  color: c)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name.isEmpty ? (context.s.isAr ? 'صيدلاني' : 'Pharmacist') : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: top3 ? FontWeight.bold : FontWeight.w600)),
        ),
        Text('${r['correct']}/${r['total']}',
            style: TextStyle(
                fontSize: 10.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.withOpacity(top3 ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${r['score']}',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.bold, color: c)),
        ),
      ]),
    );
  }
}
