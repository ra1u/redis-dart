import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

void main() {
  group("Test Unicode Support", () {
    test("Set and Get Unicode Value", () async {
      Command cmd = await generate_connect();
      String unicodeString = "中华人民共和😊👍📱😀😬";


      expect(cmd.send_object(["SET", "unicode_test", unicodeString]),
          completion(equals("OK")));

      expect(cmd.send_object(["GET", "unicode_test"]),
          completion(equals(unicodeString)));
    });
  });
}