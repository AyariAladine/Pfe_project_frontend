import 'package:flutter_test/flutter_test.dart';
import 'package:pfe_project/core/constants/contract_templates.dart';
import 'package:pfe_project/models/contract_model.dart';

void main() {
  group('ContractTemplates', () {
    group('getTemplate', () {
      test('rental template is verbatim Tunisian format', () {
        final template = ContractTemplates.getTemplate(ContractType.rental);
        expect(template, isNotEmpty);
        // Exact title from real document
        expect(template, contains('عقد كراء محل معد للسكنى'));
        expect(template, contains('بين الممضين أسفله'));
        // Party identification with birth details
        expect(template, contains('{{ownerFullName}}'));
        expect(template, contains('{{ownerBirthPlace}}'));
        expect(template, contains('{{ownerBirthDate}}'));
        expect(template, contains('{{ownerIdNumber}}'));
        expect(template, contains('{{ownerIdIssueDate}}'));
        expect(template, contains('{{tenantFullName}}'));
        expect(template, contains('{{tenantBirthPlace}}'));
        expect(template, contains('المسلمة بتونس بتاريخ'));
        // Financial fields
        expect(template, contains('{{dealAmount}}'));
        expect(template, contains('{{syndicAmount}}'));
        expect(template, contains('{{annualIncreaseRate}}'));
        expect(template, contains('{{paymentDay}}'));
        expect(template, contains('{{jurisdictionCourt}}'));
        expect(template, contains('{{propertyAddress}}'));
        expect(template, contains('{{contractDate}}'));
      });

      test('rental template has all 14 chapters', () {
        final template = ContractTemplates.getTemplate(ContractType.rental);
        expect(template, contains('الفصل الأول'));
        expect(template, contains('الفصل الثاني'));
        expect(template, contains('الفصل الثالث'));
        expect(template, contains('الفصل الرابع'));
        expect(template, contains('الفصل الخامس'));
        expect(template, contains('الفصل السادس'));
        expect(template, contains('الفصل السابع'));
        expect(template, contains('الفصل الثامن'));
        expect(template, contains('الفصل التاسع'));
        expect(template, contains('الفصل العاشر'));
        expect(template, contains('الفصل الحادي عشر'));
        expect(template, contains('الفصل الثاني عشر'));
        expect(template, contains('الفصل الثالث عشر'));
        expect(template, contains('الفصل الرابع عشر'));
      });

      test('rental template contains exact legal clauses', () {
        final template = ContractTemplates.getTemplate(ContractType.rental);
        // Exact wording from real document
        expect(template, contains('بصفته مالكا'));
        expect(template, contains('بصفتها متسوغة'));
        expect(template, contains('المعدة للسكنى بجميع توابعها'));
        expect(template, contains('بسنة قابلة للتجديد'));
        expect(template, contains('رسالة مضمونة الوصول'));
        expect(template, contains('معاليم السنديك'));
        expect(template, contains('إمضاء المالك'));
        expect(template, contains('إمضاء المتسوغ'));
      });

      test('sale template has party details', () {
        final template = ContractTemplates.getTemplate(ContractType.sale);
        expect(template, isNotEmpty);
        expect(template, contains('عقد بيع عقار'));
        expect(template, contains('بين الممضين أسفله'));
        expect(template, contains('بصفته بائعا'));
        expect(template, contains('بصفته مشتريا'));
        expect(template, contains('{{ownerBirthPlace}}'));
        expect(template, contains('{{jurisdictionCourt}}'));
        expect(template, contains('إمضاء البائع'));
        expect(template, contains('إمضاء المشتري'));
      });

      test('rental annex is verbatim with original contract reference', () {
        final template =
            ContractTemplates.getTemplate(ContractType.rentalAnnex);
        expect(template, isNotEmpty);
        // Exact title from real document
        expect(template, contains('ملحــق عقـد كـراء'));
        expect(template, contains('فصل تمهيــــدي'));
        // Original contract reference fields
        expect(template, contains('{{originalContractDate}}'));
        expect(template, contains('{{registrationDate}}'));
        expect(template, contains('{{taxOfficeName}}'));
        expect(template, contains('{{receiptNumber}}'));
        expect(template, contains('{{registrationNumber}}'));
        // Exact legal clauses from real document
        expect(template, contains('ممارسة جميع الانشطة التجارية'));
        expect(template, contains('بنود عقد التسويغ الأصلي سارية المفعول'));
        expect(template, contains('امضاء المتسوغة'));
      });
    });

    group('getDefaultFields', () {
      test('rental has payment, syndic, increase, jurisdiction', () {
        final fields =
            ContractTemplates.getDefaultFields(ContractType.rental);
        expect(fields.containsKey('paymentDay'), isTrue);
        expect(fields['paymentDay'], 'الخامس');
        expect(fields.containsKey('syndicAmount'), isTrue);
        expect(fields.containsKey('annualIncreaseRate'), isTrue);
        expect(fields['annualIncreaseRate'], '5');
        expect(fields.containsKey('jurisdictionCourt'), isTrue);
        expect(fields['jurisdictionCourt'], 'محكمة تونس 1');
      });

      test('sale has jurisdiction default', () {
        final fields = ContractTemplates.getDefaultFields(ContractType.sale);
        expect(fields.containsKey('jurisdictionCourt'), isTrue);
      });

      test('rentalAnnex has original contract reference fields', () {
        final fields =
            ContractTemplates.getDefaultFields(ContractType.rentalAnnex);
        expect(fields.containsKey('originalContractDate'), isTrue);
        expect(fields.containsKey('registrationDate'), isTrue);
        expect(fields.containsKey('taxOfficeName'), isTrue);
        expect(fields.containsKey('receiptNumber'), isTrue);
        expect(fields.containsKey('registrationNumber'), isTrue);
        // Should NOT have payment/duration (not in annex template)
        expect(fields.containsKey('paymentDay'), isFalse);
        expect(fields.containsKey('contractDuration'), isFalse);
      });
    });

    group('fillTemplate', () {
      test('replaces all placeholders', () {
        const template = 'Name: {{ownerFullName}}, Amount: {{dealAmount}} TND';
        final result = ContractTemplates.fillTemplate(
          template: template,
          values: {
            '{{ownerFullName}}': 'Ali Ben Ahmed',
            '{{dealAmount}}': '1500.00',
          },
        );

        expect(result, 'Name: Ali Ben Ahmed, Amount: 1500.00 TND');
      });

      test('leaves unreplaced placeholders as-is', () {
        const template = '{{ownerFullName}} and {{tenantFullName}}';
        final result = ContractTemplates.fillTemplate(
          template: template,
          values: {'{{ownerFullName}}': 'Ali'},
        );

        expect(result, 'Ali and {{tenantFullName}}');
      });

      test('handles empty values map', () {
        const template = 'Some {{placeholder}} text';
        final result = ContractTemplates.fillTemplate(
            template: template, values: {});
        expect(result, template);
      });
    });

    test('all templates contain party identification placeholders', () {
      for (final type in ContractType.values) {
        final template = ContractTemplates.getTemplate(type);
        expect(template, contains('{{ownerFullName}}'),
            reason: '$type missing ownerFullName');
        expect(template, contains('{{ownerBirthPlace}}'),
            reason: '$type missing ownerBirthPlace');
        expect(template, contains('{{ownerIdNumber}}'),
            reason: '$type missing ownerIdNumber');
        expect(template, contains('{{tenantFullName}}'),
            reason: '$type missing tenantFullName');
        expect(template, contains('{{tenantBirthPlace}}'),
            reason: '$type missing tenantBirthPlace');
        expect(template, contains('{{tenantIdNumber}}'),
            reason: '$type missing tenantIdNumber');
        expect(template, contains('{{propertyAddress}}'),
            reason: '$type missing propertyAddress');
      }
    });

    test('rental and sale templates contain date and amount placeholders', () {
      for (final type in [ContractType.rental, ContractType.sale]) {
        final template = ContractTemplates.getTemplate(type);
        expect(template, contains('{{contractDate}}'),
            reason: '$type missing contractDate');
        expect(template, contains('{{dealAmount}}'),
            reason: '$type missing dealAmount');
      }
    });
  });
}
