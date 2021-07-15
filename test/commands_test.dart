import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

void main() {
  group("Commands", () {

    test("incr 0 -> 1", () async {
      String key = "keyIncr1";
      Command cmd = await generate_connect();
      await cmd.set(key, '0');
      expect(await cmd.incr(key), equals(1));
      expect(await cmd.get(key), equals('1'));
    });

    test("dbsize", () async {
      String key = "keySize";
      Command cmd = await generate_connect();
      await cmd.send_object(["FLUSHALL"]);
      await cmd.set(key, "test");
      final size = await cmd.dbsize();
      expect(size, equals(1));
    });
  });
}
