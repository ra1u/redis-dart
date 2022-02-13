import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';
import 'dart:math';


List<int> _gen_rnd_array(Random rng){
  int len = 1 + rng.nextInt(1000);
  List<int> r = List<int>.filled(len,0);
  for(int i=0;i<len;++i){
    r[i] = rng.nextInt(255);
  }
  return r;
}

void main() {
  group("Test for sending and parsing binary data", () {
    String key = "keyBinary";

    test("binary", () async {
      Command _cmd = await generate_connect();
      Command cmd_bin = Command.from(_cmd).setParser(RedisParserBulkBinary());

      List<int> d = [1,2,3,4,5,6,7,8,9];
      var r = await cmd_bin.send_object(["SET", key, RedisBulk(d)]);
      expect(r, equals("OK"));
      expect(await cmd_bin.send_object(["GET", key]), equals(d));
    });
  
    test("binary with randomly generated data", () async {
      Command _cmd = await generate_connect();
      Command cmd_bin = Command.from(_cmd).setParser(RedisParserBulkBinary());
      var rng = Random(); 

      for(int i = 0;i < 1000; ++i){
        List<int> d = _gen_rnd_array(rng);
        var r = await cmd_bin.send_object(["SET", key, RedisBulk(d)]);
        expect(r, equals("OK"));
        expect(await cmd_bin.send_object(["GET", key]), equals(d));
      }
    });
  });
}
