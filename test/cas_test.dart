import 'dart:async';
import 'dart:collection';

import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

void main() {
  //group(("CAS"), () {
  test("Test Incr CAS Multiple", () async {
    Command cmd = await generate_connect();

    cmd.send_object(["SET", "key", "0"]);
    Queue<Future> q = Queue();
    int N = 300;
    for (int i = 0; i < N; i++) {
      q.add(testincrcas());
    }

    await Future.wait(q);
    var val = await cmd.send_object(["GET", "key"]);
    return expect(val, equals(N.toString()));
  });
  //});
}

Future testincrcas() {
  return generate_connect().then((Command command) {
    Cas cas = Cas(command);
    return cas.watch(["key"], () {
      command.send_object(["GET", "key"]).then((val) {
        int i = int.parse(val);
        i++;
        return cas.multiAndExec((trans) {
          return trans.send_object(["SET", "key", i.toString()]);
        });
      });
    });
  });
}
