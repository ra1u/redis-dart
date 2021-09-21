import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

main() {
  group("Throw  received Redis Errors", () {
    test("Expect error when sending Garbage", () async {
      Command cmd = await generate_connect();

      expect(cmd.send_object("GARBAGE"), throwsA(isRedisError));
    });
  });

  group("Recover after received Redis Errors", () {
    test("Expect error when sending Garbage 2", () async {
      Command cmd = await generate_connect();
      expect(cmd.send_object(["GARBAGE"]), throwsA(isRedisError));
      // next two commands over same connection should be fine
      expect(await cmd.send_object(["SET","garbage_test","grb"]),equals("OK"));
      expect(await cmd.send_object(["GET","garbage_test"]),equals("grb"));
    });
  });
}

const Matcher isRedisError = TypeMatcher<RedisError>();
