// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dental Clinic';

  @override
  String get home => 'Home';

  @override
  String get patients => 'Patients';

  @override
  String get appointments => 'Appointments';

  @override
  String get invoices => 'Invoices';

  @override
  String get more => 'More';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get amountMustBePositive => 'Amount must be greater than zero.';

  @override
  String get editPayment => 'Edit Payment';

  @override
  String get errorUpdatingPayment => 'Error updating payment';

  @override
  String get paymentDate => 'Payment Date';

  @override
  String get delete => 'Delete';

  @override
  String get appointmentConflictMessage =>
      'There is an appointment at the same time with patient:';

  @override
  String get patientsCount => 'عدد المرضى';

  @override
  String get todaysAppointments => 'مواعيد اليوم';

  @override
  String get pendingInvoices => 'الفواتير المعلقة';

  @override
  String get addPatient => 'إضافة مريض';

  @override
  String get addAppointment => 'إضافة موعد';

  @override
  String get addInvoice => 'إضافة فاتورة';

  @override
  String get name => 'الاسم';

  @override
  String get fileNumber => 'رقم الملف';

  @override
  String get phone => 'الهاتف';

  @override
  String get age => 'العمر';

  @override
  String get gender => 'الجنس';

  @override
  String get actions => 'التحكم';

  @override
  String get noLinkedTreatmentsFound => 'لا علاجات لهذا المريض';

  @override
  String get pleaseSelectPatientFirst => 'اختر مريض رجاء';

  @override
  String get viewInvoice => 'رؤية الفاتورة';

  @override
  String get time => 'الوقت';

  @override
  String get viewPatient => 'رؤية المريض';

  @override
  String get notEnoughDataForTrend => 'لا يوجد معلومات كافية';

  @override
  String get exportingData => 'تصدير البيانات';

  @override
  String get storagePermissionRequired => 'تصريح التخزين مطلوب';

  @override
  String get backupFileTitle => 'اسم الملف';

  @override
  String get importingData => 'استيراد البيانات';

  @override
  String get displaySettings => 'الاعدادات';

  @override
  String get development => 'التطوير';

  @override
  String get whatsappNotInstalled => 'واتس اب غير مثبت';

  @override
  String get patientInformation => 'معلومات المريض';

  @override
  String get patientName => 'اسم المريض';

  @override
  String get dataManagement => 'ادارة البيانات';

  @override
  String get invoiceNumber => 'رقم الفاتورة';

  @override
  String get fullyPaid => 'مدفوعة بالكامل';

  @override
  String get clinicInformation => 'معلومات العيادة';

  @override
  String get contactInformation => 'معلومات التواصل ';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get currencySymbol => 'ل.س';

  @override
  String get maritalStatus => 'الحالة الاجتماعية';

  @override
  String get address => 'العنوان';

  @override
  String get firstVisitDate => 'تاريخ أول زيارة';

  @override
  String get xrayGallery => 'معرض الأشعة السينية';

  @override
  String get noTreatmentsFound => 'لم يتم العثور على علاجات.';

  @override
  String get noInvoicesFound => 'لم يتم العثور على فواتير.';

  @override
  String get noAppointmentsFound => 'لم يتم العثور على مواعيد.';

  @override
  String get noDiagnosis => 'لا يوجد تشخيص';

  @override
  String get date => 'التاريخ';

  @override
  String get status => 'الحالة';

  @override
  String get invoice => 'الفاتورة';

  @override
  String get total => 'الإجمالي';

  @override
  String get appointment => 'الموعد';

  @override
  String get treatments => 'العلاجات';

  @override
  String get patient => 'المريض';

  @override
  String get invoiceDate => 'تاريخ الفاتورة';

  @override
  String get totalAmount => 'المبلغ الإجمالي';

  @override
  String get linkedTreatments => 'العلاجات المرتبطة';

  @override
  String get noLinkedTreatments => 'لا توجد علاجات مرتبطة.';

  @override
  String get payments => 'المدفوعات';

  @override
  String get addPayment => 'إضافة دفعة';

  @override
  String get noPaymentsFound => 'لم يتم العثور على مدفوعات.';

  @override
  String get amount => 'المبلغ';

  @override
  String get method => 'طريقة الدفع';

  @override
  String get editAppointmentTitle => 'تعديل الموعد';

  @override
  String get patientFormField => 'المريض';

  @override
  String get pleaseSelectPatient => 'الرجاء اختيار مريض';

  @override
  String get dateFormField => 'التاريخ';

  @override
  String get timeFormField => 'الوقت';

  @override
  String get notesFormField => 'ملاحظات';

  @override
  String get doctorNotesFormField => 'ملاحظات الطبيب';

  @override
  String get statusFormField => 'الحالة';

  @override
  String get updateAppointmentButton => 'تحديث الموعد';

  @override
  String get noAppointmentsForDate => 'لا توجد مواعيد لهذا التاريخ.';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get addExpenseTitle => 'إضافة مصروف';

  @override
  String get editExpenseTitle => 'تعديل المصروف';

  @override
  String get descriptionFormField => 'الوصف';

  @override
  String get pleaseEnterAmount => 'الرجاء إدخال المبلغ';

  @override
  String get pleaseEnterValidNumber => 'الرجاء إدخال رقم صحيح';

  @override
  String get categoryFormField => 'الفئة';

  @override
  String get addExpenseButton => 'إضافة مصروف';

  @override
  String get updateExpenseButton => 'تحديث المصروف';

  @override
  String get expenses => 'المصروفات';

  @override
  String get filterByCategory => 'تصفية حسب الفئة';

  @override
  String get allCategories => 'جميع الفئات';

  @override
  String get noExpensesForCategory => 'لا توجد مصاريف لهذه الفئة.';

  @override
  String get noDescription => 'لا يوجد وصف';

  @override
  String get patientNotFound => 'لم يتم العثور على المريض';

  @override
  String get error => 'خطأ';

  @override
  String get editInvoiceTitle => 'تعديل الفاتورة';

  @override
  String get invoiceDateFormField => 'تاريخ الفاتورة';

  @override
  String get totalAmountFormField => 'المبلغ الإجمالي';

  @override
  String get pleaseEnterTotalAmount => 'الرجاء إدخال المبلغ الإجمالي';

  @override
  String get noTreatmentsForPatient => 'لا توجد علاجات متاحة لهذا المريض.';

  @override
  String get updateInvoiceButton => 'تحديث الفاتورة';

  @override
  String get invoiceId => 'فاتورة #';

  @override
  String get patientId => 'رقم المريض';

  @override
  String get reports => 'التقارير';

  @override
  String get settings => 'الإعدادات';

  @override
  String get editPatientTitle => 'تعديل بيانات المريض';

  @override
  String get pleaseEnterPatientName => 'الرجاء إدخال اسم المريض';

  @override
  String get selectFirstVisitDate => 'اختر تاريخ الزيارة الأولى';

  @override
  String get xrayImagePath => 'مسار صورة الأشعة';

  @override
  String get updatePatientButton => 'تحديث بيانات المريض';

  @override
  String get searchPatientsHint => 'ابحث عن المرضى...';

  @override
  String get noPatientsFound => 'لم يتم العثور على مرضى.';

  @override
  String get fileNo => 'رقم الملف:';

  @override
  String get phoneLabel => 'الهاتف:';

  @override
  String get na => 'غير متاح';

  @override
  String get editPaymentTitle => 'تعديل الدفعة';

  @override
  String get updatePaymentButton => 'تحديث الدفعة';

  @override
  String get financialOverview => 'نظرة عامة مالية';

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get totalExpenses => 'إجمالي المصروفات';

  @override
  String get outstandingInvoices => 'الفواتير المستحقة';

  @override
  String get expenseBreakdown => 'تفاصيل المصروفات';

  @override
  String get revenueTrend => 'اتجاه الإيرادات';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get theme => 'السمة';

  @override
  String get importSampleData => 'استيراد بيانات عينة (JSON)';

  @override
  String get importSampleDataSubtitle =>
      'تحميل بيانات عينة من assets/data/sample_data.json';

  @override
  String get sampleDataImportInitiated => 'بدء استيراد بيانات العينة.';

  @override
  String get addTreatment => 'إضافة علاج';

  @override
  String get editTreatment => 'تعديل العلاج';

  @override
  String get diagnosis => 'التشخيص';

  @override
  String get treatmentDetails => 'تفاصيل العلاج';

  @override
  String get toothNumber => 'رقم السن';

  @override
  String get agreedAmount => 'المبلغ المتفق عليه';

  @override
  String get updateTreatment => 'تحديث العلاج';

  @override
  String get expenseCategoryRent => 'إيجار';

  @override
  String get expenseCategorySalaries => 'رواتب';

  @override
  String get expenseCategoryMedicalSupplies => 'مواد طبية';

  @override
  String get expenseCategoryOther => 'أخرى';

  @override
  String get pleaseSelectCategory => 'الرجاء اختيار فئة';

  @override
  String get paidAmount => 'المبلغ المدفوع';

  @override
  String get remainingAmount => 'المبلغ المتبقي';

  @override
  String get noImageSelected => 'لم يتم اختيار أي صورة.';

  @override
  String get gallery => 'المعرض';

  @override
  String get camera => 'الكاميرا';

  @override
  String treatmentAlreadyInvoiced(int invoiceId) {
    return 'موجود بالفعل في الفاتورة رقم $invoiceId';
  }

  @override
  String get exportData => 'تصدير البيانات';

  @override
  String get exportDataSubtitle => 'حفظ جميع بيانات التطبيق في ملف مضغوط';

  @override
  String get importData => 'استيراد البيانات';

  @override
  String get importDataSubtitle =>
      'استعادة البيانات من ملف نسخ احتياطي. سيؤدي هذا إلى الكتابة فوق جميع البيانات الحالية.';

  @override
  String get backupSuccessful => 'تم إنشاء النسخة الاحتياطية بنجاح';

  @override
  String get backupFailed => 'فشل إنشاء النسخة الاحتياطية';

  @override
  String get restoreSuccessful => 'تم استعادة البيانات بنجاح';

  @override
  String get restoreFailed => 'فشل استعادة البيانات';

  @override
  String get restoreWarningTitle => 'هل أنت متأكد؟';

  @override
  String get restoreWarningContent =>
      'سيؤدي استعادة البيانات إلى الكتابة فوق جميع البيانات الحالية في التطبيق. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get restore => 'استعادة';

  @override
  String get selectExportDirectory => 'اختر مجلد التصدير';

  @override
  String get exportSuccessful => 'تم التصدير بنجاح، تم حفظ الملف في:';

  @override
  String get amountCannotBeZero => 'يجب أن يكون المبلغ أكبر من الصفر.';

  @override
  String get amountExceedsRemaining => 'المبلغ يتجاوز الرصيد المتبقي وهو';

  @override
  String get search => 'بحث';

  @override
  String get searchInvoicesHint => 'البحث باسم المريض أو رقم الفاتورة';

  @override
  String get patientNameExists => 'يوجد مريض بهذا الاسم بالفعل.';

  @override
  String get netIncome => 'صافي الدخل';

  @override
  String get totalInvoices => 'إجمالي الفواتير';

  @override
  String get paidInvoices => 'الفواتير المدفوعة';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get notAvailable => 'غير متاح';

  @override
  String get thankYouMessage => 'شكرا لك';

  @override
  String get treatment => 'العلاج';

  @override
  String get invoicePdfMessage => 'الرجاء العثور على فاتورتك مرفقة.';

  @override
  String get patientPhoneNumberMissing =>
      'رقم هاتف المريض مفقود. لا يمكن فتح الواتساب مباشرة.';

  @override
  String get laboratory => 'المخبر';

  @override
  String get save => 'حفظ';

  @override
  String get items => 'عناصر';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get resetApp => 'إعادة تعيين التطبيق';

  @override
  String get resetAppFailed => 'فشل إعادة تعيين التطبيق';

  @override
  String get resetAppSubtitle =>
      'حذف جميع البيانات وإعادة تعيين التطبيق إلى حالته الأولية.';

  @override
  String get resetAppSuccess => 'تمت إعادة تعيين التطبيق بنجاح';

  @override
  String get resetAppWarningContent =>
      'سيؤدي هذا إلى حذف جميع البيانات بشكل دائم. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get resetAppWarningTitle => 'إعادة تعيين التطبيق؟';

  @override
  String get resettingApp => 'جارٍ إعادة تعيين التطبيق...';

  @override
  String get deletePatient => 'Delete Patient';

  @override
  String get deletePatientConfirmation =>
      'Are you sure you want to delete this patient and all their associated data?';

  @override
  String get errorLoadingImage => 'Error loading image';

  @override
  String get annotatedImage => 'Annotated Image';

  @override
  String get patientExpenses => 'Patient Expenses';

  @override
  String get passwordDialogTitle => 'Please Enter Password';

  @override
  String get passwordHintText => 'Password';

  @override
  String get submit => 'Submit';

  @override
  String get wrongPassword => 'Wrong password, please try again';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get xRayAnalysisError => 'X-Ray Analysis Error';

  @override
  String get xRayAnalysisResults => 'X-Ray Analysis Results';

  @override
  String get analysisId => 'Analysis ID';

  @override
  String get analysisDate => 'Analysis Date';

  @override
  String get imageQuality => 'Image Quality';

  @override
  String get findings => 'Findings';

  @override
  String get noSpecificFindingsDetected => 'No specific findings detected.';

  @override
  String get severity => 'Severity';

  @override
  String get recommendation => 'Recommendation';

  @override
  String get medicalAdviceSummary => 'Medical Advice Summary';

  @override
  String get noSummaryAvailable => 'No summary available.';
}
