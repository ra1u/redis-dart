import "dart:async";

import 'dart:async';
import 'dart:io';

import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

Future test_primitives() async {
  Prophecy f = new Prophecy.value(5);
  expect(f.future, completion(equals(5)));

  Prophecy f1 = new Prophecy.value(4);
  Prophecy f2 = f1.map((x) => x + 2);
  expect(f2.future, completion(equals(6)));

  Prophecy h = new Prophecy.value("hello ");
  Prophecy w = new Prophecy.value("world");
  Prophecy hw = zipWith2((a, b) => a + b, h, w);
  expect(hw.future, completion(equals("hello world")));

  p(v) => new Prophecy.value(v);

  sum3(a1, a2, a3) => a1 + a2 + a3;
  expect(
      zipWith3(sum3, p("1"), p("2"), p("3")).future, completion(equals("123")));
  //
  sum4(a1, a2, a3, a4) => a1 + a2 + a3 + a4;
  expect(zipWith4(sum4, p("1"), p("2"), p("3"), p("4")).future,
      completion(equals("1234")));
  //
  sum5(a1, a2, a3, a4, a5) => a1 + a2 + a3 + a4 + a5;
  expect(zipWith5(sum5, p("1"), p("2"), p("3"), p("4"), p("5")).future,
      completion(equals("12345")));
  //
  sum6(a1, a2, a3, a4, a5, a6) => a1 + a2 + a3 + a4 + a5 + a6;
  expect(zipWith6(sum6, p("1"), p("2"), p("3"), p("4"), p("5"), p("6")).future,
      completion(equals("123456")));
  //
  sum7(a1, a2, a3, a4, a5, a6, a7) => a1 + a2 + a3 + a4 + a5 + a6 + a7;
  expect(
      zipWith7(sum7, p("1"), p("2"), p("3"), p("4"), p("5"), p("6"), p("7"))
          .future,
      completion(equals("1234567")));
  //
  sum8(a1, a2, a3, a4, a5, a6, a7, a8) => a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8;
  expect(
      zipWith8(sum8, p("1"), p("2"), p("3"), p("4"), p("5"), p("6"), p("7"),
              p("8"))
          .future,
      completion(equals("12345678")));
}

Future test_perf(int n, [bool piping = true]) async {
  int N = n;
  int rec = 0;
  int start;
  var command = await generate_connect();
  print("connected");
  start = new DateTime.now().millisecondsSinceEpoch;
  if (piping) {
    command.pipe_start();
  }
  await command.send_object(["SET", "test", "0"]);
  Prophecy tot = new Prophecy.value(0);
  for (int i = 1; i <= N; i++) {
    Prophecy fv = new Prophecy(command.send_object(["INCR", "test"]));
    fv.map((v) {
      if (i != v) {
        throw ("wrong received value, we got $v");
      }
      return v;
    });
    tot = zipWith2((x, y) => x + y, fv, tot);
  }
  if (piping) {
    command.pipe_end();
  }

  var v = await command.send_object(["GET", "test"]);
  if (N != v) {
    throw ("wrong received value, we got $v  instead of $N");
  }

  var t = await tot.future;
  //num last = await fv.future;
  print("tot $t");
  int stop = new DateTime.now().millisecondsSinceEpoch;
  int time = stop - start;
  print("done in ${stop - start} ms");
  double perf = n / time * 1000;
  print("perf $perf");
  return 0;
}

void main() {
  //print("hai");
  //await test_perf_f3(200000, true);
  //exit(0);
  //return;
  test("Test Basics", () {
    return test_primitives();
  });
}
