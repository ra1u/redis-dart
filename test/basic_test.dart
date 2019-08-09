import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

void main() {
  group("Basic Redis Functionality test", () {
    String key = "key1b1";

    test("One by One", () async {
      Command cmd = await generate_connect();

      expect(await cmd.send_object(["SET", key, 0]), equals("OK"));

      for (int i = 0; i < 100; i++) {
        expect(await cmd.send_object(["INCR", key]), equals(i + 1));
      }
    });
  });
}
