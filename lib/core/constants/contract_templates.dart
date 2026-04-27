import '../../models/contract_model.dart';

/// Holds reusable Tunisian legal contract templates.
///
/// Templates use `{{placeholder}}` syntax that gets replaced with
/// real data when generating a contract for a specific application.
/// Templates are based on standard Tunisian legal contract formats.
class ContractTemplates {
  ContractTemplates._();

  // ─── Party identification placeholders ───
  static const String ownerFullName = '{{ownerFullName}}';
  static const String ownerBirthPlace = '{{ownerBirthPlace}}';
  static const String ownerBirthDate = '{{ownerBirthDate}}';
  static const String ownerIdNumber = '{{ownerIdNumber}}';
  static const String ownerIdIssueDate = '{{ownerIdIssueDate}}';
  static const String ownerAddress = '{{ownerAddress}}';
  static const String tenantFullName = '{{tenantFullName}}';
  static const String tenantBirthPlace = '{{tenantBirthPlace}}';
  static const String tenantBirthDate = '{{tenantBirthDate}}';
  static const String tenantIdNumber = '{{tenantIdNumber}}';
  static const String tenantIdIssueDate = '{{tenantIdIssueDate}}';
  static const String tenantAddress = '{{tenantAddress}}';

  // ─── Property placeholders ───
  static const String propertyAddress = '{{propertyAddress}}';
  static const String propertyType = '{{propertyType}}';

  // ─── Financial placeholders ───
  static const String dealAmount = '{{dealAmount}}';
  static const String dealAmountWords = '{{dealAmountWords}}';
  static const String depositAmount = '{{depositAmount}}';
  static const String syndicAmount = '{{syndicAmount}}';
  static const String paymentDay = '{{paymentDay}}';
  static const String annualIncreaseRate = '{{annualIncreaseRate}}';

  // ─── Date/duration placeholders ───
  static const String startDate = '{{startDate}}';
  static const String endDate = '{{endDate}}';
  static const String contractDate = '{{contractDate}}';
  static const String contractDuration = '{{contractDuration}}';

  // ─── Legal placeholders ───
  static const String lawyerFullName = '{{lawyerFullName}}';
  static const String jurisdictionCourt = '{{jurisdictionCourt}}';

  // ─── Annex-specific placeholders ───
  static const String originalContractDate = '{{originalContractDate}}';
  static const String registrationDate = '{{registrationDate}}';
  static const String taxOfficeName = '{{taxOfficeName}}';
  static const String receiptNumber = '{{receiptNumber}}';
  static const String registrationNumber = '{{registrationNumber}}';

  /// Get the template body for a given contract type
  static String getTemplate(ContractType type) {
    switch (type) {
      case ContractType.rental:
        return _rentalTemplate;
      case ContractType.sale:
        return _saleTemplate;
      case ContractType.rentalAnnex:
        return _rentalAnnexTemplate;
    }
  }

  /// Get the default editable fields for a contract type
  static Map<String, String> getDefaultFields(ContractType type) {
    switch (type) {
      case ContractType.rental:
        return {
          'paymentDay': 'الخامس',
          'syndicAmount': '',
          'annualIncreaseRate': '5',
          'jurisdictionCourt': 'محكمة تونس 1',
        };
      case ContractType.sale:
        return {
          'jurisdictionCourt': 'محكمة تونس 1',
        };
      case ContractType.rentalAnnex:
        return {
          'originalContractDate': '',
          'registrationDate': '',
          'taxOfficeName': '',
          'receiptNumber': '',
          'registrationNumber': '',
        };
    }
  }

  /// Fill a template with actual data
  static String fillTemplate({
    required String template,
    required Map<String, String> values,
  }) {
    var result = template;
    for (final entry in values.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════
  // Tunisian Rental Contract Template (عقد كراء)
  // Verbatim from standard Tunisian legal document
  // ═══════════════════════════════════════════════════════════════

  static const String _rentalTemplate = '''
عقد كراء محل معد للسكنى

بين الممضين أسفله :

1 )السيد  $ownerFullName, المولود ب$ownerBirthPlace بتاريخ $ownerBirthDate, تونسي الجنسية, القاطن $ownerAddress, صاحب بطاقة التعريف الوطنية عدد $ownerIdNumber  المسلمة بتونس بتاريخ $ownerIdIssueDate
بصفته مالكا

2 ) السيد  $tenantFullName, المولود ب$tenantBirthPlace بتاريخ $tenantBirthDate, تونسي الجنسية, القاطن $tenantAddress, صاحب بطاقة التعريف الوطنية عدد $tenantIdNumber  المسلمة بتونس بتاريخ $tenantIdIssueDate
بصفتها متسوغة

تم الاتفاق والتراضي على ما يلي:

الفصل الأول: موضوع العقد
سوغ السيد  $ownerFullName للسيد $tenantFullName, الشقة الكائنة $propertyAddress، المعدة للسكنى بجميع توابعها.

الفصل الثاني: مدة التسويغ
حددت مدة الكراء بسنة قابلة للتجديد تبتدأ من $startDate وتنتهي في $endDate
تتجدد العلاقة الكرائية بين الطرفين في صورة عدم توجيه رسالة مضمونة الوصول من أحدهما في إنهاء العلاقة الكرائية ثلاثة أشهر قبل الاجل المحدد بالعقد
ويعتبر المكرى المحل المختار للمكتري في خصوص تبليغ الرسالة المضمونة الوصول.
وفي صورة تجديد العلاقة الكرائية فإنه يقع الترفيع في معينات الكراء بداية من السنة الثانية بـ$annualIncreaseRate% تحتسب على معينات كراء السنة التي تسبقها.

الفصل الثالث: معينات الكراء
عين الطرفان معين الكراء الشهري بما قدره $dealAmountWords دينارا صافي من كل الأداء ($dealAmount دينارا) تدفع كل شهر مسبقا قبل اليوم $paymentDay دون اعتبار الخصم من المورد ويشمل الكراء المذكور اعلاه معاليم السنديك المقدرة بـ $syndicAmount تدفع شهريا.

الفصل الرابع:
جميع استهلاكات ومصاريف الماء والكهرباء والغاز اللاحقة لعملية التسويغ، محمولة على عاتق المتسوغ ويجب دفعها في الآجال المحددة حال الاستظهار بها من طرف الشركات المختصة.

الفصل الخامس:
يصرح المالك وأن المحل في حالة حسنة ويتعهد في صورة وجود إصلاحات تتعلق بأسس البناية بالقيام بها
يقوم المتسوغ بجميع الأشغال و الإصلاحات اللازمة التي تقتضيها طبيعة المكرى والمتعلقة بالاستغلال العادي له و على المكتري إصلاح بلاط الأرضية و ألواح الزجاج و إصلاح الأبواب و الشبابيك والأقفال والمفاتيح و ما شابه ذلك
ويتحمل المكتري المصاريف المتعلقة بالاستعمال العادي و الإصلاح لسخان و معدات المطبخ و بيت الاستحمام من  حنفيات و غيرها...
كما يلتزم المتسوغ بالمحافظة على المحل في حالة حسنة وتسليمه عند انتهاء العلاقة التسويغية في نفس الحالة.

الفصل السادس:
لا يجوز للمتسوغ إجراء تغييرات بالمحل دون إذن كتابي من المالك نفسه و لا يجوز له تغيير صبغته.
إن جميع ما يقوم به المتسوغ من تحسينات أو إصلاحات بالمحل طيلة كامل مدة تسويغه تبقى للمالك دون أي مقابل.

الفصل السابع:
ينفسخ هذا العقد في صورة مخالفة أي شرط من شروطه أو في صورة عدم خلاص المكتري لمعينات الكراء بعد أسبوع من التنبيه عليها بواسطة رسالة مضمونة الوصول.

الفصل الثامن:
لا يجوز للمتسوغ أن تتصرف في المحل تصرفا غير لائقا بالأخلاق أو فيه مس بالنظام العام كما لا يحق له أن يأوي ذوي الشبهات.
لا يمكن للمتسوغ لأي سبب كان أن تسوغ أو يعير للغير المكرى و لو مؤقتا و على وجه الاحسان.

الفصل التاسع:
لا يكون المالك مسؤولا عما يلحق للمتسوغ من شغب أو ضرر من الغير.

الفصل العاشر:
تنتهي العلاقة الكرائية بين الطرفين بمجرد تنبيه بمقتضى رسالة مضمونة الوصول مع إعلام بالبلوغ موجهة 3 أشهر قبل انتهاء مدة التسويغ.

الفصل الحادي عشر:
في حالة عرض المحل للبيع تتم زيارة الشقة من طرف المالك والمشتري بعد الحصول على موافقة المكتري وعلى موعد مسبق.

الفصل الثاني عشر:
تحمل مصاريف تحرير وتسجيل العقد على المتسوغ.

الفصل الثالث عشر:
تختص $jurisdictionCourt بجميع النزاعات التي قد تنشأ عن تنفيذ هذا العقد.

الفصل الرابع عشر:
لتنفيذ هذا العقد عين كل من الأطراف محل مخابرته بعنوانه المذكور أعلاه.

تونس في $contractDate

إمضاء المالك                                                  إمضاء المتسوغ
''';

  // ═══════════════════════════════════════════════════════════════
  // Tunisian Sale Contract Template (عقد بيع عقار)
  // ═══════════════════════════════════════════════════════════════

  static const String _saleTemplate = '''
عقد بيع عقار

بين الممضين أسفله :

1 )السيد  $ownerFullName, المولود ب$ownerBirthPlace بتاريخ $ownerBirthDate, تونسي الجنسية, القاطن $ownerAddress, صاحب بطاقة التعريف الوطنية عدد $ownerIdNumber  المسلمة بتونس بتاريخ $ownerIdIssueDate
بصفته بائعا

2 ) السيد  $tenantFullName, المولود ب$tenantBirthPlace بتاريخ $tenantBirthDate, تونسي الجنسية, القاطن $tenantAddress, صاحب بطاقة التعريف الوطنية عدد $tenantIdNumber  المسلمة بتونس بتاريخ $tenantIdIssueDate
بصفته مشتريا

تم الاتفاق والتراضي على ما يلي:

الفصل الأول: موضوع البيع
باع السيد $ownerFullName للسيد $tenantFullName العقار الكائن $propertyAddress بجميع توابعه ومكوناته.

الفصل الثاني: ثمن البيع
حدد ثمن البيع بمبلغ $dealAmountWords أي ($dealAmount دينارا).

الفصل الثالث: طريقة الدفع
يدفع الثمن كاملا عند التوقيع على هذا العقد، ويصبح نافذ المفعول فور إتمام التسجيل لدى إدارة الملكية العقارية.

الفصل الرابع: تصريحات البائع
يصرح البائع بما يلي:
- أنه المالك الشرعي والوحيد للعقار.
- أن العقار خال من أي رهن أو حجز أو نزاع.
- أنه لم يبرم أي عقد آخر بشأنه.

الفصل الخامس: التزامات البائع
- تسليم العقار في حالته الراهنة.
- تمكين المشتري من الانتفاع الفعلي والقانوني.
- تقديم جميع الوثائق اللازمة لنقل الملكية.

الفصل السادس: التزامات المشتري
- دفع كامل ثمن البيع.
- تحمل مصاريف التسجيل والشهر العقاري.
- تحمل كافة الأعباء والضرائب ابتداء من تاريخ التوقيع.

الفصل السابع: نقل الملكية
تنقل ملكية العقار فور توقيع هذا العقد وإتمام إجراءات التسجيل لدى إدارة الملكية العقارية بالجمهورية التونسية.

الفصل الثامن:
تختص $jurisdictionCourt بجميع النزاعات التي قد تنشأ عن تنفيذ هذا العقد.

الفصل التاسع:
لتنفيذ هذا العقد عين كل من الأطراف محل مخابرته بعنوانه المذكور أعلاه.

تونس في $contractDate

إمضاء البائع                                                  إمضاء المشتري
''';

  // ═══════════════════════════════════════════════════════════════
  // Tunisian Rental Annex Template (ملحق عقد كراء)
  // Verbatim from standard Tunisian legal document
  // ═══════════════════════════════════════════════════════════════

  static const String _rentalAnnexTemplate = '''
ملحــق عقـد كـراء

بين الممضين أسفله :

1 )السيد  $ownerFullName, المولود ب$ownerBirthPlace بتاريخ $ownerBirthDate, تونسي الجنسية, القاطن $ownerAddress, صاحب بطاقة التعريف الوطنية عدد $ownerIdNumber  المسلمة بتونس بتاريخ $ownerIdIssueDate
بصفته مالكا

2 ) السيد  $tenantFullName, المولود ب$tenantBirthPlace بتاريخ $tenantBirthDate, تونسي الجنسية, القاطن $tenantAddress, صاحب بطاقة التعريف الوطنية عدد $tenantIdNumber  المسلمة بتونس بتاريخ $tenantIdIssueDate
بصفتها متسوغة

فصل تمهيــــدي :
بمقتضى عقد الكراء الممضى بين السيد  $ownerFullName و السيد  $tenantFullName,  في $originalContractDate  مسجل بتاريخ $registrationDate بالقباضة المالية $taxOfficeName عدد الوصل $receiptNumber عدد التسجيل  $registrationNumber تسوغ السيد  $tenantFullName, العقار الكائن $propertyAddress

و تم الاتفاق بالعقد المذكور على أنه يمكن للمكتري ممارسة جميع الانشطة التجارية شرط الموافقة السابقة من مالك الجدران

بعد هذا البسط تم الاتفاق و التراضي على ما يلي :

الفصل الأول:
اتفق الطرفان على أن يمكن مالك العقار المكترية من ممارسة جميع أنواع التجارة بالمحل المذكور عدا النشاط المتعلق بالمقاهي.

الفصل الثاني:
تبقى جميع بنود عقد التسويغ الأصلي سارية المفعول في ما لا يتعارض مع ما ورد في هذا الملحق.

الفصل الثالث:
تحمل مصاريف هذا الكتب من تحرير و تسجيل و غيرها على المتسوغة.

الفصل الرابع:
لتنفيذ بنود هذا العقد عين كل من الطرفين محل مخابرته بعنوانه المذكور أعلاه.

إمضاء المالك                                                      امضاء المتسوغة
''';
}
