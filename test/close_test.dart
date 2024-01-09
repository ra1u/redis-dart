import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

main() {
  group("Close test", () {
    test("Expect error when sending Garbage", () async {
      Command cmd = await generate_connect();
      await cmd.send_object(["SET", "test", "0"]);
      for (int i = 1; i <= 100000; i++) {
        cmd.send_object(["INCR", "test"]).then((v) {
          if (i != v) {
            throw ("wrong received value, we got $v");
          }
        }).catchError((e) {
          // stream closed
        });
      }
      await cmd.get_connection().close();
      //expect(cmd.send_object("GARBAGE"), throwsA(isRedisError));
    });

    test("Open/Close in loop", () async {
      for (int i = 0; i < 1000; ++i) {
        Command cmd = await generate_connect();
        await cmd.send_object(["SET", "test", "0"]);
        await cmd.get_connection().close();
      }
    });
  });
}

const Matcher isRedisError = TypeMatcher<RedisError>();
