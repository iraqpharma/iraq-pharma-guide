import 'package:flutter/material.dart';

class AppStrings {
  final bool isAr;
  const AppStrings(this.isAr);

  // ── App ───────────────────────────────────────────────────────────────────
  String get appName       => isAr ? 'دليل الصيدلة العراقي' : 'Iraq Pharma Guide';
  String get appSubtitle   => isAr ? 'Iraq Pharma Guide'    : 'دليل الصيدلة العراقي';

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  String get navFavorites  => isAr ? 'المفضلة'  : 'Favorites';
  String get navTools      => isAr ? 'الأدوات'  : 'Tools';
  String get navHome       => isAr ? 'الرئيسية' : 'Home';
  String get navSearch     => isAr ? 'بحث'      : 'Search';
  String get navAccount    => isAr ? 'حسابي'    : 'Account';

  // ── Home ──────────────────────────────────────────────────────────────────
  String get browseByCategory  => isAr ? 'استعراض حسب الفصيلة' : 'Browse by Category';
  String get viewAll           => isAr ? 'عرض الكل'             : 'View All';
  String get quickTools        => isAr ? 'أدوات سريعة'          : 'Quick Tools';
  String get adSpace           => isAr ? 'مساحة إعلانية'        : 'Ad Space';
  String get ad                => isAr ? 'إعلان'                : 'Ad';

  // OTC Banner
  String get otcMedicines      => isAr ? 'أدوية OTC'                          : 'OTC Medicines';
  String get otcSubtitle       => isAr ? 'الأدوية المتاحة بدون وصفة طبية'    : 'Over-the-counter medications';
  String get otcSections       => isAr ? '7 أقسام طبية'                       : '7 Medical Sections';
  String get otcDrugs          => isAr ? '+30 دواء'                           : '+30 Drugs';

  // Price Guide Banner
  String get priceGuide        => isAr ? 'دليل الأسعار التجاري'    : 'Commercial Price Guide';
  String get priceGuideSubtitle=> isAr ? 'تكلفة • بيع • هامش الربح' : 'Cost • Sale • Profit Margin';

  // ── Search ────────────────────────────────────────────────────────────────
  String get searchDrug        => isAr ? 'بحث عن دواء'                                    : 'Search for Drug';
  String get searchHint        => isAr ? 'ابحث عن اسم الدواء'                             : 'Search by drug name';
  String get searchSubHint     => isAr ? 'بالاسم العلمي أو التجاري أو عن طريق مسح الباركود' : 'By generic or trade name, or scan barcode';
  String get searchError       => isAr ? 'خطأ' : 'Error';
  String get noResultsTitle    => isAr ? 'عذراً، لم نعثر على هذا الدواء'   : 'Sorry, drug not found';
  String get noResultsPrefix   => isAr ? 'لم يتم العثور على نتائج لـ "'   : 'No results found for "';
  String get noResultsSuffix   => '"';
  String get noResultsHint     => isAr ? 'تحقق من الإملاء أو جرب اسماً مختلفاً' : 'Check spelling or try a different name';
  String get suggestDrugBtn    => isAr ? 'اقتراح إضافة هذا الدواء' : 'Suggest Adding This Drug';
  String get suggestDrugHint   => isAr ? 'سيصل طلبك للفريق لمراجعته وإضافة الدواء' : 'Your request will be reviewed by the team';

  // Drug Request Sheet
  String get suggestDrug       => isAr ? 'اقتراح إضافة دواء'                  : 'Suggest Adding a Drug';
  String get suggestDrugSub    => isAr ? 'سيصل طلبك للفريق مباشرةً للمراجعة' : 'Your request will go directly to the team';
  String get drugName          => isAr ? 'اسم الدواء'         : 'Drug Name';
  String get chooseCat         => isAr ? 'اختر القسم'         : 'Choose Category';
  String get sending           => isAr ? 'جاري الإرسال...'   : 'Sending...';
  String get sendRequest       => isAr ? 'إرسال الطلب'        : 'Send Request';
  String get requestSent       => isAr ? 'تم إرسال الطلب!'   : 'Request Sent!';
  String get requestSentSub    => isAr ? 'سيراجع الفريق طلبك ويضيف الدواء قريباً' : 'The team will review your request and add the drug soon';
  String get ok                => isAr ? 'حسناً' : 'OK';
  String get errorRetry        => isAr ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, please try again';
  String get enterDrugName     => isAr ? 'أدخل اسم الدواء' : 'Enter drug name';
  String get chooseCatValidate => isAr ? 'اختر القسم'       : 'Choose a category';

  // Drug request categories
  List<String> get drugCategories => isAr ? [
    'قلب وأوعية', 'مضادات حيوية', 'سكري', 'مسكنات وألم',
    'جهاز هضمي', 'أعصاب ونفسية', 'فيتامينات ومقويات',
    'جلدية وكوزمتك', 'جهاز تنفسي', 'أدوية مخدرة', 'أخرى',
  ] : [
    'Cardiovascular', 'Antibiotics', 'Diabetes', 'Analgesics & Pain',
    'Gastroenterology', 'Neurology & Psychiatry', 'Vitamins & Supplements',
    'Dermatology & Cosmetic', 'Respiratory', 'Controlled & Narcotics', 'Other',
  ];

  // ── Favorites ─────────────────────────────────────────────────────────────
  String get favorites         => isAr ? 'المفضلة'                         : 'Favorites';
  String get noFavorites       => isAr ? 'لا توجد أدوية محفوظة'           : 'No saved drugs';
  String get noFavoritesSub    => isAr ? 'افتح أي دواء واضغط "المفضلة" لحفظه' : 'Open any drug and tap "Favorites" to save it';
  String get select            => isAr ? 'تحديد'        : 'Select';
  String get cancel            => isAr ? 'إلغاء'        : 'Cancel';
  String get selectAll         => isAr ? 'تحديد الكل'  : 'Select All';
  String get deselectAll       => isAr ? 'إلغاء الكل'  : 'Deselect All';
  String get chooseDrugs       => isAr ? 'اختر الأدوية' : 'Choose drugs';
  String get removeSelected    => isAr ? 'إزالة المحدد' : 'Remove Selected';
  String get nothingSelected   => isAr ? 'لم يتم تحديد شيء' : 'Nothing selected';
  String get removeFromFav     => isAr ? 'إزالة من المفضلة' : 'Remove from Favorites';
  String get removeAll         => isAr ? 'إزالة الكل'        : 'Remove All';
  String get removeAllConfirm  => isAr ? 'سيتم مسح جميع الأدوية من المفضلة. هل أنت متأكد؟'
                                       : 'All drugs will be removed from favorites. Are you sure?';
  String selectedCount(int n)  => isAr ? 'تم تحديد $n' : '$n selected';
  String removeDrug(String name) => isAr
      ? 'هل تريد إزالة "$name" من المفضلة؟'
      : 'Remove "$name" from favorites?';
  String removeNDrugs(int n) => isAr
      ? 'إزالة $n ${n == 1 ? "دواء" : "أدوية"}'
      : 'Remove $n ${n == 1 ? "drug" : "drugs"}';
  String willRemove(String names) => isAr
      ? 'سيتم إزالة:\n$names\nمن المفضلة. هل أنت متأكد؟'
      : 'Will remove:\n$names\nfrom favorites. Are you sure?';
  String get remove            => isAr ? 'إزالة' : 'Remove';
  String get other             => isAr ? 'أخرى'  : 'Other';

  // ── Tools Tab ────────────────────────────────────────────────────────────
  String get clinicalTools     => isAr ? 'الأدوات السريرية'                        : 'Clinical Tools';
  String get doseCalc          => isAr ? 'حاسبة الجرعة'                            : 'Dose Calculator';
  String get doseCalcSub       => isAr ? 'احسب الجرعة للأطفال والبالغين بدقة'     : 'Calculate dose for children and adults';
  String get crcl              => isAr ? 'حاسبة CrCl'                              : 'CrCl Calculator';
  String get crclSub           => isAr ? 'تصفية الكرياتينين — معادلة Cockcroft-Gault' : 'Creatinine Clearance — Cockcroft-Gault';
  String get interactions      => isAr ? 'فاحص التفاعلات'     : 'Interaction Checker';
  String get interactionsSub   => isAr ? 'تفاعلات الأدوية'    : 'Drug Interactions';
  String get notebook          => isAr ? 'دفتر الصيدلاني'     : 'Pharmacist Notebook';
  String get notebookSub       => isAr ? 'الأدوية المفقودة'   : 'Missing Drugs';
  String get pricingCalc       => isAr ? 'حاسبة التسعير'      : 'Pricing Calculator';
  String get pricingCalcSub    => isAr ? 'حاسبة التسعير الذكية' : 'Smart Pricing Calculator';
  String get substitution      => isAr ? 'الباحث عن البدائل'  : 'Substitution Finder';
  String get substitutionSub   => isAr ? 'البديل الذكي'       : 'Smart Substitution';

  // ── Drawer (hamburger menu) ─────────────────────────────────────────────────
  String get pricesSectionLabel   => isAr ? 'الأسعار' : 'Prices';
  String get drawerInteractionsSub => isAr ? 'تفاعلات الأدوية المتعددة' : 'Multiple drug interactions';
  String get drawerNotebookSub    => isAr ? 'الأدوية المفقودة والملاحظات' : 'Missing drugs and notes';
  String get drawerPricingSub     => isAr ? 'تكلفة الوحدة وسعر البيع' : 'Unit cost and selling price';
  String get drawerSubstitutionSub => isAr ? 'البدائل المباشرة والعلاجية' : 'Direct and therapeutic alternatives';

  // Quick filters
  String get safePregnancy     => isAr ? 'آمن للحمل'    : 'Safe for Pregnancy';
  String get refrigerated      => isAr ? 'مبرّد'         : 'Refrigerated';
  String get renalAdjust       => isAr ? 'تعديل كلوي'   : 'Renal Adjustment';
  String get pediatricDrops    => isAr ? 'قطرات أطفال'  : 'Pediatric Drops';

  // ── Profile ───────────────────────────────────────────────────────────────
  String get myAccount         => isAr ? 'حسابي'                      : 'My Account';
  String get editProfile       => isAr ? 'تعديل البيانات الشخصية'    : 'Edit Personal Data';
  String get interactiveRef    => isAr ? 'المرجع التفاعلي'            : 'Interactive Reference';
  String get appLanguage       => isAr ? 'لغة التطبيق'               : 'App Language';
  String get darkMode          => isAr ? 'الوضع الداكن'              : 'Dark Mode';
  String get support           => isAr ? 'قسم الدعم'                 : 'Support';
  String get sendSuggestion    => isAr ? 'إرسال اقتراح'              : 'Send Suggestion';
  String get privacyPolicy     => isAr ? 'سياسة الخصوصية'            : 'Privacy Policy';
  String get termsOfUse        => isAr ? 'شروط الاستخدام'            : 'Terms of Use';
  String get disclaimer        => isAr ? 'إخلاء المسؤولية'           : 'Disclaimer';
  String get signOut           => isAr ? 'تسجيل الخروج'              : 'Sign Out';
  String get signOutConfirm    => isAr ? 'هل أنت متأكد من تسجيل الخروج؟' : 'Are you sure you want to sign out?';
  String get drugSearchStat    => isAr ? 'بحث دواء'         : 'Drug Search';
  String get toolUsageStat     => isAr ? 'استخدام الأدوات'  : 'Tool Usage';
  String get version           => isAr ? 'الإصدار'          : 'Version';
  String get langDialogTitle   => isAr ? 'لغة التطبيق'      : 'App Language';

  // ── Auth — Login ──────────────────────────────────────────────────────────
  String get loginTitle        => isAr ? 'تسجيل الدخول'          : 'Sign In';
  String get loginSubtitle     => isAr ? 'أهلاً بعودتك'          : 'Welcome back';
  String get emailOrPhone      => isAr ? 'البريد / الهاتف / اسم المستخدم' : 'Email / Phone / Username';
  String get password          => isAr ? 'كلمة المرور'            : 'Password';
  String get forgotPassword    => isAr ? 'نسيت كلمة المرور؟'     : 'Forgot Password?';
  String get signIn            => isAr ? 'تسجيل الدخول'           : 'Sign In';
  String get signingIn         => isAr ? 'جاري الدخول...'         : 'Signing in...';
  String get orSignInWith      => isAr ? 'أو سجّل الدخول بـ'      : 'Or sign in with';
  String get googleSignIn      => isAr ? 'Google'                 : 'Google';
  String get noAccount         => isAr ? 'ليس لديك حساب؟'        : 'Don\'t have an account?';
  String get registerNow       => isAr ? 'سجّل الآن'              : 'Register Now';
  String get welcomeBack       => isAr ? 'أهلاً بعودتك!'          : 'Welcome Back!';
  String get loginSuccess      => isAr ? 'تم تسجيل الدخول بنجاح.' : 'Signed in successfully.';

  // ── Auth — Sign Up ────────────────────────────────────────────────────────
  String get createAccount     => isAr ? 'إنشاء حساب'             : 'Create Account';
  String get joinCommunity     => isAr ? 'انضم لمجتمع الصيادلة'   : 'Join the pharmacists community';
  String get fullName          => isAr ? 'الاسم الكامل'            : 'Full Name';
  String get username          => isAr ? 'اسم المستخدم'            : 'Username';
  String get email             => isAr ? 'البريد الإلكتروني'       : 'Email';
  String get passwordField     => isAr ? 'كلمة المرور'             : 'Password';
  String get confirmPassword   => isAr ? 'تأكيد كلمة المرور'      : 'Confirm Password';
  String get role              => isAr ? 'الصفة المهنية'           : 'Professional Role';
  String get birthDate         => isAr ? 'تاريخ الميلاد'           : 'Date of Birth';
  String get address           => isAr ? 'العنوان'                 : 'Address';
  String get optional          => isAr ? 'اختياري'                 : 'Optional';
  String get signUp            => isAr ? 'إنشاء الحساب'            : 'Create Account';
  String get signingUp         => isAr ? 'جاري الإنشاء...'         : 'Creating...';
  String get alreadyHaveAccount => isAr ? 'لديك حساب بالفعل؟'     : 'Already have an account?';
  String get signInNow         => isAr ? 'سجّل الدخول'             : 'Sign In';
  String get accountCreated    => isAr ? 'تم إنشاء الحساب بنجاح!' : 'Account created successfully!';
  String get accountCreatedSub => isAr
      ? 'أهلاً بك في مجتمع الصيادلة في العراق.\nيمكنك الآن البدء باستكشاف دليل الأدوية والأدوات السريرية.'
      : 'Welcome to the Iraq pharmacists community.\nYou can now explore the drug guide and clinical tools.';
  String get startNow          => isAr ? 'ابدأ الآن' : 'Start Now';
  String get verifyEmailTitle  => isAr ? 'تحقق من بريدك الإلكتروني' : 'Verify your email';
  String get verifyEmailSub    => isAr
      ? 'تم إرسال رابط التحقق إلى بريدك الإلكتروني.\nافتح الإيميل واضغط على الرابط لتفعيل حسابك.'
      : 'A verification link has been sent to your email.\nOpen it to activate your account.';
  String get goToLogin         => isAr ? 'الذهاب إلى تسجيل الدخول' : 'Go to Login';
  String get didntReceiveEmail => isAr ? 'لم تستلم الإيميل؟ تحقق من مجلد Spam' : "Didn't receive it? Check your Spam folder";

  // ── Auth — Sign Up fields ─────────────────────────────────────────────────
  String get firstName         => isAr ? 'الاسم الأول'            : 'First Name';
  String get middleName        => isAr ? 'الاسم الأوسط (اختياري)' : 'Middle Name (Optional)';
  String get lastName          => isAr ? 'الاسم الأخير'           : 'Last Name';
  String get usernameField     => isAr ? 'اسم المستخدم'           : 'Username';
  String get usernameHint      => isAr ? 'يُملأ تلقائياً من الاسم' : 'Auto-filled from name';
  String get phoneOptional     => isAr ? 'رقم الهاتف (اختياري)'   : 'Phone Number (Optional)';
  String get profession        => isAr ? 'المهنة'                  : 'Profession';
  String get newAccount        => isAr ? 'إنشاء حساب جديد'        : 'Create New Account';
  String get newAccountSub     => isAr ? 'أدخل بياناتك للتسجيل في دليل الصيدلة العراقي'
                                       : 'Enter your details to register in Iraq Pharma Guide';
  String get agreePrefix       => isAr ? 'أوافق على ' : 'I agree to the ';
  String get agreeAnd          => isAr ? ' و'          : ' and ';
  String get rememberMe        => isAr ? 'تذكرني'      : 'Remember me';
  String get continueGoogle    => isAr ? 'المتابعة عبر Google' : 'Continue with Google';
  String get continueApple     => isAr ? 'المتابعة عبر Apple' : 'Continue with Apple';
  String get continueWithLabel => isAr ? 'المتابعة عبر'       : 'Continue with';
  String get orWith            => isAr ? 'أو'          : 'or';
  String get loginSubHint      => isAr ? 'البريد الإلكتروني · رقم الهاتف · اسم المستخدم'
                                       : 'Email · Phone · Username';
  String get universalFieldLabel => isAr ? 'البريد / رقم الهاتف / اسم المستخدم'
                                         : 'Email / Phone / Username';
  String get phoneExample      => isAr ? 'مثال: 07xxxxxxxxx' : 'Example: +964xxxxxxxxx';

  // Username status
  String get usernameAvailable => isAr ? 'متاح ✓'           : 'Available ✓';
  String get usernameTaken     => isAr ? 'مستخدم بالفعل'    : 'Already taken';
  String get usernameTooShort  => isAr ? '4 أحرف على الأقل' : 'At least 4 characters';

  // Roles
  List<String> get roles => isAr
      ? ['مدير صيدلية', 'صيدلاني متدرب', 'معاون صيدلي']
      : ['Pharmacy Manager', 'Trainee Pharmacist', 'Pharmacy Assistant'];

  // Governorates (no translation needed — same in both)
  List<String> get governorates => [
    'بغداد', 'البصرة', 'نينوى', 'أربيل', 'السليمانية', 'كركوك',
    'الأنبار', 'ديالى', 'صلاح الدين', 'بابل', 'كربلاء', 'النجف',
    'الديوانية', 'ميسان', 'واسط', 'ذي قار', 'المثنى', 'دهوك',
  ];

  // Validators
  String get enterFirstName    => isAr ? 'أدخل الاسم الأول'    : 'Enter first name';
  String get enterLastName     => isAr ? 'أدخل الاسم الأخير'   : 'Enter last name';
  String get enterUsername     => isAr ? 'أدخل اسم المستخدم'   : 'Enter username';
  String get enterEmail        => isAr ? 'أدخل البريد الإلكتروني' : 'Enter email address';
  String get invalidEmail      => isAr ? 'بريد إلكتروني غير صحيح' : 'Invalid email address';
  String get emailTooLong      => isAr ? 'البريد الإلكتروني طويل جداً' : 'Email is too long';
  String get enterPhone        => isAr ? 'أدخل رقم الهاتف'     : 'Enter phone number';
  String get invalidPhone      => isAr ? 'رقم الهاتف غير صحيح' : 'Invalid phone number';
  String get enterPassword     => isAr ? 'أدخل كلمة المرور'    : 'Enter password';
  String get passwordTooShort  => isAr ? '6 أحرف على الأقل'    : 'At least 6 characters';
  String get reEnterPassword   => isAr ? 'أعد إدخال كلمة المرور' : 'Re-enter password';
  String get passwordMismatch  => isAr ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  String get chooseProfession  => isAr ? 'اختر مهنتك'          : 'Choose your profession';
  String get usernameTakenErr  => isAr ? 'اسم المستخدم مستخدم' : 'Username is taken';
  String get enterIdentifier   => isAr ? 'أدخل البريد الإلكتروني أو رقم الهاتف أو اسم المستخدم'
                                       : 'Enter email, phone or username';
  String get chooseProfessionFirst => isAr ? 'يرجى اختيار المهنة' : 'Please choose a profession';
  String get usernameTakenFull  => isAr ? 'اسم المستخدم مستخدم بالفعل' : 'Username is already taken';
  String get agreeToTermsErr    => isAr ? 'يجب الموافقة على الشروط وسياسة الخصوصية للمتابعة'
                                        : 'You must agree to the Terms and Privacy Policy';
  String get checkingUsername   => isAr ? 'جارٍ التحقق من اسم المستخدم…' : 'Checking username…';

  // ── Auth — Forgot Password ────────────────────────────────────────────────
  String get forgotPasswordTitle   => isAr ? 'نسيت كلمة المرور'       : 'Forgot Password';
  String get forgotPasswordSub     => isAr ? 'أدخل بريدك الإلكتروني وسنرسل رابط إعادة التعيين' : 'Enter your email and we\'ll send a reset link';
  String get sendResetLink         => isAr ? 'إرسال رابط الاسترداد'   : 'Send Reset Link';
  String get resetLinkSent         => isAr ? 'تم الإرسال!'             : 'Sent!';
  String get resetLinkSentSub      => isAr ? 'تحقق من بريدك الإلكتروني لإعادة تعيين كلمة المرور' : 'Check your email to reset your password';
  String get backToLogin           => isAr ? 'العودة لتسجيل الدخول'   : 'Back to Sign In';

  // ── OTP ───────────────────────────────────────────────────────────────────
  String get otpTitle          => isAr ? 'التحقق من البريد الإلكتروني' : 'Email Verification';
  String get otpSentTo         => isAr ? 'أرسلنا رمز مكون من'          : 'We sent a';
  String get otpDigits         => isAr ? 'أرقام إلى'                   : 'digit code to';
  String get verifyCode        => isAr ? 'تحقق من الرمز'               : 'Verify Code';
  String get noCode            => isAr ? 'لم تستلم الرمز؟'             : 'Didn\'t receive the code?';
  String get resend            => isAr ? 'إعادة الإرسال'               : 'Resend';

  // ── Notifications ─────────────────────────────────────────────────────────
  String get notifications     => isAr ? 'الإشعارات'                      : 'Notifications';
  String get noNotifications   => isAr ? 'لا توجد إشعارات'               : 'No Notifications';
  String get enableNotifFromSettings => isAr
      ? 'الإذن مرفوض من إعدادات الجهاز — فعّله من الإعدادات أولاً'
      : 'Permission denied at the device level — enable it from Settings first';
  String get noNotificationsSub=> isAr ? 'ستظهر هنا الإشعارات والتنبيهات الجديدة' : 'New notifications and alerts will appear here';

  // ── Notification Permission ───────────────────────────────────────────────
  String get notifPermTitle => isAr ? 'تفعيل التنبيهات'   : 'Enable Notifications';
  String get notifPermSub   => isAr
      ? 'كن أول من يعلم بآخر تحديثات الأدوية،\nتغييرات الأسعار، والتنبيهات الطبية الهامة.'
      : 'Be the first to know about drug updates,\nprice changes, and important medical alerts.';
  String get enabling       => isAr ? 'جارٍ التفعيل…' : 'Enabling…';
  String get enableNow      => isAr ? 'تفعيل الآن'    : 'Enable Now';
  String get notNow         => isAr ? 'ليس الآن'      : 'Not Now';

  // ── Edit Profile ──────────────────────────────────────────────────────────
  String get changePassword        => isAr ? 'تغيير كلمة المرور'              : 'Change Password';
  String get currentPassword       => isAr ? 'كلمة المرور الحالية'            : 'Current Password';
  String get newPassword           => isAr ? 'كلمة المرور الجديدة'            : 'New Password';
  String get confirmNewPassword    => isAr ? 'تأكيد كلمة المرور الجديدة'     : 'Confirm New Password';
  String get enterCurrentPassword  => isAr ? 'أدخل كلمة المرور الحالية'      : 'Enter current password';
  String get enterNewPassword      => isAr ? 'أدخل كلمة المرور الجديدة'      : 'Enter new password';
  String get passwordChangedSuccess=> isAr ? 'تم تغيير كلمة المرور بنجاح'   : 'Password changed successfully';
  String get personalData          => isAr ? 'البيانات الشخصية'               : 'Personal Data';
  String get governorate           => isAr ? 'المحافظة'                        : 'Governorate';
  String get birthDateOptional     => isAr ? 'تاريخ الميلاد (اختياري)'       : 'Date of Birth (Optional)';
  String get birthDateHint         => isAr ? 'مثال: 1995/06/15'               : 'e.g. 1995/06/15';
  String get saveChanges           => isAr ? 'حفظ التغييرات'                  : 'Save Changes';
  String get profileSavedSuccess   => isAr ? 'تم حفظ البيانات بنجاح'         : 'Profile saved successfully';
  String get chooseProfessionErr   => isAr ? 'اختر المهنة'                    : 'Choose your profession';

  // ── Profile completion prompt (post-login, optional) ────────────────────
  String get completeProfileTitle  => isAr ? 'أكمل ملفك الشخصي'                : 'Complete your profile';
  String get completeProfileSub    => isAr ? 'أضف محافظتك وتاريخ ميلادك وصورتك — كل هذا اختياري ويمكنك تخطيه الآن'
                                            : 'Add your governorate, birth date and photo — all optional, you can skip for now';
  String get addPhotoLabel         => isAr ? 'إضافة صورة'                     : 'Add photo';
  String get skipForNow            => isAr ? 'تخطي الآن'                      : 'Skip for now';

  // ── Drug List ─────────────────────────────────────────────────────────────
  String get noDrugsInCategory  => isAr ? 'لا توجد أدوية في هذا الصنف' : 'No drugs in this category';
  String get searchInCategory   => isAr ? 'بحث في'                     : 'Search in';
  String drugCount(int n)       => isAr ? '$n دواء' : '$n drug${n == 1 ? '' : 's'}';

  // Category labels (bilingual map)
  Map<String, String> get categoryLabels => isAr ? const {
    'antibiotics':     'مضادات حيوية',
    'cardiovascular':  'قلب وأوعية',
    'diabetes':        'سكري',
    'analgesics':      'مسكنات وألم',
    'neurology':       'أعصاب ونفسية',
    'gastrointestinal':'جهاز هضمي',
    'respiratory':     'جهاز تنفسي',
    'vitamins':        'فيتامينات ومقويات',
    'cosmetic':        'كوزمتك وجلدية',
    'narcotics':       'أدوية مخدرة',
    'other':           'أخرى',
  } : const {
    'antibiotics':     'Antibiotics',
    'cardiovascular':  'Cardiovascular',
    'diabetes':        'Diabetes',
    'analgesics':      'Analgesics & Pain',
    'neurology':       'Neurology & Psychiatry',
    'gastrointestinal':'Gastroenterology',
    'respiratory':     'Respiratory',
    'vitamins':        'Vitamins & Supplements',
    'cosmetic':        'Dermatology & Cosmetic',
    'narcotics':       'Controlled & Narcotics',
    'other':           'Other',
  };

  // Drug Detail titles
  String get mechanism         => isAr ? 'آلية العمل'            : 'Mechanism of Action';
  String get indications       => isAr ? 'الاستطبابات'           : 'Indications';
  String get adultDose         => isAr ? 'جرعة البالغين'         : 'Adult Dose';
  String get pediatricDose     => isAr ? 'جرعة الأطفال'          : 'Pediatric Dose';
  String get renalDose         => isAr ? 'تعديل القصور الكلوي'   : 'Renal Adjustment';
  String get hepaticDose       => isAr ? 'تعديل القصور الكبدي'   : 'Hepatic Adjustment';
  String get contraindications => isAr ? 'موانع الاستخدام'       : 'Contraindications';
  String get sideEffects       => isAr ? 'الآثار الجانبية'       : 'Side Effects';
  String get drugInteractions  => isAr ? 'التفاعلات الدوائية'    : 'Drug Interactions';
  String get pharmacokinetics  => isAr ? 'الحرائك الدوائية'      : 'Pharmacokinetics';
  String get counselingNote    => isAr ? 'ملاحظة صيدلانية'       : 'Pharmacist Note';
  String get tradeNames        => isAr ? 'الأسماء التجارية'       : 'Trade Names';
  String get noInfo            => isAr ? 'لا تتوفر معلومات'      : 'No information available';
  String get drugNotFound      => isAr ? 'الدواء غير موجود'      : 'Drug not found';
  String get addToChecker      => isAr ? 'إضافة للفاحص'          : 'Add to Checker';
  String get addedToFav        => isAr ? 'أُضيف إلى المفضلة'     : 'Added to Favorites';
  String get removedFromFav    => isAr ? 'أُزيل من المفضلة'      : 'Removed from Favorites';
  String get lasaWarning       => isAr ? 'تحذير LASA'            : 'LASA Warning';
  String get lasaSub           => isAr ? 'يشبه في الاسم أو الشكل:' : 'Looks-alike / Sounds-alike:';

  // Drug Detail extras
  String get administrationTitle => isAr ? 'طريقة الإعطاء'          : 'Administration';
  String get monitoringTitle     => isAr ? 'المراقبة الصيدلانية'    : 'Pharmacist Monitoring';
  String get pregnancyLactation  => isAr ? 'الحمل والرضاعة'         : 'Pregnancy & Lactation';
  String get pregnancyCat        => isAr ? 'فئة الحمل'              : 'Pregnancy Category';
  String get lactationHale       => isAr ? 'الرضاعة (Hale)'         : 'Lactation (Hale)';
  String get blackBoxWarning     => isAr ? 'تحذير الصندوق الأسود'   : 'Black Box Warning';
  String get ivTitle             => isAr ? 'IV — التحضير والإعطاء'  : 'IV — Preparation & Administration';
  String get pharmacistNote      => isAr ? 'نصيحة الصيدلاني'        : 'Pharmacist Tip';
  String get refrigeratedLabel   => isAr ? 'مبرّد'                  : 'Refrigerated';
  String get unknown             => isAr ? 'غير محدد'               : 'Unknown';
  // Pregnancy badge labels
  String get pregSafe        => isAr ? 'آمن'         : 'Safe';
  String get pregRelSafe     => isAr ? 'آمن نسبياً'  : 'Relatively Safe';
  String get pregCaution     => isAr ? 'بحذر'         : 'With Caution';
  String get pregRisk        => isAr ? 'خطر'          : 'Risk';
  String get pregContra      => isAr ? 'ممنوع'         : 'Contraindicated';
  // Lactation labels
  String get lactL1 => isAr ? 'L1 آمن جداً'   : 'L1 Very Safe';
  String get lactL2 => isAr ? 'L2 آمن'        : 'L2 Safe';
  String get lactL3 => isAr ? 'L3 بحذر'       : 'L3 Caution';
  String get lactL4 => isAr ? 'L4 خطر'        : 'L4 Risk';
  String get lactL5 => isAr ? 'L5 ممنوع'      : 'L5 Contraindicated';
  // Bottom actions
  String addedToFavMsg(String name) => isAr ? '$name أُضيف للمفضلة' : '$name added to Favorites';

  // Interactions screen
  String get interactionChecker => isAr ? 'فاحص التفاعلات الدوائية' : 'Drug Interaction Checker';
  String get addDrugsHint       => isAr ? 'أضف الأدوية للفحص (2-8 أدوية)' : 'Add drugs to check (2–8 drugs)';
  String get clearAll           => isAr ? 'مسح الكل'                 : 'Clear All';
  String get addDrug            => isAr ? 'إضافة دواء'               : 'Add Drug';
  String get noInteractions     => isAr ? 'لا توجد تفاعلات مسجّلة'  : 'No recorded interactions';
  String get noInteractionsSub  => isAr ? 'بين الأدوية المحددة'      : 'between the selected drugs';
  String get interactionFound   => isAr ? 'تفاعل دوائي'              : 'Drug Interaction';
  String get addDrugsToStart    => isAr ? 'أضف دواءين على الأقل للتحقق من التفاعلات' : 'Add at least 2 drugs to check interactions';
  String get oneDrugAdded       => isAr ? 'أضف دواءً آخر للمقارنة'  : 'Add another drug to compare';

  // ── Dosage Calculator ─────────────────────────────────────────────────────
  String get tabChildren      => isAr ? 'الأطفال'    : 'Pediatric';
  String get tabAdults        => isAr ? 'البالغون'   : 'Adult';
  String get childWeight      => isAr ? 'وزن الطفل'               : 'Child Weight';
  String get adultWeight      => isAr ? 'وزن البالغ (اختياري)'   : 'Adult Weight (Optional)';
  String get dosePerKg        => isAr ? 'الجرعة'                  : 'Dose';
  String get maxDoseOptional  => isAr ? 'الجرعة القصوى (اختياري)' : 'Max Dose (Optional)';
  String get dailyFreq        => isAr ? 'عدد الجرعات يومياً (اختياري)' : 'Daily Frequency (Optional)';
  String get calculate        => isAr ? 'احسب'        : 'Calculate';
  String get reset_           => isAr ? 'مسح'         : 'Reset';
  String get totalDose        => isAr ? 'الجرعة الكلية' : 'Total Dose';
  String get doseCapped       => isAr ? 'الجرعة المحسوبة (بُقيدت عند الحد القصوى)' : 'Calculated Dose (Capped at Max)';
  String get capNote          => isAr ? 'تجاوزت الحد القصوى — تم تحديد الجرعة عنده' : 'Exceeded max dose — capped at maximum';
  String get dailyDose        => isAr ? 'الجرعة اليومية' : 'Daily Dose';
  String get perDose          => isAr ? 'الجرعة الواحدة' : 'Per-Dose';
  String get formula          => isAr ? 'المعادلة'       : 'Formula';
  String get pediatricFormula => isAr ? 'الجرعة = الوزن (كغ) × الجرعة (مغ/كغ)'  : 'Dose = Weight (kg) × Dose (mg/kg)';
  String get adultFormula     => isAr ? 'الجرعة اليومية = الوزن × الجرعة\nالجرعة الواحدة = الجرعة اليومية ÷ التكرار'
                                      : 'Daily Dose = Weight × Dose\nPer-Dose = Daily ÷ Frequency';
  String get pediatricBanner  => isAr ? 'احسب جرعة الطفل بحسب وزنه (مغ/كغ). أدخل الجرعة القصوى لمنع التجاوز.'
                                      : 'Calculate pediatric dose by weight (mg/kg). Enter max dose to prevent overdosing.';
  String get adultBanner      => isAr ? 'احسب الجرعة اليومية والجرعة الواحدة بناءً على الوزن والتكرار.'
                                      : 'Calculate daily and per-dose based on weight and frequency.';
  String get kgUnit           => isAr ? 'كغ'    : 'kg';
  String get mgKgUnit         => isAr ? 'مغ/كغ' : 'mg/kg';
  String get mgUnit           => isAr ? 'مغ'    : 'mg';
  String get timesDay         => isAr ? 'مرة/يوم' : 'times/day';

  // ── Interaction Checker ───────────────────────────────────────────────────
  String get searchAddDrug    => isAr ? 'ابحث عن دواء للإضافة...' : 'Search a drug to add...';
  String get severityMajor    => isAr ? 'خطير'  : 'Major';
  String get severityModerate => isAr ? 'متوسط' : 'Moderate';
  String get severityMinor    => isAr ? 'خفيف'  : 'Minor';
  String get interactionCount => isAr ? 'تفاعل' : 'interaction';
  String get pairCount        => isAr ? 'زوج'   : 'pair';
  String get noInteractionsMsg => isAr ? 'لا توجد تفاعلات دوائية مسجّلة بين هذه الأدوية'
                                        : 'No recorded drug interactions between these drugs';
  String get addMoreDrugs     => isAr ? 'أضف دواءين على الأقل للتحقق من التفاعلات'
                                      : 'Add at least 2 drugs to check for interactions';
  String get addOneDrug       => isAr ? 'أضف دواءً آخر للمقارنة' : 'Add another drug to compare';
  String get drugCheckerStart => isAr ? 'أضف أدوية للتحقق من التفاعلات بينها'
                                      : 'Add drugs to check for interactions';

  // ── Renal Calculator ──────────────────────────────────────────────────────
  String get crclTitle       => isAr ? 'حاسبة CrCl (Cockcroft-Gault)' : 'CrCl Calculator (Cockcroft-Gault)';
  String get patientData     => isAr ? 'بيانات المريض'   : 'Patient Data';
  String get ageYears        => isAr ? 'العمر (سنة)'     : 'Age (years)';
  String get weightKg        => isAr ? 'الوزن (كغ)'      : 'Weight (kg)';
  String get gender          => isAr ? 'الجنس:'          : 'Sex:';
  String get male            => isAr ? 'ذكر'             : 'Male';
  String get female          => isAr ? 'أنثى'            : 'Female';
  String get enterAllValues  => isAr ? 'يرجى إدخال جميع القيم بشكل صحيح' : 'Please enter all values correctly';
  String get dosageGuide     => isAr ? 'دليل تعديل الجرعات' : 'Dose Adjustment Guide';
  // CrCl stage labels
  String get crclNormal      => isAr ? 'طبيعي'            : 'Normal';
  String get crclMild        => isAr ? 'قصور خفيف (G2)'   : 'Mild (G2)';
  String get crclModerate    => isAr ? 'قصور متوسط (G3)'  : 'Moderate (G3)';
  String get crclSevere      => isAr ? 'قصور شديد (G4)'   : 'Severe (G4)';
  String get crclFailure     => isAr ? 'فشل كلوي (G5)'    : 'Kidney Failure (G5)';
  // Table rows
  List<List<String>> get renalRows => isAr ? const [
    ['≥ 90', 'طبيعي', 'لا تعديل'],
    ['60–89', 'G2 خفيف', 'مراقبة فقط'],
    ['30–59', 'G3 متوسط', 'تعديل الجرعة'],
    ['15–29', 'G4 شديد', 'تقليل كبير'],
    ['< 15', 'G5 فشل كلوي', 'يُمنع أو الغسيل'],
  ] : const [
    ['≥ 90', 'Normal', 'No adjustment'],
    ['60–89', 'G2 Mild', 'Monitor only'],
    ['30–59', 'G3 Moderate', 'Dose adjustment'],
    ['15–29', 'G4 Severe', 'Significant reduction'],
    ['< 15', 'G5 Failure', 'Avoid or dialysis'],
  ];
  List<String> get renalTableHeaders => isAr
      ? const ['CrCl', 'المرحلة', 'التوجيه']
      : const ['CrCl', 'Stage', 'Guidance'];
  String crclStage(double crcl) {
    if (crcl >= 90) return crclNormal;
    if (crcl >= 60) return crclMild;
    if (crcl >= 30) return crclModerate;
    if (crcl >= 15) return crclSevere;
    return crclFailure;
  }

  // ── Substitution Screen ───────────────────────────────────────────────────
  String get substitutionTitle => isAr ? 'الباحث عن البدائل الذكي' : 'Smart Substitution Finder';
  String get substitutionSub2  => isAr ? 'ابحث باسم الدواء أو المادة الفعالة' : 'Search by drug name or active ingredient';
  String get offlineMode       => isAr ? 'يعمل بدون إنترنت' : 'Works offline';
  String get subSearchHint     => isAr ? 'مثال: Zofran  أو  Ondansetron' : 'e.g. Zofran or Ondansetron';
  String get directAlternatives => isAr ? 'البدائل المباشرة' : 'Direct Alternatives';
  String get sameActiveIngredient => isAr ? 'نفس المادة الفعالة' : 'Same active ingredient';
  String get similarAlternatives  => isAr ? 'بدائل مشابهة'    : 'Similar Alternatives';
  String get subNoResults    => isAr ? 'لم نعثر على بدائل لـ' : 'No alternatives found for';
  String get sameFamily      => isAr ? 'بدائل من نفس العائلة' : 'Same Drug Family';
  String get activeIngredientLabel => isAr ? 'المادة الفعالة'  : 'Active Ingredient';
  String get drugClassLabel  => isAr ? 'العائلة الدوائية'      : 'Drug Class';
  String get searchAnyDrug   => isAr ? 'ابحث عن أي دواء'      : 'Search any drug';
  String get subWelcomeSub   => isAr ? 'سيعرض لك البدائل المباشرة وبدائل من نفس العائلة الدوائية'
                                      : 'Shows direct and therapeutic-class alternatives';
  String get subWelcome      => isAr ? 'ابحث عن بديل للدواء'  : 'Search for a drug substitute';

  // ── Notebook ──────────────────────────────────────────────────────────────
  String get notebookTitle   => isAr ? 'دفتر الأدوية المفقودة' : 'Missing Drugs Notebook';
  String get addDrugHint     => isAr ? 'أضف اسم دواء مفقود...' : 'Add a missing drug name...';
  String get sendWhatsApp    => isAr ? 'إرسال عبر WhatsApp'    : 'Send via WhatsApp';
  String get noPendingItems  => isAr ? 'لا توجد عناصر غير مكتملة للإرسال' : 'No pending items to send';
  String get emptyNotebook   => isAr ? 'الدفتر فارغ'           : 'Notebook is empty';
  String get emptyNotebookSub => isAr ? 'أضف الأدوية الناقصة في صيدليتك' : 'Add missing drugs in your pharmacy';
  String get emptyNotebookWhatsappSub => isAr
      ? 'أضف أسماء الأدوية المفقودة\nثم أرسلها مباشرة عبر واتساب'
      : 'Add the names of missing drugs\nthen send them directly via WhatsApp';
  String get all_             => isAr ? 'الكل'   : 'All';
  String get missing          => isAr ? 'مفقود'  : 'Missing';
  String get doneLabel        => isAr ? 'تم'     : 'Done';
  String get addLabel         => isAr ? 'إضافة'  : 'Add';
  String get clearDone        => isAr ? 'مسح المكتملة' : 'Clear done';
  String get whatsappError    => isAr ? 'تعذّر فتح واتساب. تأكد من تثبيته.' : 'Could not open WhatsApp. Make sure it is installed.';

  // ── Pricing Calculator ────────────────────────────────────────────────────
  String get pricingTitle    => isAr ? 'حاسبة التسعير الذكية'   : 'Smart Pricing Calculator';
  String get baseCost        => isAr ? 'سعر القطعة في الفاتورة'    : 'Unit Invoice Price';
  String get purchased       => isAr ? 'الكمية المشتراة'            : 'Quantity Purchased';
  String get bonus           => isAr ? 'البونص المجاني'             : 'Free Bonus';
  String get discount        => isAr ? 'نسبة الخصم'                : 'Discount %';
  String get cashDiscount    => isAr ? 'خصم نقدي إضافي'            : 'Extra Cash Discount';
  String get profitMargin    => isAr ? 'نسبة الربح لحساب سعر البيع' : 'Profit % for Selling Price';
  String get netCost         => isAr ? 'تكلفة الوحدة الصافية'       : 'Net Unit Cost';
  String get sellingPrice    => isAr ? 'سعر البيع'                  : 'Selling Price';
  String get totalPieces     => isAr ? 'إجمالي القطع'               : 'Total Pieces';
  String get totalPaid       => isAr ? 'المدفوع الكلي'              : 'Total Paid';
  String get iqd             => isAr ? 'د.ع'                        : 'IQD';
  String get piecesUnit      => isAr ? 'قطعة'                       : 'pcs';
  String get howToUse        => isAr ? 'كيفية الاستخدام'            : 'How to Use';
  String get helpRequired    => isAr ? 'الحقول المعلّمة بـ (*) إلزامية — الباقي اختياري' : 'Fields marked (*) are required — rest are optional';
  String get helpBonus       => isAr ? 'البونص: القطع المجانية من المورد — تُحسب في التكلفة' : 'Bonus: free units from supplier — counted in cost';
  String get helpDiscountNote => isAr ? 'نسبة الخصم والخصم النقدي يُطرحان من الفاتورة' : 'Discount % and cash discount are deducted from invoice';
  String get helpAutoUpdate  => isAr ? 'النتائج تتحدث تلقائياً عند كل إدخال' : 'Results update automatically with each input';
  String piecesAndPaid(int pieces, String paid) => isAr ? '$pieces قطعة • $paid د.ع' : '$pieces pcs • $paid IQD';
  String profitOf(String amount) => isAr ? 'ربح $amount د.ع' : 'Profit $amount IQD';

  // ── Legal / Settings / Support ────────────────────────────────────────────
  String get settingsTitle   => isAr ? 'الإعدادات'               : 'Settings';
  String get supportTitle    => isAr ? 'قسم الدعم'               : 'Support';
  String get suggestionTitle => isAr ? 'إرسال اقتراح'            : 'Send Suggestion';
  String get legalTitle      => isAr ? 'المعلومات القانونية'      : 'Legal Information';
  String get barcodeTitle    => isAr ? 'مسح الباركود'            : 'Barcode Scanner';

  // OTC
  String get otcTitle            => isAr ? 'أدوية OTC'                           : 'OTC Medicines';
  String get otcSubtitle2        => isAr ? 'أدوية بدون وصفة طبية'               : 'Over-the-counter medicines';
  String get chooseCategory      => isAr ? 'اختر القسم'                          : 'Choose a category';
  String get otcChooseSectionHint => isAr ? 'اختر قسماً لعرض الأمراض والأدوية' : 'Choose a section to browse conditions and drugs';
  String get otcSearchHint       => isAr ? 'ابحث عن قسم أو مرض أو دواء...'      : 'Search by category, condition or drug...';
  String get noResults           => isAr ? 'لا توجد نتائج'                       : 'No results';
  String get chooseCondition     => isAr ? 'اختر الحالة الطبية'                  : 'Choose a condition';
  String get dosage_             => isAr ? 'الجرعة'                              : 'Dosage';
  String get pharmacistCounseling => isAr ? 'نصائح الصيدلاني'                   : 'Pharmacist Tips';
  String nSections(int n)        => isAr ? '$n قسم'                              : '$n section${n == 1 ? '' : 's'}';
  String nConditions(int n)      => isAr ? '$n حالة طبية'                        : '$n condition${n == 1 ? '' : 's'}';
  String nDrugsAvail(int n)      => isAr ? '$n أدوية متاحة'                      : '$n drug${n == 1 ? '' : 's'} available';
  String otcDrugsFor(int n, String name) => isAr ? '$n أدوية OTC لـ $name' : '$n OTC drug${n == 1 ? '' : 's'} for $name';

  // Commercial price guide
  String get priceGuideTitle      => isAr ? 'دليل الأسعار التجاري'                : 'Commercial Price Guide';
  String get dataRefreshed        => isAr ? 'تم استيراد أحدث البيانات بنجاح'     : 'Latest data imported successfully';
  String get refreshList          => isAr ? 'تحديث القائمة'                       : 'Refresh list';
  String get priceSearchHint      => isAr ? 'ابحث باسم المنتج أو الباركود...'    : 'Search by product name or barcode...';
  String get technicalDetails     => isAr ? 'التفاصيل الفنية'                     : 'Technical Details';
  String get barcode_             => isAr ? 'الباركود'                            : 'Barcode';
  String get entryId              => isAr ? 'المعرف (ID)'                         : 'Entry ID';
  String get packaging            => isAr ? 'التعبئة'                             : 'Packaging';
  String get barcodeCopied        => isAr ? 'تم نسخ الباركود'                     : 'Barcode copied';
  String get listCurrentlyEmpty   => isAr ? 'القائمة فارغة حالياً'               : 'List is currently empty';
  String get priceListEmptyHint   => isAr ? 'ستظهر هنا أسعار المنتجات بعد إضافتها من لوحة التحكم' : 'Product prices will appear here once added via the dashboard';
  String get serverConnectionFailed => isAr ? 'تعذّر الاتصال بالخادم'            : 'Could not connect to server';
  String get checkInternet        => isAr ? 'تحقق من اتصالك بالإنترنت'          : 'Check your internet connection';

  // Notifications
  String get notifications_       => isAr ? 'الإشعارات'                           : 'Notifications';
  String get tapNotifToRead       => isAr ? 'اضغط على الإشعار لفتحه وتعيينه كمقروء' : 'Tap a notification to open and mark as read';
  String get markAll              => isAr ? 'تعيين الكل'                          : 'Mark all';
  String get tapForDetails        => isAr ? 'اضغط للتفاصيل'                       : 'Tap for details';
  String get noNotificationsHint  => isAr ? 'ستظهر هنا الإشعارات الجديدة عند وصولها' : 'New notifications will appear here';
  String get failedToLoadNotifs   => isAr ? 'تعذّر تحميل الإشعارات'              : 'Failed to load notifications';
  String get today_               => isAr ? 'اليوم'                               : 'Today';
  String get thisWeek             => isAr ? 'هذا الأسبوع'                         : 'This Week';
  String get older_               => isAr ? 'أقدم'                                : 'Older';
  String notifGroupLabel(String key) {
    if (key == 'today') return today_;
    if (key == 'thisWeek') return thisWeek;
    return older_;
  }
  String get justNow              => isAr ? 'الآن' : 'Just now';
  String minutesAgo(int m)        => isAr ? 'منذ $m دقيقة' : '${m}m ago';
  String hoursAgo(int h)          => isAr ? 'منذ $h ساعة' : '${h}h ago';
  String get yesterdayLabel       => isAr ? 'منذ يوم' : 'Yesterday';
  String daysAgo(int d)           => isAr ? 'منذ $d أيام' : '${d}d ago';
  String weeksAgo(int w)          => isAr ? 'منذ $w أسبوع' : '${w}w ago';
  String monthsAgo_(int m)        => isAr ? 'منذ $m شهر' : '${m}mo ago';
  String yearsAgo(int y)          => isAr ? 'منذ $y سنة' : '${y}y ago';
  String monthName(int m) {
    const ar = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    const en = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return isAr ? ar[m] : en[m];
  }

  // Quick filter
  String get quickFilter     => isAr ? 'فلتر سريع'                        : 'Quick Filter';
  String get drugSearchHint  => isAr ? 'ابحث عن اسم الدواء...'            : 'Search drug name...';

  // Barcode scanner
  String get barcodeScanHint  => isAr ? 'وجّه الكاميرا نحو باركود البكج'  : 'Point camera at package barcode';
  String get flashOn_         => isAr ? 'تشغيل الفلاش'                    : 'Flash on';
  String get flashOff_        => isAr ? 'إطفاء الفلاش'                    : 'Flash off';

  // Support screen
  String get helpCenter        => isAr ? 'مركز المساعدة'                   : 'Help Center';
  String get helpCenterSub     => isAr ? 'إجابات على الأسئلة الشائعة وطرق التواصل' : 'FAQs and contact options';
  String get faqSection        => isAr ? 'الأسئلة الشائعة'                 : 'Frequently Asked Questions';
  String get contactUs_        => isAr ? 'تواصل معنا'                      : 'Contact Us';
  String get emailLabel        => isAr ? 'البريد الإلكتروني'               : 'Email';

  // Suggestion screen
  String get yourOpinionMatters   => isAr ? 'رأيك يهمنا'                  : 'Your opinion matters';
  String get suggestionHeaderSub  => isAr ? 'ساعدنا في تحسين التطبيق باقتراحاتك' : 'Help us improve the app with your suggestions';
  String get suggestionType       => isAr ? 'نوع الاقتراح'                 : 'Suggestion type';
  String get suggestionDetails    => isAr ? 'تفاصيل الاقتراح'              : 'Suggestion details';
  String get suggestionHint       => isAr ? 'اكتب اقتراحك أو وصف المشكلة هنا...' : 'Write your suggestion or describe the issue here...';
  String get writeYourSuggestion  => isAr ? 'يرجى كتابة اقتراحك'           : 'Please write your suggestion';
  String get min10Chars           => isAr ? '10 أحرف على الأقل'            : 'At least 10 characters';
  String get attachImageOptional  => isAr ? 'إرفاق صورة (اختياري)'         : 'Attach image (optional)';
  String get changeImage          => isAr ? 'تغيير الصورة'                 : 'Change image';
  String get tapToAddImage        => isAr ? 'اضغط لإضافة صورة'            : 'Tap to add an image';
  String get sendFailed_          => isAr ? 'فشل الإرسال، تحقق من اتصالك وحاول مجدداً' : 'Send failed. Check your connection and try again.';
  String get sending_             => isAr ? 'جارٍ الإرسال...'              : 'Sending...';
  String get suggestionSent       => isAr ? 'تم إرسال اقتراحك!'            : 'Your suggestion was sent!';
  String get suggestionSentMsg    => isAr ? 'شكراً لمساهمتك في تطوير التطبيق.\nسنراجع اقتراحك في أقرب وقت.' : 'Thank you for helping improve the app.\nWe will review your suggestion soon.';
  String get allowAccessSettings  => isAr ? 'يرجى السماح بالوصول من إعدادات الهاتف' : 'Please allow access in phone settings';
  String get allowAccessRequired  => isAr ? 'يجب السماح بالوصول للمتابعة'  : 'Access permission is required to continue';
  String get fromGallery          => isAr ? 'من معرض الصور'                : 'From gallery';
  String get takePicture          => isAr ? 'التقاط صورة'                  : 'Take a picture';
  List<String> get suggestionCategories => isAr
      ? ['اقتراح ميزة جديدة', 'الإبلاغ عن خطأ', 'تحسين واجهة المستخدم', 'إضافة دواء أو معلومة', 'أخرى']
      : ['Suggest a new feature', 'Report a bug', 'UI/UX improvement', 'Add drug or info', 'Other'];

  // Settings screen
  String get appearance           => isAr ? 'المظهر'                       : 'Appearance';
  String get language_            => isAr ? 'اللغة'                        : 'Language';
  String get aboutApp_            => isAr ? 'عن التطبيق'                   : 'About';
  String get medicalDisclaimer    => isAr ? 'إخلاء مسؤولية طبية'           : 'Medical Disclaimer';
  String get importantNotice      => isAr ? 'تنبيه مهم'                    : 'Important Notice';
  String get disclaimerContent    => isAr
      ? 'هذا التطبيق للأغراض التعليمية والمرجعية فقط.\nلا يُغني عن استشارة الطبيب أو الصيدلاني.\nالمعلومات مستمدة من FDA وقد لا تعكس الواقع المحلي بالكامل.'
      : 'This app is for educational and reference purposes only.\nIt does not replace consultation with a physician or pharmacist.\nInformation is sourced from the FDA and may not fully reflect local practices.';
  String get appVersion           => isAr ? 'الإصدار 1.0.0'                : 'Version 1.0.0';
  String get okLabel              => isAr ? 'موافق'                        : 'OK';
  String get arabicLabel          => 'العربية';
  String get disclaimer_          => isAr ? 'إخلاء المسؤولية'              : 'Disclaimer';

  // Interactive Reference screen
  String get interactiveRefTitle  => isAr ? 'المرجع التفاعلي'              : 'Interactive Reference';
  String get noNotesYet           => isAr ? 'لا توجد ملاحظات بعد'          : 'No notes yet';
  String get addNotesHint         => isAr ? 'أضف بروتوكولاتك وملاحظاتك المهنية هنا' : 'Add your professional protocols and notes here';
  String get addNote              => isAr ? 'إضافة ملاحظة'                 : 'Add note';
  String get deleteNote           => isAr ? 'حذف الملاحظة'                 : 'Delete note';
  String get deleteNoteConfirm    => isAr ? 'هل تريد حذف هذه الملاحظة نهائياً؟' : 'Are you sure you want to permanently delete this note?';
  String get editNote             => isAr ? 'تعديل الملاحظة'               : 'Edit note';
  String get newNote              => isAr ? 'ملاحظة جديدة'                 : 'New note';
  String get noteTitle            => isAr ? 'العنوان'                      : 'Title';
  String get noteTitleRequired    => isAr ? 'أدخل عنوان الملاحظة'          : 'Enter a note title';
  String get noteContent          => isAr ? 'المحتوى'                      : 'Content';
  String get noteContentRequired  => isAr ? 'أدخل محتوى الملاحظة'          : 'Enter note content';
  String get saveFailed           => isAr ? 'فشل الحفظ، حاول مجدداً'       : 'Save failed. Please try again.';
  String get saveNote             => isAr ? 'حفظ الملاحظة'                 : 'Save note';

  // Search bar widget
  String get searchDrugHint        => isAr ? 'ابحث عن دواء... (عربي أو إنجليزي)' : 'Search drug... (Arabic or English)';
  String get allowCameraSettings   => isAr ? 'يرجى السماح بالكاميرا من إعدادات الجهاز' : 'Please allow camera access in device settings';
  String get cameraPermission      => isAr ? 'إذن الكاميرا'                : 'Camera Permission';
  String get cameraPermissionReason => isAr ? 'نحتاج إلى إذن استخدام الكاميرا لمسح باركود الدواء بسرعة وبدقة.' : 'We need camera permission to scan drug barcodes quickly and accurately.';
  String get allow_                => isAr ? 'السماح'                      : 'Allow';
  String get scan_                 => isAr ? 'مسح'                         : 'Scan';
  String get recentSearches        => isAr ? 'عمليات البحث الأخيرة'        : 'Recent Searches';
  String get generic_              => isAr ? 'جنيس'                        : 'Generic';
  String get commercial_          => isAr ? 'تجاري'                        : 'Trade';

  // Splash
  String get splashTitle     => isAr ? 'دليل الصيدلة العراقي'             : 'Iraq Pharma Guide';

  // ── Common ────────────────────────────────────────────────────────────────
  String get loading           => isAr ? 'جاري التحميل...' : 'Loading...';
  String get error             => isAr ? 'خطأ'             : 'Error';
  String get retry             => isAr ? 'إعادة المحاولة'  : 'Retry';
  String get close             => isAr ? 'إغلاق'           : 'Close';
  String get save              => isAr ? 'حفظ'             : 'Save';
  String get confirm           => isAr ? 'تأكيد'           : 'Confirm';
  String get yes               => isAr ? 'نعم'             : 'Yes';
  String get no                => isAr ? 'لا'              : 'No';
  String get back              => isAr ? 'رجوع'            : 'Back';
  String get next              => isAr ? 'التالي'          : 'Next';
  String get done              => isAr ? 'تم'              : 'Done';
  String get edit              => isAr ? 'تعديل'           : 'Edit';
  String get delete            => isAr ? 'حذف'             : 'Delete';
  String get search            => isAr ? 'بحث'             : 'Search';
  String get send              => isAr ? 'إرسال'           : 'Send';
  String get required_         => isAr ? 'مطلوب'           : 'Required';

  // ── Rating modal ──────────────────────────────────────────────────────────
  String get rateApp           => isAr ? 'قيّم التطبيق'    : 'Rate the App';
  String get rateAppLater      => isAr ? 'لاحقاً'          : 'Later';
  String get rateAppSubmit     => isAr ? 'إرسال التقييم'  : 'Submit Rating';
  String get rateAppThanks     => isAr ? 'شكراً لك!'       : 'Thank you!';
  String get rateAppHintHigh   => isAr ? '🎉 شكراً! سنحولك للمتجر لإتمام التقييم' : '🎉 Thanks! We\'ll take you to the store to finish rating';
  String get rateAppHintLow    => isAr ? 'نأسف لذلك. سنعمل على التحسين' : 'Sorry to hear that. We\'ll work on improving';
  String get rateAppThanksHigh => isAr ? 'تقييمك يعني لنا الكثير ❤️' : 'Your rating means a lot to us ❤️';
  String get rateAppThanksLow  => isAr ? 'سنعمل على تحسين التطبيق' : 'We\'ll work on improving the app';

  // ── Force update dialog ───────────────────────────────────────────────────
  String get updateRequired          => isAr ? 'تحديث مطلوب' : 'Update Required';
  String get updateAvailableBody     => isAr ? 'يتوفر تحديث جديد!\nيرجى تحديث التطبيق للمتابعة.' : 'A new update is available!\nPlease update the app to continue.';
  String get currentVersionLabel     => isAr ? 'الإصدار الحالي' : 'Current Version';
  String get requiredVersionLabel    => isAr ? 'الإصدار المطلوب' : 'Required Version';
  String get openingLabel            => isAr ? 'جارٍ الفتح...' : 'Opening...';
  String get updateNowLabel          => isAr ? 'تحديث الآن' : 'Update Now';
  String get cannotContinueWithoutUpdate => isAr ? 'لا يمكن الاستمرار بدون التحديث' : 'Cannot continue without updating';

  // ── Soft update dialog ────────────────────────────────────────────────────
  String get newUpdateAvailableTitle => isAr ? '🎉 تحديث جديد متاح!' : '🎉 New update available!';
  String versionLabel(String v)      => isAr ? 'الإصدار $v' : 'Version $v';
  String get updateAppNowLabel       => isAr ? 'حدّث التطبيق الآن' : 'Update App Now';

  // ── Ad carousel ───────────────────────────────────────────────────────────
  String get adSpaceTitle      => isAr ? 'المساحة الإعلانية' : 'Ad Space';
  String get pharmacistCountLabel => isAr ? '5,000 صيدلاني' : '5,000 Pharmacists';
  String get adReachText       => isAr ? 'اعرض منتجاتك أو خدماتك أمام أكثر من' : 'Showcase your products or services to over';
  String get inIraqLabel       => isAr ? 'في العراق' : 'in Iraq';
  String get contactInquiryLabel => isAr ? 'للتواصل والاستفسار:' : 'For contact & inquiries:';
  String get callNowLabel      => isAr ? 'اتصل الآن' : 'Call Now';
  String get imageLoadFailed   => isAr ? 'تعذّر تحميل الصورة' : 'Failed to load image';

  // ── Connectivity ──────────────────────────────────────────────────────────
  String get connectedToInternet   => isAr ? 'تم الاتصال بالإنترنت' : 'Connected to the internet';
  String get noInternetConnection  => isAr ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection';

  // ── Substitution search ───────────────────────────────────────────────────
  String noResultsForQuery(String q) => isAr ? 'لا توجد نتائج لـ "$q"' : 'No results for "$q"';
  String get tryDifferentSearchTerm  => isAr ? 'جرّب البحث باسم تجاري آخر أو بالاسم العلمي' : 'Try a different trade name or the generic name';

  // ── Reset password ────────────────────────────────────────────────────────
  String get setNewPasswordTitle => isAr ? 'تعيين كلمة مرور جديدة' : 'Set a New Password';
  String get setNewPasswordSub   => isAr ? 'أدخل كلمة المرور الجديدة التي تريد استخدامها' : 'Enter the new password you want to use';
  String get passwordMin8Chars   => isAr ? 'يجب أن تكون 8 أحرف على الأقل' : 'Must be at least 8 characters';
  String get confirmPasswordValidate => isAr ? 'أكّد كلمة المرور' : 'Confirm your password';
  String get savePasswordBtn     => isAr ? 'حفظ كلمة المرور' : 'Save Password';
  String get passwordChangedTitle => isAr ? 'تم تغيير كلمة المرور' : 'Password Changed';
  String get canNowSignInMsg     => isAr ? 'يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة' : 'You can now sign in with your new password';

  // ── OTP screen ────────────────────────────────────────────────────────────
  String get pasteCodeLabel    => isAr ? 'اضغط للصق الرمز' : 'Tap to paste code';
  String get changeEmailLabel  => isAr ? 'تغيير البريد الإلكتروني' : 'Change Email';

  // ── Drug detail extras ────────────────────────────────────────────────────
  String get drugFormAdministration => isAr ? 'شكل الدواء وطريقة الإعطاء' : 'Drug Form & Administration';
  String get availableDosesLabel    => isAr ? 'الجرع المتوفرة' : 'Available Doses';
}

extension AppStringsExt on BuildContext {
  AppStrings get s {
    final locale = Localizations.localeOf(this);
    return AppStrings(locale.languageCode == 'ar');
  }
}
