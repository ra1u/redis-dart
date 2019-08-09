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
}

const Matcher isRedisError = TypeMatcher<RedisError>();
