import 'package:app/io.dart';
import 'package:flutter_test/flutter_test.dart';

const String testCSV = "";

void main() {
  test('csv', () {
    return loadCSV('"eins", "zwei", "drei"\n"1","2","3"') == [
      ["eins", "zwei", "drei"],
      [1, 2, 3]
    ] && storeCSV([["eins", "zwei", "drei"],
      [1, 2, 3]
    ]) == '"eins","zwei","drei"\n"1","2","3"';
  });

  test('test test', () {
    return false;
  });
}
