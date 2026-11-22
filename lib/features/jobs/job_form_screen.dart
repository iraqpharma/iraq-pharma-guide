import '../../shared/widgets/t_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/job_post.dart';
import '../../services/jobs_service.dart';

/// نشر إعلان فرصة عمل — لا يظهر للناس إلا بعد موافقة الإدارة.
class JobFormScreen extends StatefulWidget {
  const JobFormScreen({super.key});

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pharmacy = TextEditingController();
  final _area = TextEditingController();
  final _addressNote = TextEditingController();
  final _title = TextEditingController(text: 'صيدلاني');
  final _shift = TextEditingController();
  final _hours = TextEditingController();
  final _days = TextEditingController();
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _experience = TextEditingController();
  final _desc = TextEditingController();
  final _contactName = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();

  String _city = 'بغداد';
  String _workType = 'full_time';
  String _period = 'monthly';
  String _gender = 'any';
  bool _negotiable = true;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _pharmacy, _area, _addressNote, _title, _shift, _hours, _days,
      _min, _max, _experience, _desc, _contactName, _phone, _whatsapp,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final post = JobPost(
        id: 0,
        postedBy: '',
        pharmacyName: _pharmacy.text.trim(),
        city: _city,
        area: _area.text.trim(),
        addressNote: _addressNote.text.trim(),
        jobTitle: _title.text.trim().isEmpty ? 'صيدلاني' : _title.text.trim(),
        workType: _workType,
        shiftText: _shift.text.trim(),
        hoursText: _hours.text.trim(),
        daysText: _days.text.trim(),
        salaryNegotiable: _negotiable,
        salaryMin: _negotiable ? null : int.tryParse(_min.text.trim()),
        salaryMax: _negotiable ? null : int.tryParse(_max.text.trim()),
        salaryPeriod: _period,
        genderPref: _gender,
        experienceText: _experience.text.trim(),
        description: _desc.text.trim(),
        contactName: _contactName.text.trim(),
        contactPhone: _phone.text.trim(),
        contactWhatsapp: _whatsapp.text.trim(),
        createdAt: DateTime.now(),
      );
      await JobsService.instance.create(post);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline,
              color: AppColors.successGreen, size: 42),
          title: const TText('تم إرسال الإعلان'),
          content: const TText(
              'سيظهر إعلانك للصيادلة بعد مراجعته من الإدارة'
              'تجد حالته في «إعلاناتي»'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const TText('حسناً')),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          content: TText('تعذّر النشر: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const TText('نشر فرصة عمل')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 100),
          children: [
            const _SectionTitle('الصيدلية', Icons.local_pharmacy_outlined),
            _Field(
              controller: _pharmacy,
              label: 'اسم الصيدلية *',
              hint: 'مثال: صيدلية الشفاء',
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? trS(context, 'أدخل اسم الصيدلية') : null,
            ),
            _CityDropdown(value: _city, onChanged: (v) => setState(() => _city = v)),
            _Field(controller: _area, label: 'المنطقة', hint: 'مثال: الكرادة'),
            _Field(
                controller: _addressNote,
                label: 'وصف الموقع',
                hint: 'قرب أي معلم معروف'),

            const _SectionTitle('الوظيفة', Icons.work_outline),
            _Field(controller: _title, label: 'المسمّى', hint: 'صيدلاني'),
            _Labeled(
              'نوع الدوام',
              Wrap(
                spacing: 8,
                children: JobPost.workTypeLabels.entries
                    .map((e) => ChoiceChip(
                          label: TText(e.value),
                          selected: _workType == e.key,
                          onSelected: (_) => setState(() => _workType = e.key),
                        ))
                    .toList(),
              ),
            ),
            _Field(
                controller: _shift,
                label: 'الوردية',
                hint: 'صباحية / مسائية / متناوبة'),
            _Field(
              controller: _hours,
              label: 'ساعات التواجد المطلوبة *',
              hint: 'مثال: 9 صباحاً، 5 مساءً (8 ساعات)',
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'حدّد ساعات التواجد المطلوبة، الباحث عن عمل يحتاجها'
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: const [
                  '8 ساعات: 9 ص، 5 م',
                  '6 ساعات: 4 م، 10 م',
                  '12 ساعة: 9 ص، 9 م',
                  'وردية صباحية: 8 ص، 2 م',
                  'وردية مسائية: 4 م، 11 م',
                ]
                    .map((p) => ActionChip(
                          label: TText(p, style: const TextStyle(fontSize: 11.5)),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _hours.text = p),
                        ))
                    .toList(),
              ),
            ),
            _Field(
                controller: _days,
                label: 'أيام العمل',
                hint: 'مثال: السبت، الخميس'),

            const _SectionTitle('الراتب', Icons.payments_outlined),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _negotiable,
              onChanged: (v) => setState(() => _negotiable = v),
              title: const TText('يُحدَّد عند المقابلة'),
              subtitle: const TText('أوقف الخيار إن أردت ذكر مبلغ'),
            ),
            if (!_negotiable) ...[
              Row(children: [
                Expanded(
                  child: _Field(
                    controller: _min,
                    label: 'من *',
                    keyboard: TextInputType.number,
                    digitsOnly: true,
                    validator: (v) {
                      if (_negotiable) return null;
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'أدخل مبلغاً';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Field(
                    controller: _max,
                    label: 'إلى',
                    keyboard: TextInputType.number,
                    digitsOnly: true,
                  ),
                ),
              ]),
              _Labeled(
                'المدّة',
                Wrap(
                  spacing: 8,
                  children: JobPost.periodLabels.entries
                      .map((e) => ChoiceChip(
                            label: TText(e.value),
                            selected: _period == e.key,
                            onSelected: (_) => setState(() => _period = e.key),
                          ))
                      .toList(),
                ),
              ),
            ],

            const _SectionTitle('تفاصيل إضافية', Icons.notes_outlined),
            _Labeled(
              'تفضيل الجنس',
              Wrap(
                spacing: 8,
                children: JobPost.genderLabels.entries
                    .map((e) => ChoiceChip(
                          label: TText(e.value),
                          selected: _gender == e.key,
                          onSelected: (_) => setState(() => _gender = e.key),
                        ))
                    .toList(),
              ),
            ),
            _Field(
                controller: _experience,
                label: 'الخبرة المطلوبة',
                hint: 'مثال: سنة على الأقل، أو حديث التخرّج'),
            _Field(
                controller: _desc,
                label: 'وصف إضافي',
                hint: 'مهام العمل، مزايا أخرى…',
                maxLines: 4),

            const _SectionTitle('التواصل', Icons.phone_outlined),
            _Field(controller: _contactName, label: 'اسم المسؤول'),
            _Field(
              controller: _phone,
              label: 'رقم الهاتف *',
              hint: '07XXXXXXXXX',
              keyboard: TextInputType.phone,
              validator: (v) {
                final s = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (s.length < 10) return 'أدخل رقماً صحيحاً';
                return null;
              },
            ),
            _Field(
                controller: _whatsapp,
                label: 'واتساب (اختياري)',
                hint: '07XXXXXXXXX',
                keyboard: TextInputType.phone),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningAmber.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline,
                    size: 18, color: AppColors.warningAmber),
                SizedBox(width: 8),
                Expanded(
                  child: TText(
                    'الإعلان لا يظهر للصيادلة إلا بعد مراجعته من الإدارة',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: TText(_saving ? 'جارٍ الإرسال…' : 'إرسال الإعلان'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── عناصر مساعدة ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionTitle(this.text, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 7),
          TText(text,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
        ]),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboard;
  final bool digitsOnly;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboard,
    this.digitsOnly = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          textInputAction:
              maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          inputFormatters:
              digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
          validator: validator,
          decoration: InputDecoration(
            labelText: trN(context, label),
            hintText: trN(context, hint),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      );
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled(this.label, this.child);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TText(label,
              style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          child,
        ]),
      );
}

class _CityDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _CityDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: trS(context, 'المحافظة *'),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: JobsService.iraqCities
              .map((c) => DropdownMenuItem(value: c, child: TText(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );
}
