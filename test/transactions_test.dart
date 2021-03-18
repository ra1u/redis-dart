import 'dart:async';
import 'dart:cli';
import 'dart:collection';

import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

void main() {
  test("Basic Transaction Test", () {
    Command cmd1 = waitFor(generate_connect());
    Command cmd2 = waitFor(generate_connect());

    const String key = "transaction_key";
    int n = 2;

    // Start Transaction
    Transaction trans = waitFor(cmd1.multi());
    trans.send_object(["SET", key, "0"]);

    cmd2.send_object(["SET", key, "10"]);

    
    for (int i = 1; i <= n; ++i) {
      trans.send_object(["INCR", key]).then((v) {
        expect(v == i, true,
            reason:
            "Transaction value should not be interfered by actions outside of transaction");
      })
      .catchError((e) {
          print("got test error $e");
          expect(e,TypeMatcher<TransactionError>());
      });
      
      // Increase value out of transaction
      cmd2.send_object(["INCR", key]);
    }
    
    expect(trans.send_object(["GET", key]), completion(equals(n.toString())),
        reason: "Transaction value should be final value $n");

    //Test using command fail during transaction
    expect(() => cmd1.send_object(['SET', key, 0])
      , throwsA(TypeMatcher<RedisRuntimeError>()),
        reason: "Command should not be usable during transaction");

    expect(trans.exec(), completion(equals("OK")),
        reason: "Transaction should be executed.");

    expect(cmd1.send_object(["GET", key]), completion(equals(n.toString())),
      reason: "Value should be final value $n after transaction complete");
    
    
    expect(() => trans.send_object(["GET", key]),
       throwsA(TypeMatcher<RedisRuntimeError>()),
        reason:
        "Transaction object should not be usable after finishing transaction");
  });

  
  group("Fake CAS", () {
    test("Transaction Fake CAS", () {
      expect(() => test_incr_fakecas(), returnsNormally);
    });
    
    test("Transaction Fake CAS Multiple", () {
      expect(() => test_incr_fakecas_multiple(10), returnsNormally);
    });
    
  });
 
  
}

//this doesnt use Cas class, but does same functionality
Future test_incr_fakecas() {
  RedisConnection conn = new RedisConnection();
  String key = "keycaswewe";
  return generate_connect().then((Command cmd) {
    cmd.send_object(["SETNX", key, "1"]);
    return Future.doWhile(() {
      cmd.send_object(["WATCH", key]);
      return cmd.send_object(["GET", key]).then((val) {
        int i = int.parse(val);
        ++i;
        return cmd.multi().then((Transaction trans) {
          trans.send_object(["SET", key, i.toString()]);
          return trans.exec().then((var res) {
            return false; //terminate doWhile
        	}).catchError((e){
            return true; // try again
          });
        });
      });
    });
  });
}

Future test_incr_fakecas_multiple(int n) {
  Queue<Future> q = new Queue();
  for (int i = 0; i < n; ++i) {
    q.add(test_incr_fakecas());
  }
  return Future.wait(q);
}
