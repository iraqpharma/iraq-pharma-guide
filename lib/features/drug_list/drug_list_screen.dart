import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/drug_model.dart';
import '../../providers/drug_provider.dart';

const categoryClassMap = {
  'antibiotics': [
    'Penicillins', 'Cephalosporins', 'Macrolides', 'Quinolones',
    'Carbapenems', 'Glycopeptides', 'Sulfonamides', 'Tetracyclines',
    'Antiprotozoals',
  ],
  'cardiovascular': [
    'ACE inhibitors', 'Angiotensin II receptor antagonists', 'Beta-blockers',
    'Calcium channel blockers', 'Diuretics', 'Statins', 'Nitrates',
    'Antiplatelet drugs', 'Anticoagulants', 'Miscellaneous cardiovascular',
  ],
  'diabetes': ['Oral antidiabetics', 'Insulin'],
  'analgesics': ['NSAIDs', 'Analgesics', 'Opioid analgesics'],
  'neurology': [
    'Benzodiazepines', 'Antipsychotics', 'SSRIs',
    'Tricyclic antidepressants', 'Antiepileptics',
  ],
  'gastrointestinal': [
    'Proton pump inhibitors', 'H2 receptor antagonists', 'Laxatives',
    'Antidiarrhoeals', 'Antiemetics', 'Antispasmodics',
  ],
  'respiratory': [
    'Beta2 agonists', 'Inhaled corticosteroids', 'Antihistamines',
    'Anticholinergic bronchodilators', 'Leukotriene antagonists', 'Xanthines',
  ],
  'endocrine': ['Thyroid drugs', 'Corticosteroids'],
  'vitamins': [
    'Vitamins', 'Vitamin supplements', 'Multivitamins',
    'Iron preparations', 'Iron supplements', 'Calcium supplements',
    'Dietary supplements', 'Nutritional supplements',
    'Minerals', 'Electrolytes', 'Folic acid', 'Vitamin D',
    'Vitamin B12', 'Zinc supplements',
  ],
  'cosmetic': [
    'Dermatologicals', 'Topical agents', 'Topical corticosteroids',
    'Antifungal topical', 'Emollients', 'Skin preparations',
    'Cosmeceuticals', 'Keratolytics', 'Topical antibiotics',
    'Retinoids', 'Sunscreens', 'Hair preparations',
    'Wound care', 'Topical antifungals',
  ],
};

const categoryLabelMap = {
  'antibiotics': 'مضادات حيوية',
  'cardiovascular': 'قلب وأوعية',
  'diabetes': 'سكري',
  'analgesics': 'مسكنات وألم',
  'neurology': 'أعصاب ونفسية',
  'gastrointestinal': 'جهاز هضمي',
  'respiratory': 'جهاز تنفسي',
  'endocrine': 'غدد صماء',
  'vitamins': 'فيتامينات ومقويات',
  'cosmetic': 'كوزمتك وجلدية',
};

final _categoryDrugsProvider =
    FutureProvider.family<List<Drug>, String>((ref, key) async {
  final classes = categoryClassMap[key] ?? [];
  if (classes.isEmpty) return [];
  return ref.read(drugRepositoryProvider).getByClasses(classes);
});

// Flat list item - either a header or a drug
abstract class _ListItem {}

class _HeaderItem extends _ListItem {
  final String title;
  final String titleAr;
  _HeaderItem(this.title, this.titleAr);
}

class _DrugItem extends _ListItem {
  final Drug drug;
  _DrugItem(this.drug);
}

class DrugListScreen extends ConsumerWidget {
  final String categoryKey;
  const DrugListScreen({super.key, required this.categoryKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = categoryLabelMap[categoryKey] ?? categoryKey;
    final drugsAsync = ref.watch(_categoryDrugsProvider(categoryKey));

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: drugsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (drugs) {
          if (drugs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 56, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('لا توجد أدوية في هذا الصنف',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          // Group by pharmacological_class and build flat list
          final grouped = <String, List<Drug>>{};
          for (final d in drugs) {
            grouped.putIfAbsent(d.drugClass, () => []).add(d);
          }
          final sections = grouped.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          final items = <_ListItem>[];
          for (final section in sections) {
            items.add(_HeaderItem(section.key,
                section.value.isNotEmpty ? section.value.first.drugClassAr : ''));
            for (final d in section.value) {
              items.add(_DrugItem(d));
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              if (item is _HeaderItem) {
                return _SectionHeader(title: item.title, titleAr: item.titleAr);
              } else if (item is _DrugItem) {
                return _DrugTile(drug: item.drug);
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String titleAr;
  const _SectionHeader({required this.title, required this.titleAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleAr.isNotEmpty)
            Text(titleAr,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                    fontSize: 14)),
          Text(title,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DrugTile extends StatelessWidget {
  final Drug drug;
  const _DrugTile({required this.drug});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.lightBlue,
        child: Icon(Icons.medication, color: AppColors.primaryBlue, size: 20),
      ),
      title: Text(drug.genericName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: drug.tradeNamesList.isNotEmpty
          ? Text(drug.tradeNamesList.take(3).join(' / '),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: drug.pregnancyCategory.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('فئة ${drug.pregnancyCategory}',
                  style: const TextStyle(fontSize: 10, color: AppColors.primaryBlue)),
            )
          : null,
      onTap: () => context.push('/drug/${drug.id}'),
    );
  }
}
