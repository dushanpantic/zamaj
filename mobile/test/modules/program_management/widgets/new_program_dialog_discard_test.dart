import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/program_management/widgets/new_program_dialog.dart';

void main() {
  group('shouldConfirmDiscard', () {
    test('confirms when a name has been typed', () {
      expect(shouldConfirmDiscard('Push day'), isTrue);
    });

    test('confirms when the typed name has surrounding whitespace', () {
      expect(shouldConfirmDiscard('  x '), isTrue);
    });

    test('does not confirm for an empty field', () {
      expect(shouldConfirmDiscard(''), isFalse);
    });

    test('does not confirm for a whitespace-only field', () {
      expect(shouldConfirmDiscard('   '), isFalse);
    });
  });
}
