import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';
import 'dart:io';

Future<Command> generate_connect_broken() {
  return RedisConnection().connect("localhost", 2);
}

main() {
  group("Throw  received Redis Errors", () {
    test("Expect error when sending Garbage", () async {
      Command cmd = await generate_connect();
      expect(() => cmd.send_object("GARBAGE"), throwsA(isRedisError));
    });
  });

  group("Recover after received Redis Errors", () {
    test("Expect error when sending Garbage 2", () async {
      Command cmd = await generate_connect();
      expect(() => cmd.send_object(["GARBAGE"]), throwsA(isRedisError));
      // next two commands over same connection should be fine
      var ok = await cmd.send_object(["SET", "garbage_test", "grb"]);
      expect(ok, equals("OK"));
      var v = await cmd.send_object(["GET", "garbage_test"]);
      expect(v, equals("grb"));
    });
  });

  group("Handle low lewel error", () {
    test("handle error that is out of our contoll", () {
      expect(generate_connect_broken, throwsA(isA<SocketException>()));
    });
  });
}

const Matcher isRedisError = TypeMatcher<RedisException>();
