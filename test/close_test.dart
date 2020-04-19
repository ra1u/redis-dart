import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

main() {
  group("Close test", () {
    test("Expect error when sending Garbage", () async {
      Command cmd = await generate_connect();
      await cmd.send_object(["SET", "test", "0"]);
      var last_future;
      bool p = true;
      for (int i = 1; i <= 100000; i++) {
        last_future = cmd.send_object(["INCR", "test"]).then((v) {
          if (i != v) {
            throw ("wrong received value, we got $v");
          }
      }).catchError((e) {
          if(p){
            //Type t = typeof(e);
            print("error $e ${e.runtimeType}");
            p = false;
          }
          // stream closed
        });
      }
      await cmd.get_connection().close();
      await last_future;
      //expect(cmd.send_object("GARBAGE"), throwsA(RedisError));
    });
  });
}

const Matcher isRedisError = TypeMatcher<RedisError>();
