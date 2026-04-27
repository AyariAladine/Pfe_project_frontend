import 'package:flutter_test/flutter_test.dart';
import 'package:pfe_project/models/user_model.dart';

void main() {
  group('UserRole', () {
    test('displayNameEn returns correct English names', () {
      expect(UserRole.user.displayNameEn, 'User');
      expect(UserRole.lawyer.displayNameEn, 'Lawyer');
    });

    test('displayNameAr returns correct Arabic names', () {
      expect(UserRole.user.displayNameAr, 'مستخدم');
      expect(UserRole.lawyer.displayNameAr, 'محامي');
    });

    test('displayNameFr returns correct French names', () {
      expect(UserRole.user.displayNameFr, 'Utilisateur');
      expect(UserRole.lawyer.displayNameFr, 'Avocat');
    });
  });

  group('UserModel', () {
    final fullJson = {
      '_id': 'u1',
      'name': 'Ahmed',
      'lastName': 'Ben Salem',
      'identitynumber': '12345678',
      'email': 'ahmed@example.com',
      'role': 'user',
      'phoneNumber': '22334455',
      'profileImageUrl': 'https://example.com/photo.jpg',
      'isVerified': true,
      'faceRegistered': true,
      'signatureUrl': 'https://example.com/sig.png',
      'latitude': 36.8065,
      'longitude': 10.1815,
      'createdAt': '2024-01-15T08:00:00.000Z',
      'updatedAt': '2024-06-01T12:00:00.000Z',
    };

    group('fromJson', () {
      test('parses full user JSON', () {
        final user = UserModel.fromJson(fullJson);

        expect(user.id, 'u1');
        expect(user.name, 'Ahmed');
        expect(user.lastName, 'Ben Salem');
        expect(user.identityNumber, '12345678');
        expect(user.email, 'ahmed@example.com');
        expect(user.role, UserRole.user);
        expect(user.phoneNumber, '22334455');
        expect(user.profileImageUrl, 'https://example.com/photo.jpg');
        expect(user.isVerified, isTrue);
        expect(user.faceRegistered, isTrue);
        expect(user.signatureUrl, 'https://example.com/sig.png');
        expect(user.latitude, 36.8065);
        expect(user.longitude, 10.1815);
        expect(user.createdAt, isNotNull);
        expect(user.updatedAt, isNotNull);
      });

      test('parses minimal JSON with defaults', () {
        final user = UserModel.fromJson({'_id': 'u2'});

        expect(user.id, 'u2');
        expect(user.name, '');
        expect(user.lastName, '');
        expect(user.email, '');
        expect(user.role, UserRole.user);
        expect(user.phoneNumber, '');
        expect(user.faceRegistered, isFalse);
        expect(user.profileImageUrl, isNull);
        expect(user.isVerified, isNull);
      });

      test('uses "id" field when "_id" is absent', () {
        final user = UserModel.fromJson({'id': 'u3', 'name': 'Test'});
        expect(user.id, 'u3');
      });

      test('parses lawyer role', () {
        final user = UserModel.fromJson({
          '_id': 'l1',
          'role': 'lawyer',
        });
        expect(user.role, UserRole.lawyer);
      });

      test('parses role case-insensitively', () {
        final user = UserModel.fromJson({
          '_id': 'l2',
          'role': 'LAWYER',
        });
        expect(user.role, UserRole.lawyer);
      });

      test('defaults to user role for unknown role string', () {
        final user = UserModel.fromJson({
          '_id': 'u4',
          'role': 'admin',
        });
        expect(user.role, UserRole.user);
      });

      test('defaults to user role for null role', () {
        final user = UserModel.fromJson({
          '_id': 'u5',
          'role': null,
        });
        expect(user.role, UserRole.user);
      });
    });

    test('fullName combines name and lastName', () {
      final user = UserModel.fromJson(fullJson);
      expect(user.fullName, 'Ahmed Ben Salem');
    });

    test('fullName with empty lastName', () {
      final user = UserModel.fromJson({
        '_id': 'u6',
        'name': 'Solo',
        'lastName': '',
      });
      expect(user.fullName, 'Solo ');
    });

    group('toJson', () {
      test('includes required fields', () {
        final user = UserModel.fromJson(fullJson);
        final json = user.toJson();

        expect(json['name'], 'Ahmed');
        expect(json['lastName'], 'Ben Salem');
        expect(json['identitynumber'], '12345678');
        expect(json['email'], 'ahmed@example.com');
        expect(json['role'], 'user');
        expect(json['phoneNumber'], '22334455');
        expect(json['faceRegistered'], isTrue);
      });

      test('includes optional fields when present', () {
        final user = UserModel.fromJson(fullJson);
        final json = user.toJson();

        expect(json['profileImageUrl'], 'https://example.com/photo.jpg');
        expect(json['isVerified'], isTrue);
        expect(json['signatureUrl'], 'https://example.com/sig.png');
        expect(json['latitude'], 36.8065);
        expect(json['longitude'], 10.1815);
      });

      test('omits null optional fields', () {
        final user = UserModel.fromJson({'_id': 'u7'});
        final json = user.toJson();

        expect(json.containsKey('profileImageUrl'), isFalse);
        expect(json.containsKey('isVerified'), isFalse);
        expect(json.containsKey('signatureUrl'), isFalse);
        expect(json.containsKey('latitude'), isFalse);
        expect(json.containsKey('longitude'), isFalse);
      });
    });

    group('copyWith', () {
      test('creates a copy with updated name', () {
        final user = UserModel.fromJson(fullJson);
        final updated = user.copyWith(name: 'Khalil');

        expect(updated.name, 'Khalil');
        expect(updated.lastName, user.lastName); // unchanged
        expect(updated.id, user.id); // unchanged
      });

      test('creates a copy with updated role', () {
        final user = UserModel.fromJson(fullJson);
        final updated = user.copyWith(role: UserRole.lawyer);

        expect(updated.role, UserRole.lawyer);
        expect(updated.email, user.email);
      });

      test('creates a copy with updated location', () {
        final user = UserModel.fromJson(fullJson);
        final updated = user.copyWith(latitude: 33.0, longitude: 9.0);

        expect(updated.latitude, 33.0);
        expect(updated.longitude, 9.0);
      });
    });

    test('toString includes key fields', () {
      final user = UserModel.fromJson(fullJson);
      final str = user.toString();

      expect(str, contains('Ahmed'));
      expect(str, contains('Ben Salem'));
      expect(str, contains('ahmed@example.com'));
      expect(str, contains('user'));
    });
  });
}
