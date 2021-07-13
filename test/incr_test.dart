import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

void main() {
  group("Redis Commands test", () {
    String key = "keyIncr1";
    test("incr 0 -> 1", () async {
      Command cmd = await generate_connect();
      await cmd.set(key, '0');
      expect(await cmd.incr(key), equals(1));
      expect(await cmd.get(key), equals('1'));
    });
  });
}
