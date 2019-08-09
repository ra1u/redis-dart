import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

void main() {
  test("Test Lua Native", () async {
    Command cmd = await generate_connect();

    expect((await cmd.send_object([
      "EVAL",
      "return {KEYS[1],{KEYS[2],{ARGV[1]},ARGV[2]},2}",
      "2",
      "key1",
      "key2",
      "first",
      "2"
    ])).toString(), equals("[key1, [key2, [first], 2], 2]"));
  });
}
