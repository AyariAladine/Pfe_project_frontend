import 'package:flutter_test/flutter_test.dart';
import 'package:pfe_project/models/application_model.dart';

void main() {
  group('ApplicationStatus', () {
    group('toJson', () {
      test('converts camelCase statuses to snake_case', () {
        expect(ApplicationStatus.underReview.toJson(), 'under_review');
        expect(ApplicationStatus.visitScheduled.toJson(), 'visit_scheduled');
        expect(ApplicationStatus.preApproved.toJson(), 'pre_approved');
        expect(ApplicationStatus.awaitingLawyer.toJson(), 'awaiting_lawyer');
        expect(
            ApplicationStatus.contractDrafting.toJson(), 'contract_drafting');
      });

      test('keeps simple statuses as-is', () {
        expect(ApplicationStatus.pending.toJson(), 'pending');
        expect(ApplicationStatus.accepted.toJson(), 'accepted');
        expect(ApplicationStatus.negotiation.toJson(), 'negotiation');
        expect(ApplicationStatus.rejected.toJson(), 'rejected');
        expect(ApplicationStatus.cancelled.toJson(), 'cancelled');
      });
    });

    group('fromJson', () {
      test('parses snake_case strings', () {
        expect(ApplicationStatus.fromJson('under_review'),
            ApplicationStatus.underReview);
        expect(ApplicationStatus.fromJson('visit_scheduled'),
            ApplicationStatus.visitScheduled);
        expect(ApplicationStatus.fromJson('pre_approved'),
            ApplicationStatus.preApproved);
        expect(ApplicationStatus.fromJson('awaiting_lawyer'),
            ApplicationStatus.awaitingLawyer);
        expect(ApplicationStatus.fromJson('contract_drafting'),
            ApplicationStatus.contractDrafting);
      });

      test('parses simple status names', () {
        expect(
            ApplicationStatus.fromJson('pending'), ApplicationStatus.pending);
        expect(ApplicationStatus.fromJson('accepted'),
            ApplicationStatus.accepted);
        expect(ApplicationStatus.fromJson('negotiation'),
            ApplicationStatus.negotiation);
        expect(ApplicationStatus.fromJson('rejected'),
            ApplicationStatus.rejected);
        expect(ApplicationStatus.fromJson('cancelled'),
            ApplicationStatus.cancelled);
      });

      test('is case-insensitive', () {
        expect(ApplicationStatus.fromJson('PENDING'), ApplicationStatus.pending);
        expect(ApplicationStatus.fromJson('Under_Review'),
            ApplicationStatus.underReview);
      });

      test('handles dashes as well as underscores', () {
        expect(ApplicationStatus.fromJson('under-review'),
            ApplicationStatus.underReview);
        expect(ApplicationStatus.fromJson('pre-approved'),
            ApplicationStatus.preApproved);
      });

      test('defaults to pending for unknown strings', () {
        expect(ApplicationStatus.fromJson('unknown'), ApplicationStatus.pending);
        expect(ApplicationStatus.fromJson(''), ApplicationStatus.pending);
      });
    });

    group('isActive', () {
      test('returns true for actionable statuses', () {
        expect(ApplicationStatus.pending.isActive, isTrue);
        expect(ApplicationStatus.underReview.isActive, isTrue);
        expect(ApplicationStatus.visitScheduled.isActive, isTrue);
        expect(ApplicationStatus.preApproved.isActive, isTrue);
        expect(ApplicationStatus.accepted.isActive, isTrue);
        expect(ApplicationStatus.negotiation.isActive, isTrue);
        expect(ApplicationStatus.awaitingLawyer.isActive, isTrue);
      });

      test('returns false for terminal statuses', () {
        expect(ApplicationStatus.contractDrafting.isActive, isFalse);
        expect(ApplicationStatus.rejected.isActive, isFalse);
        expect(ApplicationStatus.cancelled.isActive, isFalse);
      });
    });

    test('roundtrip: toJson then fromJson preserves value', () {
      for (final status in ApplicationStatus.values) {
        expect(
          ApplicationStatus.fromJson(status.toJson()),
          status,
          reason: 'Roundtrip failed for $status',
        );
      }
    });
  });

  group('ApplicationType', () {
    test('toJson returns name', () {
      expect(ApplicationType.rent.toJson(), 'rent');
      expect(ApplicationType.buy.toJson(), 'buy');
    });

    test('fromJson is case-insensitive', () {
      expect(ApplicationType.fromJson('RENT'), ApplicationType.rent);
      expect(ApplicationType.fromJson('Buy'), ApplicationType.buy);
    });

    test('defaults to rent for unknown values', () {
      expect(ApplicationType.fromJson('lease'), ApplicationType.rent);
    });
  });

  group('ApplicationMessage', () {
    test('fromJson parses populated sender object', () {
      final msg = ApplicationMessage.fromJson({
        '_id': 'm1',
        'applicationId': 'a1',
        'sender': {
          '_id': 'u1',
          'name': 'John',
          'lastName': 'Doe',
        },
        'content': 'Hello',
        'createdAt': '2024-06-01T10:00:00.000Z',
        'isRead': true,
      });

      expect(msg.id, 'm1');
      expect(msg.senderId, 'u1');
      expect(msg.senderName, 'John Doe');
      expect(msg.content, 'Hello');
      expect(msg.isRead, isTrue);
    });

    test('fromJson handles string sender (unpopulated)', () {
      final msg = ApplicationMessage.fromJson({
        '_id': 'm2',
        'applicationId': 'a1',
        'sender': 'user123',
        'content': 'Hi',
        'createdAt': '2024-06-01T10:00:00.000Z',
      });

      expect(msg.senderId, 'user123');
      expect(msg.isRead, isFalse);
    });
  });

  group('ApplicationStatusEntry', () {
    test('fromJson parses status transition', () {
      final entry = ApplicationStatusEntry.fromJson({
        'fromStatus': 'pending',
        'toStatus': 'under_review',
        'changedBy': 'admin1',
        'note': 'Reviewing',
        'createdAt': '2024-06-01T12:00:00.000Z',
      });

      expect(entry.fromStatus, ApplicationStatus.pending);
      expect(entry.toStatus, ApplicationStatus.underReview);
      expect(entry.changedBy, 'admin1');
      expect(entry.note, 'Reviewing');
    });
  });

  group('ApplicationModel', () {
    final minimalJson = {
      '_id': 'app1',
      'propertyId': 'prop1',
      'applicantId': 'user1',
      'type': 'rent',
      'status': 'pending',
      'createdAt': '2024-06-01T00:00:00.000Z',
    };

    test('fromJson parses minimal JSON', () {
      final app = ApplicationModel.fromJson(minimalJson);

      expect(app.id, 'app1');
      expect(app.propertyId, 'prop1');
      expect(app.applicantId, 'user1');
      expect(app.type, ApplicationType.rent);
      expect(app.status, ApplicationStatus.pending);
      expect(app.dealAmount, isNull);
      expect(app.assignedLawyerId, isNull);
      expect(app.assignedLawyer, isNull);
    });

    test('fromJson parses negotiation fields', () {
      final json = {
        ...minimalJson,
        'status': 'negotiation',
        'dealAmount': 1500.50,
        'assignedLawyerId': 'lawyer1',
      };
      final app = ApplicationModel.fromJson(json);

      expect(app.status, ApplicationStatus.negotiation);
      expect(app.dealAmount, 1500.50);
      expect(app.assignedLawyerId, 'lawyer1');
    });

    test('fromJson handles populated assignedLawyer object', () {
      final json = {
        ...minimalJson,
        'assignedLawyer': {
          '_id': 'lawyer1',
          'name': 'Ahmed',
          'lastName': 'Ben Ali',
          'email': 'ahmed@example.com',
        },
      };
      final app = ApplicationModel.fromJson(json);

      expect(app.assignedLawyerId, 'lawyer1');
      expect(app.assignedLawyer, isNotNull);
      expect(app.assignedLawyerName, 'Ahmed Ben Ali');
    });

    test('fromJson handles populated propertyId as object', () {
      final json = {
        '_id': 'app2',
        'propertyId': {
          '_id': 'prop99',
          'propertyAddress': '123 Main St',
          'propertyImages': ['img1.jpg', 'img2.jpg'],
          'owner': {
            'name': 'Owner',
            'lastName': 'Name',
          },
        },
        'applicantId': 'user1',
        'type': 'buy',
        'createdAt': '2024-06-01T00:00:00.000Z',
      };
      final app = ApplicationModel.fromJson(json);

      expect(app.propertyId, 'prop99');
      expect(app.property, isNotNull);
      expect(app.propertyAddress, '123 Main St');
      expect(app.propertyFirstImage, 'img1.jpg');
      expect(app.ownerName, 'Owner Name');
    });

    test('fromJson handles populated applicant', () {
      final json = {
        ...minimalJson,
        'applicantId': {
          '_id': 'user55',
          'name': 'Fatma',
          'lastName': 'Trabelsi',
          'email': 'fatma@example.com',
          'phoneNumber': '21345678',
          'faceRegistered': true,
          'signatureUrl': 'https://example.com/sig.png',
          'isVerified': true,
        },
      };
      final app = ApplicationModel.fromJson(json);

      expect(app.applicantId, 'user55');
      expect(app.applicantName, 'Fatma Trabelsi');
      expect(app.applicantEmail, 'fatma@example.com');
      expect(app.applicantPhone, '21345678');
      expect(app.applicantFaceRegistered, isTrue);
      expect(app.applicantHasSignature, isTrue);
      expect(app.applicantIsVerified, isTrue);
    });

    test('applicantPhone returns null for placeholder number', () {
      final json = {
        ...minimalJson,
        'applicantId': {
          '_id': 'u1',
          'name': 'Test',
          'lastName': 'User',
          'phoneNumber': '00000000',
        },
      };
      final app = ApplicationModel.fromJson(json);
      expect(app.applicantPhone, isNull);
    });

    test('fromJson parses statusHistory', () {
      final json = {
        ...minimalJson,
        'statusHistory': [
          {
            'fromStatus': 'pending',
            'toStatus': 'under_review',
            'createdAt': '2024-06-01T10:00:00.000Z',
          },
          {
            'fromStatus': 'under_review',
            'toStatus': 'accepted',
            'createdAt': '2024-06-02T10:00:00.000Z',
          },
        ],
      };
      final app = ApplicationModel.fromJson(json);

      expect(app.statusHistory.length, 2);
      expect(app.statusHistory[0].toStatus, ApplicationStatus.underReview);
      expect(app.statusHistory[1].toStatus, ApplicationStatus.accepted);
    });

    group('assignedLawyerName', () {
      test('returns null when no lawyer is assigned', () {
        final app = ApplicationModel.fromJson(minimalJson);
        expect(app.assignedLawyerName, isNull);
      });

      test('returns null when lawyer map has empty names', () {
        final json = {
          ...minimalJson,
          'assignedLawyer': {'_id': 'l1', 'name': '', 'lastName': ''},
        };
        final app = ApplicationModel.fromJson(json);
        expect(app.assignedLawyerName, isNull);
      });

      test('returns full name when lawyer is populated', () {
        final json = {
          ...minimalJson,
          'assignedLawyer': {
            '_id': 'l1',
            'name': 'Sami',
            'lastName': 'Karoui',
          },
        };
        final app = ApplicationModel.fromJson(json);
        expect(app.assignedLawyerName, 'Sami Karoui');
      });
    });

    group('copyWith', () {
      test('creates a copy with updated status', () {
        final app = ApplicationModel.fromJson(minimalJson);
        final updated = app.copyWith(status: ApplicationStatus.accepted);

        expect(updated.status, ApplicationStatus.accepted);
        expect(updated.id, app.id); // unchanged
      });

      test('creates a copy with deal amount and lawyer', () {
        final app = ApplicationModel.fromJson(minimalJson);
        final updated = app.copyWith(
          dealAmount: 2000.0,
          assignedLawyerId: 'lawyer42',
          assignedLawyer: {'_id': 'lawyer42', 'name': 'Ali', 'lastName': 'B'},
        );

        expect(updated.dealAmount, 2000.0);
        expect(updated.assignedLawyerId, 'lawyer42');
        expect(updated.assignedLawyerName, 'Ali B');
      });
    });

    test('toJson includes only submission fields', () {
      final app = ApplicationModel.fromJson({
        ...minimalJson,
        'message': 'I am interested',
      });
      final json = app.toJson();

      expect(json['propertyId'], 'prop1');
      expect(json['type'], 'rent');
      expect(json['message'], 'I am interested');
      // Should NOT include status, id, etc.
      expect(json.containsKey('_id'), isFalse);
      expect(json.containsKey('status'), isFalse);
    });
  });
}
