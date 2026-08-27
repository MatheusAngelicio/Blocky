import 'package:blocky/app/blocky_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates the Blocky application', () {
    expect(const BlockyApp(), isA<BlockyApp>());
  });
}
