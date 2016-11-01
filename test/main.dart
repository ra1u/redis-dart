/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

library testredis;
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import '../lib/redis.dart';

part 'testcas.dart';
part 'testtransaction.dart';
part 'testperformance.dart';
part 'testpubsub.dart';
part 'testlua.dart';
part 'testunicode.dart';


Future testing_performance(Function fun,String name, int rep){
   Future r = new Future((){
       print("  starting performance test $name with $rep");
       int start = new DateTime.now().millisecondsSinceEpoch;
       return fun(rep).then((_){
         int now = new DateTime.now().millisecondsSinceEpoch;
         double diff = (now - start)/1000.0;
         double perf = rep/diff;
         print("  $name performance test complete , performance ${perf.round()} ops/s");
       });
   });
   return testing_helper(r,name);
}

Future testing_helper(Future f,String name){
  print("start  $name");
  return f.then((_)=>print("PASSED $name"),onError: (e){print("ERROR $name => $e"); throw(e);});
}

main(){
  Queue<Future> q =new Queue();
  q.add(testing_helper(test_transactions(10000), "transaction"));
  q.add(testing_helper(test_incr_fakecas(),"transaction FAKECAS"));
  q.add(testing_helper(test_incr_fakecas_multiple(10),"transation FAKECAS multiple"));
  q.add(testing_helper(test_unicode(), "unicode"));
  q.add(testing_helper(test_transactions_failing(),"transation error handling")); 
  q.add(testing_helper(test_transactions_command_usable(),"transaction release connection"));
  q.add(testing_helper(test_pubsub(),"pubsub"));
  q.add(testing_helper(test_pubsubDeprecated(),"pubsubDeprected"));
  q.add(testing_helper(test_commands_one_by_one(),"one by one")); 
  q.add(testing_helper(testincrcasmultiple(),"CAS"));
  q.add(testing_helper(testluanative(),"eval"));

  Future.wait(q)
  .then((_){
    return testing_performance(test_muliconnections_con(100),"100 connections",200000);
  })
  .then((_)=>testing_performance(test_pubsub_performance,"pubsub performance",20000))
  .then((_){
    //just increase this number if you have more time (I did, but I lost paitence)
    return testing_helper(test_long_running(20000),"one by one for longer time");
  })
  .then((_){
    return testing_performance(test_performance,"raw performance",200000);
  })
  .then((_){
    print("all tests PASSED!");
    exit(0);
  })
  .catchError((e){
    print("some of tests FAILED! $e");
    exit(-1);
  });
}

