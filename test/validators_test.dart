import 'package:flutter_test/flutter_test.dart';
import 'package:focus_room/features/auth/domain/validators.dart';

void main() {
  group('FormValidators', () {
    test('validateDisplayName', () {
      expect(FormValidators.validateDisplayName(null), 'Nama lengkap wajib diisi');
      expect(FormValidators.validateDisplayName(''), 'Nama lengkap wajib diisi');
      expect(FormValidators.validateDisplayName('   '), 'Nama lengkap wajib diisi');
      expect(FormValidators.validateDisplayName('A'), 'Nama minimal 2 karakter');
      expect(FormValidators.validateDisplayName('Farhan'), isNull);
    });

    test('validateEmail', () {
      expect(FormValidators.validateEmail(null), 'Email wajib diisi');
      expect(FormValidators.validateEmail(''), 'Email wajib diisi');
      expect(FormValidators.validateEmail('bukanemail'), 'Format email tidak valid');
      expect(FormValidators.validateEmail('nama@'), 'Format email tidak valid');
      expect(FormValidators.validateEmail('nama@kampus'), 'Format email tidak valid');
      expect(FormValidators.validateEmail('nama@kampus.ac.id'), isNull);
      expect(FormValidators.validateEmail('user.test+1@gmail.com'), isNull);
    });

    test('validatePassword', () {
      expect(FormValidators.validatePassword(null), 'Password wajib diisi');
      expect(FormValidators.validatePassword(''), 'Password wajib diisi');
      expect(FormValidators.validatePassword('1234567'), 'Password minimal 8 karakter');
      expect(FormValidators.validatePassword('12345678'), isNull);
      expect(FormValidators.validatePassword('kuncirahasia'), isNull);
    });

    test('validateConfirmPassword', () {
      expect(FormValidators.validateConfirmPassword('rahasia123', null), 'Konfirmasi password wajib diisi');
      expect(FormValidators.validateConfirmPassword('rahasia123', ''), 'Konfirmasi password wajib diisi');
      expect(FormValidators.validateConfirmPassword('rahasia123', 'berbeda123'), 'Konfirmasi password tidak cocok');
      expect(FormValidators.validateConfirmPassword('rahasia123', 'rahasia123'), isNull);
    });
  });
}
