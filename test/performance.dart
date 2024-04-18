import 'dart:async';
import 'package:universal_io/io.dart';

import 'package:redis/redis.dart';

import 'main.dart';

void main() {
  print("Performance TEST and REPORT");
  testing_performance(
          test_muliconnections_con(100) as Future<dynamic> Function(int),
          "Multiple connections",
          200000)
      .then(
          (_) => testing_performance(test_pubsub_performance, "PubSub", 200000))
      .then((_) =>
          testing_performance(test_performance, "Raw Performance", 200000))
      .then((_) => test_long_running(20000))
      .then((_) => print("Finished Performance Tests"))
      .then((_) => exit(0));
}

Future<int> testing_performance(
    Future Function(int) fun, String title, int iterations) {
  int start = DateTime.now().millisecondsSinceEpoch;
  return fun(iterations).then((_) {
    int end = DateTime.now().millisecondsSinceEpoch;

    double diff = (end - start) / 1000.0;
    int perf = (iterations / diff).round();
    print(title +
        ": " +
        perf.toString() +
        " op/s\t (Iterations: " +
        iterations.toString() +
        ")");

    return perf;
  });
}

Future test_pubsub_performance(int N) {
  late Command command; //on conn1 tosend commands
  late Stream pubsubstream; //on conn2 to rec c
  return generate_connect().then((Command cmd) {
    command = cmd;
    return generate_connect();
  }).then((Command cmd) {
    PubSub pubsub = PubSub(cmd);
    pubsub.subscribe(["monkey"]);
    pubsubstream = pubsub.getStream();
    return pubsubstream;
  }).then((_) {
    //bussy wait for prevous to be subscibed
    return Future.doWhile(() {
      return command
          .send_object(["PUBSUB", "NUMSUB", "monkey"]).then((v) => v[1] == 0);
    }).then((_) {
      //at thuis point one is subscribed
      for (int i = 0; i < N; ++i) {
        command.send_object(["PUBLISH", "monkey", "banana"]);
      }
    });
  }).then((_) {
    int counter = 0;
    //var expected = ["message", "monkey", "banana"];
    late var subscription;
    Completer comp = Completer();
    subscription = pubsubstream.listen((var data) {
      counter++;
      if (counter == N) {
        subscription.cancel();
        comp.complete("OK");
      }
    });
    return comp.future;
  });
}

Future test_performance(int n, [bool piping = true]) {
  int N = n;
  //int rec = 0;
  //int start;
  return generate_connect().then((Command command) {
    //start = DateTime.now().millisecondsSinceEpoch;
    if (piping) {
      command.pipe_start();
    }
    command.send_object(["SET", "test", "0"]);
    for (int i = 1; i <= N; i++) {
      command.send_object(["INCR", "test"]).then((v) {
        if (i != v) {
          throw ("wrong received value, we got $v");
        }
      });
    }
    //last command will be executed and then processed last
    Future r = command.send_object(["GET", "test"]).then((v) {
      if (N.toString() != v.toString()) {
        throw ("wrong received value, we got $v  instead of $N");
      }
      return true;
    });
    if (piping) {
      command.pipe_end();
    }
    return r;
  });
}

Function test_muliconnections_con(int conn) {
  return (int cmd) => test_muliconnections(cmd, conn);
}

Future test_muliconnections(int commands, int connections) {
  int N = commands;
  int K = connections;
  int c = 0;

  Completer completer = Completer();
  generate_connect().then((Command command) {
    return command.set("var", "0");
  }).then((_) {
    for (int j = 0; j < K; j++) {
      RedisConnection();
      generate_connect().then((Command command) {
        command.pipe_start();
        for (int i = j; i < N; i += K) {
          command.send_object(["INCR", "var"]).then((v) {
            c++;
            if (c == N) {
              command.get("var").then((v) {
                assert(v == N.toString());
                completer.complete("ok");
              });
            }
          });
        }
        command.pipe_end();
      });
    }
  });
  return completer.future;
}

//this one employs doWhile to allow numerous
//commands wihout "memory leaking"
//next command is executed after prevous commands completes
//performance of this test depends on packet roundtrip time
Future test_long_running(int n) {
  int start = DateTime.now().millisecondsSinceEpoch;
  int update_period = 2000;
  int timeout = start + update_period;
  //const String key = "keylr";
  return generate_connect().then((Command command) {
    int N = n;
    int c = 0;
    print("  started long running test of $n commands");
    return Future.doWhile(() {
      c++;
      if (c >= N) {
        print("  done");
        int now = DateTime.now().millisecondsSinceEpoch;
        double diff = (now - start) / 1000.0;
        double perf = c / diff;
        print("  ping-pong test performance ${perf.round()} ops/s");
        return false;
      }
      if (c % 40000 == 0) {
        int now = DateTime.now().millisecondsSinceEpoch;
        if (now > timeout) {
          timeout += update_period;
          double diff = (now - start) / 1000.0;
          double perf = c / diff;
          print(
              "  ping-pong test running  ${((N - c) / perf).round()}s to complete , performance ${perf.round()} ops/s");
        }
      }
      return command.send_object(["PING"]).then((v) {
        if (v != "PONG") {
          throw "expeted $c but got $v";
        }
        return true;
      });
    });
  });
}

//this one employs doWhile to allow numerous
//commands wihout "memory leaking"
//it uses multiple connections
Future test_long_running2(int n, int k) {
  int start = DateTime.now().millisecondsSinceEpoch;
  int timeout = start + 5000;
  const String key = "keylr";
  Completer completer = Completer();
  generate_connect().then((Command command) {
    int N = n;
    int c = 0;
    print("  started long running test of $n commands and $k connections");
    command.send_object(["SET", key, "0"]).then((_) {
      for (int i = 0; i < k; i++) {
        generate_connect().then((Command command) {
          Future.doWhile(() {
            c++;
            if (c >= N) {
              if (c == N) {
                print(" done");
                completer.complete("OK");
              }
              return Future(() => false);
            }

            int now = DateTime.now().millisecondsSinceEpoch;
            if (now > timeout) {
              timeout += 5000;
              double diff = (now - start) / 1000.0;
              double perf = c / diff;
              print(
                  "  ping-pong test running  ${((N - c) / perf).round()}s to complete , performance ${perf.round()} ops/s");
            }
            return command.send_object(["INCR", key]).then((v) {
              return true;
            });
          });
        });
      }
    });
  });
  return completer.future;
}
