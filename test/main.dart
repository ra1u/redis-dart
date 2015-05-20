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
import '../lib/redis.dart';

part 'testcas.dart';
part 'testtransaction.dart';
part 'testperformance.dart';
part 'testpubsub.dart';
part 'testlua.dart';




Future testing_helper(Future f,String name){
  print("start  $name");
  return f.then((_)=>print("PASSED $name"),onError: (e)=>print("ERROR $name => $e"));
}

main(){
  Queue<Future> q =new Queue();
  q.add(testing_helper(test_transactions(10000), "transaction"));
  q.add(testing_helper(test_incr_fakecas(),"transaction FAKECAS"));
  q.add(testing_helper(test_incr_fakecas_multiple(10),"transation FAKECAS multiple"));
  q.add(testing_helper(test_transactions_failing(),"transation error handling")); 
  q.add(testing_helper(test_transactions_command_usable(),"transaction release connection"));
  q.add(testing_helper(test_pubsub(),"pubsub"));
  q.add(testing_helper(test_pubsub2(),"pubsub2"));
  q.add(testing_helper(test_commands_one_by_one(),"one by one")); 
  q.add(testing_helper(testincrcasmultiple(),"CAS"));
  q.add(testing_helper(testluanative(),"eval"));

  Future.wait(q)
  .then((_){
    return testing_helper(test_muliconnections(200000,100),"testing performance multiple connections");
  })
  .then((_)=>testing_helper(test_pubsub_performance(50000),"pubsub performance"))
  .then((_){
    //just increase this number if you have more time (I did, but I lost paitence)
    return testing_helper(test_long_running(20000),"one by one for longer time");
  })
  .then((_){
    return testing_helper(test_performance(200000),"raw performance");
  });
}

