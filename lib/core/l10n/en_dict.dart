// مُولَّد: ترجمة إنجليزية للنصوص العربية الثابتة التي تُعرض عبر TText/trS.
// المفتاح هو النص العربي كما يُعرض. ما لا يوجد هنا يبقى بالعربية.
const Map<String, String> kEnDict = {
  'صيدلاني':
      'Pharmacist',
  'بغداد':
      'Baghdad',
  'تم إرسال الإعلان':
      'Ad submitted',
  'سيظهر إعلانك للصيادلة بعد مراجعته من الإدارةتجد حالته في «إعلاناتي»':
      'Your ad will appear to pharmacists after admin review. Track its status in “My ads”',
  'حسناً':
      'OK',
  'نشر فرصة عمل':
      'Post a job',
  'الصيدلية':
      'Pharmacy',
  'اسم الصيدلية *':
      'Pharmacy name *',
  'مثال: صيدلية الشفاء':
      'e.g. Al-Shifa Pharmacy',
  'أدخل اسم الصيدلية':
      'Enter the pharmacy name',
  'المنطقة':
      'Area',
  'مثال: الكرادة':
      'e.g. Karrada',
  'وصف الموقع':
      'Location description',
  'قرب أي معلم معروف':
      'Near a well-known landmark',
  'الوظيفة':
      'Job',
  'المسمّى':
      'Title',
  'نوع الدوام':
      'Work type',
  'الوردية':
      'Shift',
  'صباحية / مسائية / متناوبة':
      'Morning / evening / rotating',
  'ساعات التواجد المطلوبة *':
      'Required working hours *',
  'مثال: 9 صباحاً، 5 مساءً (8 ساعات)':
      'e.g. 9 am to 5 pm (8 hours)',
  'حدّد ساعات التواجد المطلوبة، الباحث عن عمل يحتاجها':
      'Specify the required hours; job seekers need them',
  '8 ساعات: 9 ص، 5 م':
      '8 hours: 9 am to 5 pm',
  '6 ساعات: 4 م، 10 م':
      '6 hours: 4 pm to 10 pm',
  '12 ساعة: 9 ص، 9 م':
      '12 hours: 9 am to 9 pm',
  'وردية صباحية: 8 ص، 2 م':
      'Morning shift: 8 am to 2 pm',
  'وردية مسائية: 4 م، 11 م':
      'Evening shift: 4 pm to 11 pm',
  'أيام العمل':
      'Working days',
  'مثال: السبت، الخميس':
      'e.g. Saturday to Thursday',
  'الراتب':
      'Salary',
  'يُحدَّد عند المقابلة':
      'Set at the interview',
  'أوقف الخيار إن أردت ذكر مبلغ':
      'Turn this off to state an amount',
  'من *':
      'From *',
  'أدخل مبلغاً':
      'Enter an amount',
  'إلى':
      'To',
  'المدّة':
      'Period',
  'تفاصيل إضافية':
      'More details',
  'تفضيل الجنس':
      'Gender preference',
  'الخبرة المطلوبة':
      'Required experience',
  'مثال: سنة على الأقل، أو حديث التخرّج':
      'e.g. at least one year, or fresh graduate',
  'وصف إضافي':
      'Additional description',
  'مهام العمل، مزايا أخرى…':
      'Duties, other benefits…',
  'التواصل':
      'Contact',
  'اسم المسؤول':
      'Contact person',
  'رقم الهاتف *':
      'Phone number *',
  'أدخل رقماً صحيحاً':
      'Enter a valid number',
  'واتساب (اختياري)':
      'WhatsApp (optional)',
  'الإعلان لا يظهر للصيادلة إلا بعد مراجعته من الإدارة':
      'The ad appears to pharmacists only after admin review',
  'جارٍ الإرسال…':
      'Sending…',
  'إرسال الإعلان':
      'Submit ad',
  'المحافظة *':
      'Governorate *',
  'قطرة العين أو الأذن':
      'Eye or ear drops',
  '28 يوماً':
      '28 days',
  'المادة الحافظة تكفي شهراً بعد الفتح. القطرة بلا مادة حافظة (أحادية الجرعة) تُرمى بعد 12–24 ساعة من فتحها':
      'The preservative lasts a month after opening. Preservative-free (single-dose) drops are discarded 12–24 hours after opening',
  'قلم أو قنينة أنسولين قيد الاستعمال':
      'Insulin pen or vial in use',
  'خارج الثلاجة بحرارة الغرفة دون 25 درجة. القلم المفتوح لا يُعاد للثلاجة. بعض الأنواع 42 يوماً، راجع نشرة المنتج':
      'Out of the fridge at room temperature below 25°C. An opened pen does not go back in the fridge. Some types last 42 days; check the leaflet',
  'مضاد حيوي شراب بعد التحضير بالماء':
      'Antibiotic suspension after reconstitution',
  '7 إلى 14 يوماً':
      '7 to 14 days',
  'الأموكسيسيلين والأوغمنتين 7 أيام في الثلاجة، والأزيثرومايسين 10 أيام، والسيفيكسيم 14. اكتب تاريخ التحضير على العلبة':
      'Amoxicillin and co-amoxiclav 7 days in the fridge, azithromycin 10 days, cefixime 14. Write the preparation date on the bottle',
  'شراب جاهز أو معلّق فموي':
      'Ready-made syrup or oral suspension',
  '3 أشهر':
      '3 months',
  'ما لم تذكر النشرة غير ذلك. أغلق بإحكام وتجنّب الحرارة والشمس':
      'Unless the leaflet says otherwise. Close tightly and keep away from heat and sunlight',
  'كريم أو مرهم في أنبوب':
      'Cream or ointment in a tube',
  '3 إلى 6 أشهر':
      '3 to 6 months',
  'الأنبوب أنظف من العلبة ذات الغطاء لأن الأصابع لا تلمس المحتوى. يُرمى عند تغيّر اللون أو الرائحة أو انفصال القوام':
      'A tube stays cleaner than a jar because fingers do not touch the contents. Discard if the colour, smell or texture changes',
  'بخاخ الأنف':
      'Nasal spray',
  'لا يُشارَك بين شخصين إطلاقاً. نظّف الفوهة بعد كل استعمال':
      'Never share between two people. Clean the nozzle after each use',
  'محلول وريدي بعد الفتح أو الثقب':
      'IV solution after opening or spiking',
  '24 ساعة':
      '24 hours',
  'في الثلاجة، وبعض الأدوية أقل بكثير. التحضير في ظرف معقّم يطيل المدّة حسب بروتوكول المستشفى':
      'In the fridge, and much less for some drugs. Aseptic preparation extends this according to hospital protocol',
  'قنينة متعدّدة الجرعات (حقن)':
      'Multi-dose vial (injection)',
  'من أول ثقب للغطاء المطاطي. اكتب التاريخ على القنينة، وامسح الغطاء بالكحول قبل كل سحب':
      'From the first puncture of the rubber stopper. Write the date on the vial and swab the stopper with alcohol before each draw',
  'تحاميل ولبوس':
      'Suppositories and pessaries',
  'حتى تاريخ العلبة':
      'Until the pack expiry',
  'لا تتأثر بالفتح لأن كل وحدة مغلّفة وحدها، لكنها تذوب بالحرارة فتُحفظ في مكان بارد':
      'Not affected by opening since each unit is sealed, but they melt in heat, so store in a cool place',
  'أقراص وكبسولات في شريط':
      'Tablets and capsules in a blister',
  'الشريط يحمي كل حبّة وحدها. أمّا العلبة المفتوحة ذات الحبوب السائبة فستّة أشهر، ولا تُنقل الحبوب إلى علبة أخرى':
      'The blister protects each tablet. Loose tablets in an opened bottle last six months; do not move them to another container',
  'متى فُتحت العبوة؟':
      'When was it opened?',
  'الصلاحية بعد الفتح':
      'Shelf Life After Opening',
  'التاريخ المطبوع على العلبة يخصّ العبوة المغلقة. بعد أول فتح تبدأ مدّة أقصر، وهذه هي':
      'The date printed on the pack is for the sealed product. After first opening a shorter period starts, and here it is',
  'هذه مدد عامة مرجعية. نشرة المنتج تسبقها دائماً، وأي تغيّر في اللون أو الرائحة أو القوام يعني الرمي فوراً مهما بقي من الوقت':
      'These are general reference periods. The product leaflet always takes priority, and any change in colour, smell or texture means discard immediately, whatever time is left',
  'تنتهي اليوم':
      'Expires today',
  'عدد الأقراص في العلبة':
      'Tablets in the pack',
  'حجم القنينة (مل)':
      'Bottle volume (mL)',
  'وحدات القلم أو القنينة':
      'Units in the pen or vial',
  'عدد الأقراص في المرّة':
      'Tablets per dose',
  'الجرعة في المرّة (ملغم)':
      'Dose each time (mg)',
  'عدد القطرات في المرّة':
      'Drops per dose',
  'الوحدات في المرّة':
      'Units per dose',
  'كم يوماً تكفي العلبة؟':
      'How Many Days Will the Pack Last?',
  'نوع الشكل الدوائي':
      'Dosage form',
  'أقراص وكبسولات':
      'Tablets and capsules',
  'شراب ومعلّق':
      'Syrup and suspension',
  'قطرة':
      'Drops',
  'أنسولين':
      'Insulin',
  'التركيز (ملغم في كل مل)':
      'Concentration (mg per mL)',
  'مثال: شراب 250 ملغم / 5 مل يعني 50':
      'e.g. a 250 mg / 5 mL syrup means 50',
  'عدد المرّات في اليوم':
      'Times per day',
  'مرّة':
      'once',
  'مرّتان':
      'twice',
  'أكمل الحقول أعلاه ليظهر الناتج':
      'Fill in the fields above to see the result',
  'القطرة محسوبة على أنّ كل 20 قطرة تساوي ملليلتراً واحداً، وهو تقدير يتغيّر بحسب لزوجة المحلول وفوهة القنينة. الشراب بعد التحضير له مدّة صلاحية قد تنتهي قبل أن ينفد':
      'Drops are calculated at 20 drops per millilitre, an estimate that varies with solution viscosity and the dropper tip. A reconstituted syrup has a shelf life that may end before it runs out',
  'قرصاً في اليوم':
      'tablets per day',
  'مل في اليوم':
      'mL per day',
  'وحدة في اليوم':
      'units per day',
  'الاستهلاك اليومي':
      'Daily use',
  'تاريخ النفاد المتوقّع':
      'Expected run-out date',
  'ذكّر المريض بإعادة الصرف':
      'Remind the patient to refill',
  'العبوة لا تكفي أسبوعاً. راجع حجم العبوة أو اصرف أكثر من واحدة لتغطية مدّة العلاج':
      'The pack will not last a week. Check the pack size or dispense more than one to cover the treatment period',
  'سكر الدم':
      'Blood glucose',
  'الكيمياء العامة':
      'General chemistry',
  '70 – 100 صائم':
      '70 – 100 fasting',
  'السكر التراكمي':
      'HbA1c',
  'أقل من 5.7':
      'Below 5.7',
  'الكرياتينين':
      'Creatinine',
  'اليوريا':
      'Urea',
  'نيتروجين اليوريا':
      'Blood urea nitrogen',
  'حامض اليوريك':
      'Uric acid',
  'البيليروبين الكلّي':
      'Total bilirubin',
  'البروتين الكلّي':
      'Total protein',
  'الألبومين':
      'Albumin',
  'بروتين سي التفاعلي':
      'C-reactive protein',
  'أقل من 0.5':
      'Below 0.5',
  'اللاكتات':
      'Lactate',
  'الأمونيا':
      'Ammonia',
  'الكوليسترول الكلّي':
      'Total cholesterol',
  'الشحوم':
      'Lipids',
  'أقل من 200':
      'Below 200',
  'الكوليسترول الضار':
      'LDL cholesterol',
  'أقل من 100':
      'Below 100',
  'الكوليسترول النافع':
      'HDL cholesterol',
  'أكثر من 40':
      'Above 40',
  'الدهون الثلاثية':
      'Triglycerides',
  'أقل من 150':
      'Below 150',
  'الصوديوم':
      'Sodium',
  'الشوارد والمعادن':
      'Electrolytes and minerals',
  'البوتاسيوم':
      'Potassium',
  'الكلورايد':
      'Chloride',
  'الكالسيوم الكلّي':
      'Total calcium',
  'المغنيسيوم':
      'Magnesium',
  'الفوسفات':
      'Phosphate',
  'الهيموغلوبين':
      'Hemoglobin',
  'الدم والفيتامينات':
      'Blood and vitamins',
  '12 – 16 أنثى  ·  13.5 – 17.5 ذكر':
      '12 – 16 female  ·  13.5 – 17.5 male',
  'الحديد':
      'Iron',
  'الفيرّيتين':
      'Ferritin',
  'فيتامين ب12':
      'Vitamin B12',
  'فيتامين د':
      'Vitamin D',
  'حامض الفوليك':
      'Folic acid',
  'الكورتيزول':
      'Cortisol',
  'الهرمونات':
      'Hormones',
  '5 – 23 صباحاً':
      '5 – 23 morning',
  'التستوستيرون':
      'Testosterone',
  '300 – 1000 ذكر':
      '300 – 1000 male',
  'الثايروكسين الكلّي':
      'Total thyroxine',
  'ثلاثي يودوثيرونين':
      'Triiodothyronine',
  'الديجوكسين':
      'Digoxin',
  'مستويات الأدوية':
      'Drug levels',
  '0.5 – 2.0 علاجي':
      '0.5 – 2.0 therapeutic',
  'الفينيتوين':
      'Phenytoin',
  '10 – 20 علاجي':
      '10 – 20 therapeutic',
  'الكاربامازيبين':
      'Carbamazepine',
  '4 – 12 علاجي':
      '4 – 12 therapeutic',
  'حامض الفالبروييك':
      'Valproic acid',
  '50 – 100 علاجي':
      '50 – 100 therapeutic',
  'الثيوفيلين':
      'Theophylline',
  'الليثيوم':
      'Lithium',
  '0.6 – 1.2 علاجي':
      '0.6 – 1.2 therapeutic',
  'الفانكومايسين':
      'Vancomycin',
  '10 – 20 قبل الجرعة':
      '10 – 20 trough',
  'الجنتامايسين':
      'Gentamicin',
  'أقل من 2 قبل الجرعة':
      'Below 2 trough',
  'الباراسيتامول':
      'Paracetamol',
  'سُمّي فوق 150 بعد 4 ساعات':
      'Toxic above 150 at 4 hours',
  'الساليسيلات':
      'Salicylate',
  'سُمّي فوق 30':
      'Toxic above 30',
  'محوّل الوحدات المختبرية':
      'Lab Unit Converter',
  'ابحث عن تحليل بالعربية أو الإنكليزية':
      'Search a test in Arabic or English',
  'لا توجد نتائج':
      'No results',
  'اعكس الاتجاه':
      'Swap direction',
  'يعتمد التحويل معادلة IFCC المعتمدة عالمياً بين النسبة المئوية و ملمول/مول':
      'The conversion uses the internationally adopted IFCC equation between percent and mmol/mol',
  'عند الولادة':
      'At birth',
  'BCG  ·  0.1 مل داخل الأدمة':
      'BCG  ·  0.1 mL intradermal',
  'OPV 0  ·  نقطتان فموياً':
      'OPV 0  ·  two drops orally',
  'Hepatitis B 1  ·  خلال 24 ساعة من الولادة':
      'Hepatitis B 1  ·  within 24 hours of birth',
  'جرعة التهاب الكبد الأولى مهمّة خلال اليوم الأول، وتأخيرها يقلّل الحماية من انتقال الفيروس من الأم':
      'The first hepatitis B dose matters within the first day; delaying it reduces protection against mother-to-child transmission',
  'شهران':
      'Two months',
  'Rotavirus 1  ·  فموي':
      'Rotavirus 1  ·  oral',
  'الجرعة الأولى من لقاح الروتا لا تُعطى بعد عمر 15 أسبوعاً':
      'The first rotavirus dose is not given after 15 weeks of age',
  'أربعة أشهر':
      'Four months',
  'IPV  ·  البوليو المعطّل عضلياً':
      'IPV  ·  inactivated polio, intramuscular',
  'جرعة البوليو المعطّل تُعطى مع هذه الزيارة في البرنامج العراقي':
      'The inactivated polio dose is given at this visit in the Iraqi programme',
  'ستة أشهر':
      'Six months',
  'آخر جرعة من الروتا لا تُعطى بعد عمر ثمانية أشهر':
      'The last rotavirus dose is not given after eight months of age',
  'تسعة أشهر':
      'Nine months',
  'Measles  ·  الحصبة أحادية':
      'Measles  ·  monovalent measles',
  'Vitamin A  ·  100000 وحدة':
      'Vitamin A  ·  100,000 IU',
  'لقاح الحصبة هنا لا يُلغي الحاجة إلى MMR في الخامسة عشرة':
      'The measles vaccine here does not replace MMR at fifteen months',
  'خمسة عشر شهراً':
      'Fifteen months',
  'MMR 1  ·  حصبة ونكاف وحميراء':
      'MMR 1  ·  measles, mumps, rubella',
  'ثمانية عشر شهراً':
      'Eighteen months',
  'Vitamin A  ·  200000 وحدة':
      'Vitamin A  ·  200,000 IU',
  'الجرعة المعزّزة الأولى':
      'First booster dose',
  'عند دخول المدرسة  ·  4 إلى 6 سنوات':
      'School entry  ·  4 to 6 years',
  'الجرعة المعزّزة الثانية. بعد عمر السادسة يُستعمل Td بدل DTP':
      'Second booster dose. After age six, Td is used instead of DTP',
  'كل عشر سنوات بعد المدرسة':
      'Every ten years after school',
  'Td  ·  تيتانوس وخفّاق الدفتيريا':
      'Td  ·  tetanus and reduced diphtheria',
  'تتكرّر مدى الحياة كل عشر سنوات':
      'Repeated for life every ten years',
  'غير مشمول في الجدول الوطني، يُصرف خاصّاً. جرعتان أو ثلاث في السنة الأولى مع جرعة معزّزة':
      'Not in the national schedule; dispensed privately. Two or three doses in the first year plus a booster',
  'Varicella  ·  الجدري المائي':
      'Varicella  ·  chickenpox',
  'جرعة بعد السنة وجرعة ثانية بعد ستة أسابيع':
      'One dose after age one and a second six weeks later',
  'جرعتان بفاصل ستّة أشهر، بعد عمر السنة':
      'Two doses six months apart, after age one',
  'Influenza  ·  الإنفلونزا الموسمية':
      'Influenza  ·  seasonal flu',
  'سنوياً من عمر ستّة أشهر، وجرعتان في السنة الأولى من التلقيح':
      'Yearly from six months of age; two doses in the first year of vaccination',
  'Meningococcal  ·  السحائي':
      'Meningococcal',
  'مطلوب لحجّاج العراق ومسافري الحجّ والعمرة':
      'Required for Iraqi pilgrims and Hajj/Umrah travellers',
  'HPV  ·  فيروس الورم الحلمي':
      'HPV  ·  human papillomavirus',
  'للفتيات من عمر تسع سنوات، جرعتان':
      'For girls from age nine, two doses',
  'Typhoid  ·  التيفوئيد':
      'Typhoid',
  'جرعة كل ثلاث سنوات في المناطق الموبوءة':
      'One dose every three years in endemic areas',
  'تاريخ ميلاد الطفل':
      'Child\'s date of birth',
  'جدول التلقيح العراقي':
      'Iraqi Vaccination Schedule',
  'حوّل الجدول إلى تواريخ':
      'Turn the schedule into dates',
  'اختر تاريخ الميلاد لتظهر تواريخ كل زيارة، والزيارات التي فاتت':
      'Pick the date of birth to see the date of each visit and any missed visits',
  'تاريخ الميلاد':
      'Date of birth',
  'إلغاء':
      'Cancel',
  'لقاحات خارج الجدول الوطني':
      'Vaccines outside the national schedule',
  'جدول مرجعي للاسترشاد. بطاقة التلقيح الصادرة من مركز الرعاية الصحية الأولية وتعليمات وزارة الصحة هي المرجع الملزم، وقد تتغيّر اللقاحات وأعمارها بقرار وزاري':
      'A reference schedule for guidance. The vaccination card issued by the primary health care centre and Ministry of Health instructions are the binding reference; vaccines and ages may change by ministerial decision',
  'فائتة':
      'Missed',
  'مستحقّة الآن':
      'Due now',
  'قادمة':
      'Upcoming',
  'حاسبة السوائل والتخفيف':
      'Fluids & Dilution Calculator',
  'التخفيف':
      'Dilution',
  'معدل التسريب':
      'Infusion rate',
  'جرعة بالوزن':
      'Weight-based dose',
  'صيانة الأطفال':
      'Pediatric maintenance',
  'الحاسبة أداة مساعدة، راجع نشرة المنتج وبروتوكول المستشفى قبل التحضير، وتحقّق من الحساب مرّة ثانية مع زميل في الأدوية عالية الخطورة':
      'The calculator is an aid. Check the product leaflet and hospital protocol before preparing, and double-check the calculation with a colleague for high-alert drugs',
  'من تركيز جاهز إلى تركيز مطلوب، تُحسب كمية العيار والمذيب':
      'From a stock concentration to a target concentration: stock and diluent volumes',
  'تركيز العيار المتوفّر (C1)':
      'Stock concentration (C1)',
  'مثال: 50':
      'e.g. 50',
  'التركيز المطلوب (C2)':
      'Target concentration (C2)',
  'مثال: 5':
      'e.g. 5',
  'الحجم النهائي المطلوب (V2)':
      'Final volume needed (V2)',
  'مثال: 100':
      'e.g. 100',
  'غير ممكن':
      'Not possible',
  'التركيز المطلوب أعلى من تركيز العيار':
      'Target concentration is higher than the stock',
  'التخفيف يُنزِل التركيز لا يرفعه، راجع الأرقام أو ابحث عن عيار أقوى':
      'Dilution lowers concentration, it cannot raise it. Check the numbers or find a stronger stock',
  'التحضير':
      'Preparation',
  'اسحب من العيار':
      'Draw from stock',
  'أضف مذيباً':
      'Add diluent',
  'الحجم النهائي':
      'Final volume',
  'الكمية الكلية للدواء':
      'Total drug amount',
  'من حجم الكيس ومدّة التسريب إلى معدل المضخة وعدد القطرات':
      'From bag volume and infusion time to pump rate and drop count',
  'الحجم الكلي':
      'Total volume',
  'مثال: 500':
      'e.g. 500',
  'مدّة التسريب':
      'Infusion time',
  'ساعة':
      'hour',
  'مثال: 8، نصف ساعة تُكتب 0.5':
      'e.g. 8; write half an hour as 0.5',
  'معامل القطرة (مكتوب على علبة السِت)':
      'Drop factor (printed on the set pack)',
  '60 (ميكرو)':
      '60 (micro)',
  'المعدل':
      'Rate',
  'معدل المضخة':
      'Pump rate',
  'القطرات':
      'Drops',
  'بالثانية':
      'per second',
  'بالعدّ اليدوي: احسب القطرات في 15 ثانية واضربها في 4 للتحقّق من الضبط':
      'Manual count: count the drops in 15 seconds and multiply by 4 to verify the setting',
  'لأدوية التسريب المحسوبة بالوزن (نورإبينفرين، دوبامينميدازولام…): من الجرعة المطلوبة إلى معدل المضخة':
      'For weight-based infusions (norepinephrine, dopamine, midazolam…): from the ordered dose to the pump rate',
  'وزن المريض':
      'Patient weight',
  'الجرعة المطلوبة':
      'Ordered dose',
  'مثال: 0.05':
      'e.g. 0.05',
  'كمية الدواء في الكيس':
      'Drug amount in the bag',
  'مثال: 4':
      'e.g. 4',
  'حجم الكيس':
      'Bag volume',
  'الضبط':
      'Setting',
  'تركيز الكيس':
      'Bag concentration',
  'الجرعة الفعلية':
      'Actual dose',
  'تحقّق من التركيز المعتمد في وحدتك، بعض الوحدات تُحضّر النورإبينفرين 4 mg/250 mL وأخرى 4 mg/50 mL، والفرق في المعدل خمسة أضعاف':
      'Check the standard concentration in your unit. Some units prepare norepinephrine 4 mg/250 mL and others 4 mg/50 mL, a five-fold difference in rate',
  'سوائل الصيانة بقاعدة Holliday-Segar (4-2-1)، مع حساب العَوَز عند وجود تجفاف':
      'Maintenance fluids by the Holliday-Segar (4-2-1) rule, with deficit calculation when dehydrated',
  'وزن الطفل':
      'Child\'s weight',
  'مثال: 14':
      'e.g. 14',
  'درجة التجفاف':
      'Degree of dehydration',
  'بلا تجفاف':
      'No dehydration',
  'الصيانة':
      'Maintenance',
  'المعدل بالساعة':
      'Hourly rate',
  'في 24 ساعة':
      'Over 24 hours',
  'المحلول المعتاد للصيانة عند الأطفال: isotonic (0.9٪ NaCl + 5٪ dextrose) مع البوتاسيوم عند الحاجةالمحاليل الناقصة التوتّر ترفع خطر نقص الصوديوم':
      'Usual pediatric maintenance fluid: isotonic (0.9% NaCl + 5% dextrose) with potassium as needed. Hypotonic fluids raise the risk of hyponatremia',
  'عَوَز السوائل':
      'Fluid deficit',
  'العَوَز الكلي':
      'Total deficit',
  'نصفه في 8 ساعات':
      'Half over 8 hours',
  'والنصف في 16 ساعة':
      'and half over 16 hours',
  'الصدمة تُعالَج أولاً بجرعة bolus 10–20 mL/kg قبل حساب العَوَز، ويُعاد تقييم الطفل بعد كل جرعة':
      'Shock is treated first with a 10–20 mL/kg bolus before calculating the deficit; reassess the child after each bolus',
  'زبائني':
      'My Customers',
  'عن هذا القسم':
      'About this section',
  'ابحث باسم الزبون أو هاتفه أو دوائه':
      'Search by customer name, phone or drug',
  'زبون جديد':
      'New customer',
  'اتّصل':
      'Call',
  'سجّل زيارة وصرف':
      'Log a visit and refill',
  'احذف البطاقة':
      'Delete card',
  '؟':
      '?',
  'ماذا صرفت له اليوم؟':
      'What did you dispense today?',
  'ما تختاره يُحدّث تاريخ آخر صرف وموعد التذكير':
      'Your selection updates the last refill date and the reminder',
  'سجّل الزيارة':
      'Log visit',
  'حذف البطاقة':
      'Delete card',
  'احذف':
      'Delete',
  'لا بطاقات بعد':
      'No cards yet',
  'لا نتائج':
      'No results',
  'سجّل زبونك المزمن الأول: اسمه وعلاجه وجرعته،\nفيذكّرك التطبيق بموعده في كل زيارة':
      'Add your first chronic customer: name, treatment and dose,\nand the app reminds you of the due date at every visit',
  'جرّب كلمة أخرى':
      'Try another word',
  'اكتب اسم الزبون':
      'Enter the customer name',
  'تعديل البطاقة':
      'Edit card',
  'حفظ':
      'Save',
  'اسم الزبون':
      'Customer name',
  'الهاتف':
      'Phone',
  'العمر':
      'Age',
  'الحالة المزمنة':
      'Chronic condition',
  'سكري، ضغط، ربو':
      'Diabetes, hypertension, asthma',
  'حساسية معروفة':
      'Known allergy',
  'بنسلين، أسبرين':
      'Penicillin, aspirin',
  'ملاحظة':
      'Note',
  'أدويته':
      'Medications',
  'أضف دواء':
      'Add drug',
  'لم تُضف أدوية بعد. الدواء مع جرعته وعدد أيام العلبة هو ما يجعل التذكير ممكناً':
      'No drugs added yet. The drug with its dose and days per pack is what makes the reminder possible',
  'هذه البطاقة محفوظة على هاتفك وحده ولا تُرفع إلى أي خادم. معلومات المرضى أمانة، ومكانها جهازك لا الإنترنت':
      'This card is stored on your phone only and is never uploaded to any server. Patient information is a trust; it belongs on your device, not the internet',
  'تعديل الدواء':
      'Edit drug',
  'اسم الدواء':
      'Drug name',
  'اكتب حرفين ليظهر الاقتراح':
      'Type two letters for suggestions',
  'الجرعة':
      'Dose',
  'قرص صباحاً ومساءً بعد الأكل':
      'One tablet morning and evening after food',
  'ملاحظة (اختياري)':
      'Note (optional)',
  'لا يُؤخذ مع الحليب':
      'Not to be taken with milk',
  'العلبة تكفي':
      'Pack lasts',
  'على أساسه يُحسب موعد إعادة الصرف':
      'The refill date is calculated from this',
  'حفظ الدواء':
      'Save drug',
  'توفّر الأدوية':
      'Drug Availability',
  'إعلاناتي':
      'My ads',
  'أعلن عن توفّر دواء':
      'Announce a drug in stock',
  'اكتب اسم الدواء الذي تبحث عنه…':
      'Type the drug you are looking for…',
  'الكل':
      'All',
  'تعذّر التحميل':
      'Could not load',
  'تأكّد من الاتصال بالإنترنت':
      'Check your internet connection',
  'لا إعلانات توفّر حالياً':
      'No availability ads right now',
  'إن كان الدواء متوفّراً عندك فأعلن عنه، يصل خبره لكل صيدلاني يبحث عنه':
      'If you have the drug in stock, announce it so every pharmacist looking for it hears about it',
  'واتساب':
      'WhatsApp',
  'اتصال':
      'Call',
  'بانتظار المراجعة':
      'Pending review',
  'منشور':
      'Published',
  'مرفوض':
      'Rejected',
  'مغلق':
      'Closed',
  'منتهٍ':
      'Expired',
  'وصل إعلانك، يظهر بعد موافقة الإدارة':
      'Ad received. It appears after admin approval',
  'تعذّر الإرسال، تأكّد من تسجيل الدخول والاتصال':
      'Could not send. Make sure you are signed in and connected',
  'يظهر إعلانك بعد موافقة الإدارة ويسري 30 يوماًويمكنك إغلاقه عند نفاد الكمية':
      'Your ad appears after admin approval and runs for 30 days. You can close it when stock runs out',
  'اسم الدواء *':
      'Drug name *',
  'مثال: Insulin glargine':
      'e.g. Insulin glargine',
  'أدخل اسم الدواء':
      'Enter the drug name',
  'التركيز':
      'Strength',
  'الشكل':
      'Form',
  'قلم / حبوب':
      'Pen / tablets',
  'الكمية المتوفّرة':
      'Quantity available',
  'مثال: 5 علب':
      'e.g. 5 packs',
  'السعر بالدينار':
      'Price in IQD',
  'اتركه فارغاً إن كان عند الاتصال':
      'Leave empty if on request',
  'صيدلية الشفاء':
      'Al-Shifa Pharmacy',
  'الكرادة':
      'Karrada',
  'ملاحظات':
      'Notes',
  'تاريخ الانتهاء، شرط الحفظ، أي تفصيل مفيد':
      'Expiry date, storage condition, any useful detail',
  'جاري الإرسال…':
      'Sending…',
  'إعلانات التوفّر الخاصة بي':
      'My availability ads',
  'لم تنشر إعلاناً بعد':
      'You have not posted an ad yet',
  'نفدت الكمية، أغلق الإعلان':
      'Out of stock, close the ad',
  'كيف أبحث عن دواء؟':
      'How do I search for a drug?',
  'اضغط على أيقونة البحث في الشريط السفلي، ثم اكتب اسم الدواء بالعربي أو الإنجليزي أو رقم التسجيل.':
      'Tap the search icon in the bottom bar, then type the drug name in Arabic or English.',
  'كيف أستخدم حاسبة الجرعات؟':
      'How do I use the dose calculator?',
  'من قسم الأدوات، اختر "حاسبة الجرعات"، أدخل وزن المريض والدواء والجرعة المطلوبة وستحسب التطبيق الجرعة تلقائياً.':
      'From the Tools section choose the dose calculator, enter the patient\'s weight, the drug and the dose, and the app calculates it.',
  'كيف أحفظ ملاحظاتي المهنية؟':
      'How do I save my professional notes?',
  'من قسم حسابي → المرجع التفاعلي، يمكنك إضافة وتعديل وحذف ملاحظاتك وبروتوكولاتك الشخصية.':
      'From My Account → Notebook you can add, edit and delete your personal notes and protocols.',
  'هل يمكنني استخدام التطبيق بدون إنترنت؟':
      'Can I use the app without internet?',
  'بعض البيانات الأساسية تعمل offline، لكن البحث والمزامنة تتطلب اتصالاً بالإنترنت.':
      'Core drug data works offline, but prices, jobs and sync need an internet connection.',
  'كيف أغيّر كلمة المرور؟':
      'How do I change my password?',
  'من حسابي → تعديل البيانات الشخصية → تغيير كلمة المرور في أعلى الشاشة.':
      'From My Account → Edit personal details → Change password at the top of the screen.',
  'كيف أتواصل مع الدعم؟':
      'How do I contact support?',
  'يمكنك إرسال اقتراحاتك أو مشاكلك عبر قسم "إرسال اقتراح" في صفحة حسابي، أو عبر البريد الإلكتروني أدناه.':
      'Send suggestions or problems through “Send a suggestion” in My Account, or by the email below.',
  'الباحث عن البدائل':
      'Substitution Finder',
  'الدواء غير متوفّر والمريض واقف أمامك. هنا تجد ما يحلّ محلّه':
      'The drug is out of stock and the patient is waiting. Find what can replace it here',
  'ابحث بالاسم':
      'Search by name',
  'اكتب اسم الدواء الناقص، تجاري أو علمي، لا فرق':
      'Type the missing drug, brand or generic, either works',
  'بديل بنفس المادة أو بنفس العائلة':
      'Same ingredient or same family',
  'البديل المطابق أولاً، ثم أدوية العائلة نفسها حين لا يتوفّر مطابق':
      'Exact equivalents first, then drugs of the same family when no equivalent is available',
  'انتبه للتركيز والشكل':
      'Mind the strength and form',
  'البديل يحمل التركيز والشكل، فتقارنهما قبل الصرف':
      'Each alternative shows strength and form so you can compare before dispensing',
  'حاسبة التسعير':
      'Pricing Calculator',
  'من سعر الفاتورة إلى سعر الرفّ، بربح تحدّده أنت':
      'From invoice price to shelf price, with the margin you set',
  'ابدأ من سعر القطعة في الفاتورة':
      'Start from the unit price on the invoice',
  'أدخل سعر الشراء الحقيقي للقطعة الواحدة لا سعر الكارتون':
      'Enter the real purchase price per unit, not per carton',
  'حدّد نسبة الربح':
      'Set the profit margin',
  'الحاسبة تعطي سعر البيع والربح بالدينار على القطعة وعلى الكمّية':
      'The calculator gives the selling price and the profit in IQD per unit and per quantity',
  'قارن قبل أن تُسعّر':
      'Compare before you price',
  'راجع السعر مع دليل الأسعار كي لا تخرج عن سعر السوق':
      'Check the price against the price guide so you stay within market price',
  'نواقص الصيدلية':
      'Pharmacy Shortages',
  'سجّل ما نفد وأنت واقف عند الرفّ، لا بعد ساعة حين تنساه':
      'Log what ran out while you are at the shelf, not an hour later when you forget',
  'اكتب حرفين فقط':
      'Type just two letters',
  'الاسم يأتيك من قاعدة الأدوية، فلا تكتبه كاملاً ولا تخطئ بإملائه':
      'The name comes from the drug database, so no need to type it in full or risk misspelling',
  'أو اقرأ الباركود':
      'Or scan the barcode',
  'أسرع طريقة وأنت ممسك بالعلبة الأخيرة':
      'The fastest way while you hold the last pack',
  'أو صوّر العلبة الآن':
      'Or take a photo now',
  'الصورة تُسجَّل فوراً وتُكمل الاسم في وقت أهدأ':
      'The photo is saved right away and you complete the name later',
  'أرسل القائمة للمندوب':
      'Send the list to the rep',
  'مرتّبة: ما نفد أولاً ثم ما أوشك، بضغطة واحدة على واتساب':
      'Sorted: out of stock first, then running low, one tap to WhatsApp',
  'دليل الأسعار':
      'Price Guide',
  'أسعار السوق التجارية كما يتداولها الصيادلة':
      'Commercial market prices as traded among pharmacists',
  'ابحث بالاسم التجاري':
      'Search by brand name',
  'اكتب أول حروف الاسم وستظهر النتائج فوراً':
      'Type the first letters and results appear at once',
  'الرقم يُترجَم إلى اسم الدواء أولاً ثم يُبحث عنه':
      'The number is translated to the drug name first, then searched',
  'حدّث القائمة بين حين وآخر':
      'Refresh the list from time to time',
  'الأسعار تتغيّر، والسحب للأسفل يجلب آخر تحديث':
      'Prices change; pull down to get the latest update',
  'عيادتك اليوم':
      'Clinic Today',
  'خمس دقائق يومياً تُبقي معلوماتك حيّة':
      'Five minutes a day keeps your knowledge alive',
  'أسئلة اليوم':
      'Today\'s Questions',
  'خمسة أسئلة جديدة كل يوم، وترتيب الإجابات يتغيّر في كل مرّة':
      'Five new questions every day, with answer order shuffled each time',
  'تحدّي التداخلات':
      'Interaction Challenge',
  'زوجان من الأدوية، وعليك أن تقرّر: تداخل أم لا':
      'Two drugs, and you decide: interaction or not',
  'لوحة الصدارة':
      'Leaderboard',
  'العشرة الأوائل اليوم والأسبوع والشهر':
      'Top ten for today, the week and the month',
  'مدقّق التداخلات':
      'Interaction Checker',
  'قبل أن تصرف وصفة فيها أكثر من دواء':
      'Before dispensing a prescription with more than one drug',
  'أضف أدوية الوصفة':
      'Add the prescription drugs',
  'اثنان أو أكثر، والفحص يشمل كل الأزواج الممكنة بينها':
      'Two or more; the check covers every possible pair',
  'اقرأ درجة الخطورة':
      'Read the severity',
  'التداخل الشديد يعني راجع الطبيب لا مجرّد تنبيه المريض':
      'A severe interaction means contact the prescriber, not just warn the patient',
  'المصدر مذكور دائماً':
      'The source is always cited',
  'لتعود إليه حين تحتاج تفصيلاً أدقّ':
      'So you can go back to it for more detail',
  'فرص العمل':
      'Jobs',
  'وظائف الصيدلة في العراق، معروضة من أصحابها':
      'Pharmacy jobs in Iraq, posted by the employers',
  'فلتر بالمحافظة ونوع الدوام':
      'Filter by governorate and work type',
  'لتصل إلى ما يناسبك دون تصفّح كل الإعلانات':
      'Reach what suits you without browsing every ad',
  'انشر إعلانك':
      'Post your ad',
  'كل إعلان يُراجَع قبل نشره، فلا تظهر الإعلانات الوهمية':
      'Every ad is reviewed before publishing, so fake ads do not appear',
  'احفظ ما يعجبك':
      'Like what interests you',
  'الإعلانات الأكثر إعجاباً تتصدّر القائمة':
      'The most liked ads rise to the top',
  'أين يوجد الدواء الآن، من صيدلاني إلى صيدلاني':
      'Where the drug is right now, pharmacist to pharmacist',
  'أعلن عمّا عندك':
      'Announce what you have',
  'الدواء الموجود في صيدليتك قد يكون نقص زميل في محافظة أخرى':
      'A drug in your pharmacy may be a colleague\'s shortage in another governorate',
  'ابحث عمّا ينقصك':
      'Search for what you need',
  'فلتر بالمحافظة واتّصل بصاحب الإعلان مباشرة':
      'Filter by governorate and contact the advertiser directly',
  'كل إعلان مُراجَع':
      'Every ad is reviewed',
  'لا يظهر شيء للمستخدمين قبل الموافقة عليه':
      'Nothing appears to users before approval',
  'تاريخ العلبة للعبوة المغلقة. بعد الفتح تبدأ مدّة أقصر':
      'The pack date is for the sealed product. After opening a shorter period starts',
  'اضغط على الشكل الدوائي':
      'Tap the dosage form',
  'قطرة، أنسولين، شراب محضّر، كريم، لكلٍّ مدّته':
      'Drops, insulin, reconstituted syrup, cream: each has its period',
  'أدخل تاريخ الفتح':
      'Enter the opening date',
  'يحسب لك آخر يوم صالح وكم بقي':
      'It calculates the last valid day and how long is left',
  'اكتب التاريخ على العلبة':
      'Write the date on the pack',
  'عادة بسيطة تمنع أخطاء كثيرة في الصرف':
      'A simple habit that prevents many dispensing errors',
  'كم تكفي العلبة':
      'How Long the Pack Lasts',
  'سؤال المريض الدائم: متى أرجع أشتري؟':
      'The patient\'s constant question: when do I come back to buy?',
  'أدخل حجم العبوة':
      'Enter the pack size',
  'عدد الأقراص، أو حجم القنينة، أو وحدات القلم':
      'Number of tablets, bottle volume, or pen units',
  'ثم الجرعة وعدد المرّات':
      'Then the dose and frequency',
  'والحاسبة تعطي عدد الأيام وتاريخ النفاد':
      'The calculator gives the number of days and the run-out date',
  'ذكّر المريض قبل النفاد':
      'Remind the patient before it runs out',
  'تاريخ التذكير يظهر قبل خمسة أيام من النفاد':
      'The reminder date shows five days before run-out',
  'وحدات التحاليل':
      'Lab Units',
  'المختبرات تخلط بين الوحدات التقليدية والدولية':
      'Labs mix conventional and SI units',
  'ابحث عن التحليل':
      'Search for the test',
  'بالعربية أو الإنكليزية، أكثر من أربعين تحليلاً':
      'In Arabic or English, more than forty tests',
  'حوّل في الاتجاهين':
      'Convert both ways',
  'من ملغم/دل إلى ملمول/ل والعكس بضغطة':
      'From mg/dL to mmol/L and back in one tap',
  'المدى الطبيعي مرفق':
      'Normal range included',
  'لتعرف هل النتيجة داخل الحدود أم خارجها':
      'So you know whether the result is within limits',
  'جدول التلقيح':
      'Vaccination Schedule',
  'الجدول الوطني العراقي، محوّلاً إلى تواريخ حقيقية':
      'The Iraqi national schedule turned into real dates',
  'أدخل تاريخ ميلاد الطفل':
      'Enter the child\'s date of birth',
  'فيتحوّل الجدول العمري إلى تواريخ يفهمها الأهل':
      'The age-based schedule becomes dates parents understand',
  'الزيارات الفائتة تُعلَّم بالأحمر':
      'Missed visits are marked in red',
  'والمستحقّة الآن بالأخضر':
      'and those due now in green',
  'ولقاحات خارج الجدول':
      'Plus vaccines outside the schedule',
  'المكوّرات الرئوية والجدري المائي وغيرها، للعلم بها':
      'Pneumococcal, varicella and others, for your information',
  'تخفيض جرعات الكيماوي':
      'Chemo Dose Adjustment',
  'أداة مرجعية لتعديل الجرعة حسب وظائف الكبد والكلى':
      'A reference tool for adjusting the dose by liver and kidney function',
  'أدخل قيم المريض':
      'Enter the patient values',
  'الكرياتينين والبيليروبين وإنزيمات الكبد':
      'Creatinine, bilirubin and liver enzymes',
  'اقرأ القاعدة لا الرقم فقط':
      'Read the rule, not just the number',
  'الأداة تعرض القاعدة المرجعية التي بُني عليها التعديل':
      'The tool shows the reference rule the adjustment is based on',
  'القرار للطبيب المعالج':
      'The decision is the treating physician\'s',
  'هذه مرجعية سريرية مساعدة لا بديل عن بروتوكول المركز':
      'This is a supporting clinical reference, not a substitute for the centre protocol',
  'المريض المزمن يسأل «شنو كان علاجي؟» ويتوقّع منك أن تتذكّر':
      'The chronic patient asks “what was my treatment?” and expects you to remember',
  'بطاقة لكل زبون متكرّر':
      'A card for every regular customer',
  'اسمه وعمره وحالته المزمنة وأي حساسية عنده':
      'Name, age, chronic condition and any allergy',
  'علاجه وجرعته':
      'Treatment and dose',
  'الاسم يأتيك من قاعدة الأدوية، والجرعة بكلامك أنت':
      'The name comes from the drug database; the dose is in your own words',
  'وكم يوماً تكفي العلبة':
      'And how many days the pack lasts',
  'فيحسب التطبيق موعد إعادة الصرف ويُظهر من تأخّر':
      'So the app calculates the refill date and shows who is overdue',
  'كل شيء على هاتفك وحده':
      'Everything stays on your phone',
  'لا يُرفع إلى أي خادم. معلومات المرضى أمانة لا تُنشر':
      'Nothing is uploaded to any server. Patient information is a trust, not to be published',
  'قراءة الباركود':
      'Barcode Scanning',
  'الرقم على العلبة لا يحمل اسم الدواء':
      'The number on the pack does not carry the drug name',
  'ما الذي يقرأه التطبيق':
      'What the app reads',
  'الكاميرا تقرأ الرقم التسلسلي فقط، والخطوط ترميز لهذا الرقم':
      'The camera reads the serial number only; the bars encode that number',
  'الاسم يأتي من قاعدة ربط':
      'The name comes from a linking database',
  'إن كان الرقم معروفاً ظهر الاسم فوراً وبُحث عنه':
      'If the number is known, the name appears at once and is searched',
  'وإن كان مجهولاً':
      'And if it is unknown',
  'تقترح اسمه مرّة واحدة، وبعد مراجعة الإدارة يصير معروفاً لكل صيادلة التطبيق':
      'You suggest its name once, and after admin review it becomes known to every pharmacist using the app',
  'فهمت، لنبدأ':
      'Got it, let\'s start',
  'لن تظهر هذه الشاشة مرّة أخرى':
      'This screen will not show again',
  'الباركود رقم تسلسلي لا يحمل اسم الدواء. اربطه بالدواء الصحيح فيصبح معروفاً لكل مستخدمي التطبيق فوراً':
      'A barcode is a serial number and does not carry the drug name. Link it to the correct drug and it becomes known to all app users at once',
  'الباركود رقم تسلسلي لا يحمل اسم الدواء. اكتب اسم الدواء الذي على العلبة ليصل اقتراحك للمراجعة، ولا يُعتمد قبل التأكّد منه':
      'A barcode is a serial number and does not carry the drug name. Type the drug name on the pack to send your suggestion for review; it is not adopted until verified',
  'التداخلات أكثر ما يُغفل في الصيدلية. أعد المحاولة بأزواج جديدة':
      'Interactions are what gets missed most in the pharmacy. Try again with new pairs',
  'عشرة حسابات صيدلانية في دقيقتين: جرعة بالوزن، حجم من شراب، معدل تسريب، قطرات في الدقيقة، وتخفيف\n\nالنقاط = 100 لكل جواب صحيح + 5 لكل ثانية متبقّيةالهامش المقبول 2٪ فلا حاجة لدقّة المنازل العشرية':
      'Ten pharmacy calculations in two minutes: weight-based dose, volume from a syrup, infusion rate, drops per minute, and dilution\n\nPoints = 100 per correct answer + 5 per second left',
  'أداة مساعدة للقرار. النتيجة لا تُغني عن بروتوكول المركز العلاجي ولا عن قرار الطبيب المعالج، ولا تشمل التعديل بسبب السمّية التراكمية أو التداخلات':
      'A decision-support tool. The result does not replace the treatment centre protocol or the treating physician, and does not cover adjustments for cumulative toxicity or interactions',
  'يُستعمل GFR المحسوب بـ Cockcroft-Gault أعلاه. كثير من المراكز تضع سقفاً لـ GFR عند 125 mL/min لتفادي الجرعات المفرطة':
      'Uses the GFR calculated by Cockcroft-Gault above. Many centres cap GFR at 125 mL/min to avoid overdosing',
};
