// اختبارات رسم سريعة للأخطاء التي ظهرت في 3.1 — تُشغَّل بـ:
//   flutter test test/layout_smoke_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iraq_pharma_guide/data/models/job_post.dart';
import 'package:iraq_pharma_guide/features/jobs/jobs_screen.dart';

void main() {
  final job = JobPost.fromMap(<String, dynamic>{
    'id': 1,
    'posted_by': 'b0561517-c2b5-4d54-b3be-f089c5a54c6d',
    'pharmacy_name': 'صيدلية القمر',
    'city': 'الأنبار',
    'area': '',
    'address_note': '',
    'job_title': 'صيدلاني',
    'work_type': 'part_time',
    'shift_text': '',
    'hours_text': '',
    'days_text': '',
    'gender_pref': 'any',
    'experience_text': '',
    'salary_min': null,
    'salary_max': null,
    'salary_period': 'monthly',
    'salary_negotiable': true,
    'currency': 'IQD',
    'contact_name': '',
    'contact_phone': '07800000000',
    'contact_whatsapp': '',
    'status': 'approved',
    'reject_reason': '',
    'likes': 0,
    'views': 3,
    'contact_clicks': 0,
    'created_at': '2026-11-19T08:42:40.266896+00:00',
    'expires_at': '2026-12-19T08:42:40.266896+00:00',
  });

  testWidgets('بطاقة الوظيفة تُرسم بارتفاع محدود داخل قائمة', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: CustomScrollView(slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 96),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  JobCard(job: job, showStatus: true),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ));
    await t.pump();
    expect(t.takeException(), isNull);
    final size = t.getSize(find.byType(JobCard));
    expect(size.height, greaterThan(60));
    expect(size.height, lessThan(500));
    expect(find.text('صيدلية القمر'), findsOneWidget);
  });

  testWidgets('بطاقة الوظيفة العامة لا تتجاوز عرض 320 مع أزرار التواصل والإبلاغ',
      (t) async {
    // خط حقيقي بدل خط الاختبار العريض، وإلا ظهرت تجاوزات وهمية.
    final font = File('test/fonts/IBMPlexSansArabic-Regular.ttf').readAsBytesSync();
    await t.runAsync(() async {
      for (final f in const ['Roboto', '.SF UI Text', 'Segoe UI']) {
        await (FontLoader(f)..addFont(Future.value(ByteData.sublistView(font)))).load();
      }
    });
    t.view.physicalSize = const Size(320, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final wide = JobPost.fromMap({
      ...job.toInsertMap('00000000-0000-0000-0000-000000000000'),
      'id': 7,
      'status': 'approved',
      'views': 1234,
      'likes': 12,
      'contact_whatsapp': '07800000000',
      'created_at': '2026-11-19T08:42:40.266896+00:00',
    });
    await t.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: ListView(
              padding: const EdgeInsets.all(14),
              children: [JobCard(job: wide)]),
        ),
      ),
    ));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  test('فكّ الترميز مرّتين يرمي مع الحروف غير اللاتينية', () {
    expect(() => Uri.decodeComponent('Lipid agents — other'),
        throwsArgumentError);
  });

  testWidgets('الراوتر يسلّم اسم العائلة مفكوكاً ولا يحتاج فكّاً ثانياً',
      (t) async {
    const name = 'Lipid agents — other';
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/category/:key/family/:fam',
          builder: (_, s) => Text(s.pathParameters['fam']!,
              textDirection: TextDirection.ltr),
        ),
      ],
    );
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/category/cardiovascular/family/${Uri.encodeComponent(name)}');
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text(name), findsOneWidget);
  });
}
