import 'package:redis/redis.dart';
import 'package:test/test.dart';
import 'main.dart';

void main() {
  group("Redis Type Conversion", () {
    test("Expect Integer conversion to Bulk String", () async {
      Command cmd = await generate_connect();

      expect(cmd.send_object(["SADD", "test_list", 1]), completion(isA<int>()));
    });
  });

}