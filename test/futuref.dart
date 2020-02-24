import "dart:async";

import 'dart:async';
import 'dart:io';

import 'package:redis/redis.dart';

import 'main.dart';

class FutureF<T> {
  Future<T> Function() _f;

  FutureF._func(Future<T> Function() v) {
    _f = v;
  }

  FutureF._future(Future<T> f) {
    this._f = () => f;
  }

  FutureF._value(T v) {
    _f = () => new Future.value(v);
  }

  FutureF<E> map<E>(E f(T)) {
    return new FutureF._func(() => this._eval().then((x) => f(x)));
  }

  Future<T> _eval() {
    return _f();
  }

  FutureF.value(T v){
    _f = () => new Future.value(v);
  }
  
  Future<T> get future => this._eval();
}


FutureF futuref(Future f) {
  return new FutureF._future(f);
}

/*
Future futuref(Future f) {
  return new Future.value(new FutureF._future(f));
}
*/
  
FutureF<R> zipWith2<R, A1, A2>(R fun(A1, A2), FutureF<A1> a1, FutureF<A2> a2) {
  // this version seems to be both simple, correct and most performant
  return new FutureF<R>._future(a1._eval().then((a) {
    return a2._eval().then((b) {
      return fun(a, b);
    });
  }));
}

test() async {
  // var  c = new Future(() => 5);
  var f = new FutureF._future(new Future.value(5));
  var f2 = f.map((x) => x + 2);
  print("before map");
  var v2 = await f2.future;
  print("v2 $v2");
  var f3 = zipWith2((x, y) {
    print("zip");
    return x + y;
  }, f, f2);
  print("before zip");
  var v3 = await f3.future;
  print("v3 $v3");
}
/*
Future<int> test_perf1(int n, [bool piping = true]) async {
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
  print("send");
  for (int i = 1; i <= N; i++) {
    var v = await command.send_object(["INCR", "test"]);
    if (i != v) {
      throw ("wrong received value, we got $v");
    }
  }
  var v = await command.send_object(["GET", "test"]);
  print("got");
  if (N.toString() != v.toString()) {
    throw ("wrong received value, we got $v  instead of $N");
  }

  if (piping) {
    command.pipe_end();
  }
  int stop = new DateTime.now().millisecondsSinceEpoch;
  int time = stop - start;
  print("done in ${stop - start} ms");
  double perf = n / time * 1000;
  print("perf $perf");
  return 0;
}

Future<int> test_perf_f(int n, [bool piping = true]) async {
  int N = n;
  int rec = 0;
  int start;
  var command = await generate_connect();
  print("connected");
  start = new DateTime.now().millisecondsSinceEpoch;
  if (piping) {
    command.pipe_start();
  }
  await futuref2(command.send_object(["SET", "test", "0"]));
  print("send");
  for (int i = 1; i <= N; i++) {
    var fv = await futuref2(command.send_object(["INCR", "test"]));
    fv.map((v) {
      if (i != v) {
        throw ("wrong received value, we got $v");
      }
    });
  }
  var v = await futuref(command.send_object(["GET", "test"])).future;
  print("got");
  if (N.toString() != v.toString()) {
    throw ("wrong received value, we got $v  instead of $N");
  }

  if (piping) {
    command.pipe_end();
  }
  int stop = new DateTime.now().millisecondsSinceEpoch;
  int time = stop - start;
  print("done in ${stop - start} ms");
  double perf = n / time * 1000;
  print("perf $perf");
  return 0;
}

Future<int> test_perf_f2(int n, [bool piping = true]) async {
  int N = n;
  int rec = 0;
  int start;
  var command = await generate_connect();
  print("connected");
  start = new DateTime.now().millisecondsSinceEpoch;
  if (piping) {
    command.pipe_start();
  }
  futuref(command.send_object(["SET", "test", "0"]));
  print("send");
  for (int i = 1; i <= N; i++) {
    var fv = futuref(command.send_object(["INCR", "test"]));
    fv.map((v) {
      if (i != v) {
        throw ("wrong received value, we got $v");
      }
    });
  }
  var v = await futuref(command.send_object(["GET", "test"]))._eval();
  print("got");
  if (N.toString() != v.toString()) {
    throw ("wrong received value, we got $v  instead of $N");
  }

  if (piping) {
    command.pipe_end();
  }
  int stop = new DateTime.now().millisecondsSinceEpoch;
  int time = stop - start;
  print("done in ${stop - start} ms");
  double perf = n / time * 1000;
  print("perf $perf");
  return 0;
}
*/

Future test_perf_f3(int n, [bool piping = true]) async {
  int N = n;
  int rec = 0;
  int start;
  var command = await generate_connect();
  print("connected");
  start = new DateTime.now().millisecondsSinceEpoch;
  if (piping) {
    command.pipe_start();
  }
  futuref(command.send_object(["SET", "test", "0"]));
  print("send");
  FutureF tot = new FutureF._value(0);
  for (int i = 1; i <= N; i++) {
    FutureF fv = futuref(command.send_object(["INCR", "test"]));
    /*fv.map((v) {
      if (i != v) {
        throw ("wrong received value, we got $v");
      }
      return v;
    });*/
    //tot = fv;
    tot = zipWith2((x, y) => x + y, fv,tot);

    /*
    if(i % 1000 == 0){
      //Future f = tot.future;
      tot = FutureF._future(tot.future);
    } */
  }
  var v = await futuref(command.send_object(["GET", "test"]))._eval();
  print("got");
  if (N.toString() != v.toString()) {
    throw ("wrong received value, we got $v  instead of $N");
  }

  if (piping) {
    command.pipe_end();
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

Future<void> main() async {
  print("hai");
  // await test();
  // await test_perf1(100000,true);
  // await test_perf_f(1000000,true);
  // await test_perf_f2(1000000, true);
  await test_perf_f3(200000, true);
  exit(0);
  return;
}
