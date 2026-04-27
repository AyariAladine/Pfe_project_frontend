import 'package:flutter_test/flutter_test.dart';
import 'package:pfe_project/models/contract_model.dart';

void main() {
  group('ContractType', () {
    test('toJson returns correct strings', () {
      expect(ContractType.rental.toJson(), 'rental');
      expect(ContractType.sale.toJson(), 'sale');
      expect(ContractType.rentalAnnex.toJson(), 'rental_annex');
    });

    test('fromJson parses correctly', () {
      expect(ContractType.fromJson('rental'), ContractType.rental);
      expect(ContractType.fromJson('sale'), ContractType.sale);
      expect(ContractType.fromJson('rental_annex'), ContractType.rentalAnnex);
    });

    test('fromJson handles dashes', () {
      expect(ContractType.fromJson('rental-annex'), ContractType.rentalAnnex);
    });

    test('fromJson defaults to rental for unknown', () {
      expect(ContractType.fromJson('unknown'), ContractType.rental);
    });

    test('roundtrip preserves value', () {
      for (final t in ContractType.values) {
        expect(ContractType.fromJson(t.toJson()), t);
      }
    });
  });

  group('ContractStatus', () {
    test('toJson returns correct strings', () {
      expect(ContractStatus.draft.toJson(), 'draft');
      expect(ContractStatus.pendingReview.toJson(), 'pending_review');
      expect(ContractStatus.pendingSignatures.toJson(), 'pending_signatures');
      expect(ContractStatus.signedByOwner.toJson(), 'signed_by_owner');
      expect(ContractStatus.signedByTenant.toJson(), 'signed_by_tenant');
      expect(ContractStatus.completed.toJson(), 'completed');
      expect(ContractStatus.cancelled.toJson(), 'cancelled');
    });

    test('fromJson parses correctly', () {
      expect(ContractStatus.fromJson('draft'), ContractStatus.draft);
      expect(ContractStatus.fromJson('pending_review'),
          ContractStatus.pendingReview);
      expect(ContractStatus.fromJson('pending_signatures'),
          ContractStatus.pendingSignatures);
      expect(ContractStatus.fromJson('signed_by_owner'),
          ContractStatus.signedByOwner);
      expect(ContractStatus.fromJson('signed_by_tenant'),
          ContractStatus.signedByTenant);
      expect(
          ContractStatus.fromJson('completed'), ContractStatus.completed);
      expect(
          ContractStatus.fromJson('cancelled'), ContractStatus.cancelled);
    });

    test('fromJson defaults to draft for unknown', () {
      expect(ContractStatus.fromJson('xyz'), ContractStatus.draft);
    });

    test('roundtrip preserves value', () {
      for (final s in ContractStatus.values) {
        expect(ContractStatus.fromJson(s.toJson()), s);
      }
    });
  });

  group('ContractModel', () {
    final fullJson = {
      '_id': 'c1',
      'applicationId': 'app1',
      'type': 'rental',
      'status': 'draft',
      'lawyerId': 'l1',
      'ownerId': 'o1',
      'tenantId': 't1',
      'propertyId': 'p1',
      'content': 'Contract body text',
      'fields': {'paymentDay': '5', 'depositAmount': '2000'},
      'dealAmount': 850.0,
      'startDate': '2025-01-01T00:00:00.000Z',
      'endDate': '2025-12-31T00:00:00.000Z',
      'createdAt': '2025-01-01T00:00:00.000Z',
      'updatedAt': '2025-06-15T00:00:00.000Z',
    };

    test('fromJson parses full JSON', () {
      final c = ContractModel.fromJson(fullJson);

      expect(c.id, 'c1');
      expect(c.applicationId, 'app1');
      expect(c.type, ContractType.rental);
      expect(c.status, ContractStatus.draft);
      expect(c.lawyerId, 'l1');
      expect(c.ownerId, 'o1');
      expect(c.tenantId, 't1');
      expect(c.propertyId, 'p1');
      expect(c.content, 'Contract body text');
      expect(c.fields['paymentDay'], '5');
      expect(c.fields['depositAmount'], '2000');
      expect(c.dealAmount, 850.0);
      expect(c.startDate, isNotNull);
      expect(c.endDate, isNotNull);
    });

    test('fromJson parses minimal JSON with defaults', () {
      final c = ContractModel.fromJson({
        '_id': 'c2',
        'createdAt': '2025-01-01T00:00:00.000Z',
      });

      expect(c.id, 'c2');
      expect(c.type, ContractType.rental);
      expect(c.status, ContractStatus.draft);
      expect(c.content, '');
      expect(c.fields, isEmpty);
      expect(c.dealAmount, 0.0);
      expect(c.startDate, isNull);
      expect(c.endDate, isNull);
    });

    test('fromJson handles populated relations', () {
      final c = ContractModel.fromJson({
        ...fullJson,
        'ownerId': {
          '_id': 'o1',
          'name': 'Ali',
          'lastName': 'Ben Ahmed',
        },
        'tenantId': {
          '_id': 't1',
          'name': 'Sami',
          'lastName': 'Trabelsi',
        },
        'lawyerId': {
          '_id': 'l1',
          'name': 'Karim',
          'lastName': 'Souissi',
        },
        'propertyId': {
          '_id': 'p1',
          'propertyAddress': '10 Rue de la Liberté, Tunis',
        },
      });

      expect(c.ownerId, 'o1');
      expect(c.ownerName, 'Ali Ben Ahmed');
      expect(c.tenantName, 'Sami Trabelsi');
      expect(c.lawyerName, 'Karim Souissi');
      expect(c.propertyAddress, '10 Rue de la Liberté, Tunis');
    });

    test('convenience getters return defaults when unpopulated', () {
      final c = ContractModel.fromJson({
        '_id': 'c3',
        'createdAt': '2025-01-01T00:00:00.000Z',
      });

      expect(c.ownerName, '—');
      expect(c.tenantName, '—');
      expect(c.lawyerName, '—');
      expect(c.propertyAddress, '—');
    });

    group('isEditable', () {
      test('returns true for draft', () {
        final c = ContractModel.fromJson({
          ...fullJson,
          'status': 'draft',
        });
        expect(c.isEditable, isTrue);
      });

      test('returns true for pending_review', () {
        final c = ContractModel.fromJson({
          ...fullJson,
          'status': 'pending_review',
        });
        expect(c.isEditable, isTrue);
      });

      test('returns false for pending_signatures', () {
        final c = ContractModel.fromJson({
          ...fullJson,
          'status': 'pending_signatures',
        });
        expect(c.isEditable, isFalse);
      });

      test('returns false for completed', () {
        final c = ContractModel.fromJson({
          ...fullJson,
          'status': 'completed',
        });
        expect(c.isEditable, isFalse);
      });
    });

    test('isSigned returns true only for completed', () {
      expect(
        ContractModel.fromJson({...fullJson, 'status': 'completed'}).isSigned,
        isTrue,
      );
      expect(
        ContractModel.fromJson({...fullJson, 'status': 'draft'}).isSigned,
        isFalse,
      );
    });

    test('copyWith creates updated copy', () {
      final c = ContractModel.fromJson(fullJson);
      final updated = c.copyWith(
        status: ContractStatus.pendingSignatures,
        content: 'Updated content',
      );

      expect(updated.status, ContractStatus.pendingSignatures);
      expect(updated.content, 'Updated content');
      expect(updated.id, c.id); // unchanged
      expect(updated.dealAmount, c.dealAmount); // unchanged
    });

    test('toJson includes submission fields', () {
      final c = ContractModel.fromJson(fullJson);
      final json = c.toJson();

      expect(json['applicationId'], 'app1');
      expect(json['type'], 'rental');
      expect(json['content'], 'Contract body text');
      expect(json['fields'], isA<Map>());
      expect(json['dealAmount'], 850.0);
      expect(json.containsKey('startDate'), isTrue);
      expect(json.containsKey('endDate'), isTrue);
    });
  });
}
