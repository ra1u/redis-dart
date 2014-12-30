/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

import 'dart:async';
import 'dart:collection';
import '../lib/redis.dart';

Future test_performance(int n){
  int N = n;
  int rec=0;
  int start;
  RedisConnection conn = new RedisConnection();
  Duration zero = new Duration(seconds:0);
  return conn.connect('localhost',6379).then((Command command){
    start =  new DateTime.now().millisecondsSinceEpoch;
    command.pipe_start();
    command.send_object(["SET","test","0"]);
    for(int i=1;i<=N;i++){
      command.send_object(["INCR","test"])
      .then((v){
        if(i != v){
          throw("wrong received value, we got $v");
        }
      });
    }
    //last command will be executed and then processed last
    Future r = command.send_object(["GET","test"]).then((v){
      print(v); 
      double diff = (new DateTime.now().millisecondsSinceEpoch - start)/1000.0;
      double perf = N/diff;
      print("$N operations done in $diff s\nperformance $perf/s");
    });
    return r;
  });
}

Future test_muliconnections(int commands,int connections){
  int N = commands;
  int K = connections;
  int start;
  int c=0;
  
  print("multiple connections test started - $K connections, $N commands");
  start =  new DateTime.now().millisecondsSinceEpoch;
  Completer completer = new Completer();
  RedisConnection conn = new RedisConnection();
  conn.connect('localhost',6379).then((Command command){
    return command.set("var","0");
  })
  .then((_){
    for(int j=0;j<K;j++){
      RedisConnection conn = new RedisConnection();
      conn.connect('localhost',6379).then((Command command){
        command.pipe_start();
        for(int i=j;i<N;i+=K){ 
          command.send_object(["INCR","var"])
          .then((v){
            c++;
            if(c==N){
              double diff = (new DateTime.now().millisecondsSinceEpoch - start)/1000.0;
              double perf = N/diff;
              print("$N operations done in $diff s\nperformance $perf/s");
              command.get("var").then((v){print("var is $v");});
              completer.complete("ok");
            }
          });
        }
        command.pipe_end();
      });
    }
  });
  return completer.future;
}



Future test_transactions(int n){
  RedisConnection conn = new RedisConnection();
  RedisConnection conn2 = new RedisConnection();
  const String key = "key_trans" ;
  int N=n;
  print("starting transation with $N commands");
  return conn.connect('localhost',6379).then((Command command){   
    return conn2.connect('localhost',6379).then((Command command2){ 
      return command.multi().then((Transaction trans){
          trans.send_object(["SET",key,"0"]);
          command2.send_object(["SET",key,"0"]);
          for(int i=1;i<=N;++i){
            trans.send_object(["INCR",key]).then((v){
              if(v!=i){
                throw("transation value is $v instead of $i");
              }
            });
            command2.send_object(["INCR",key]).then((v){
              if(v!=i){
                throw("connection value is $v instead of $i");
              }
            });
          }
          trans.send_object(["GET",key]).then((v){
            if(v!=N.toString()){
              throw("transation get value is $v instead of $N");
            }
          });
          trans.exec();
          return command.send_object(["GET",key]).then((v){
            if(v!=N.toString()){
              throw("connection value is $v instead of $N");
            }
          });
      });
    });
  });
}

/// test that Command can not be used during transation
Future test_transactions_failing(){
  RedisConnection conn = new RedisConnection();
  const String key = "key_trans" ;
  return conn.connect('localhost',6379).then((Command command){   
    return command.multi().then((Transaction trans){
      trans.send_object(["SET",key,"0"]);
      try{
        command.send_object(["GET",key]); //this should throw
      }
      catch(e){
        return "OK";
      }
      throw "error : no error"; //I once saw this message in Windows and I liked it
    });
  });
}

/// test that Command can  be used after transation .exec
Future test_transactions_command_usable(){
  RedisConnection conn = new RedisConnection();
  const String key = "key_trans" ;
  return conn.connect('localhost',6379).then((Command command){   
    return command.multi().then((Transaction trans){
      trans.send_object(["SET",key,"0"]);
      trans.send_object(["GET",key]).then((v){
        if(v != "0") throw "expecting 0 but got $v";
      });
      trans.exec();
      command.send_object(["GET",key]).then((v){
        if(v != "0") throw "expecting 0 but got $v";
      });
      return conn.close();
    });
  });
}

Future test_commands_one_by_one(){  
  RedisConnection conn = new RedisConnection();
  const String key = "key1b1";
  return conn.connect('localhost',6379).then((Command command){ 
    //chain futures one after another
    const int N =100;
    return command.send_object(["SET",key,"0"]).then((_){
      Future future = new Future(()=>0);
      for(int i=0;i<N;i++){
        future = future.then((v){
          assert(v==i);
          return command.send_object(["INCR",key]);
        });
      }
      //process last invoke
      return future.then((v){
        assert(v==N);
      });
    });
  });
}

//this one employs doWhile to allow numerous 
//commands wihout "memory leaking" 
//next command is executed after prevous commands completes
//performance of this test depends on packet roundtrip time
Future test_long_running(int n){  
  int start = new DateTime.now().millisecondsSinceEpoch;
  int timeout = start + 5000;
  const String key = "keylr";
  RedisConnection conn = new RedisConnection();
  return conn.connect('localhost',6379).then((Command command){ 
    int N = n;
    int c = 0;
    print("started long running test of $n commands"); 
    return command.send_object(["SET",key,"0"]).then((_){
      return Future.doWhile((){
        c++;
        if(c>=N){
          print("done");
          return new Future(()=>false);
        }
        if(c%40000 == 0){
          int now = new DateTime.now().millisecondsSinceEpoch;
          if(now > timeout){
            timeout += 5000;
            double diff = (now - start)/1000.0;
            double perf = c/diff;
            print("ping-pong test running  ${((N-c)/perf).round()}s to complete , performance ${perf.round()} ops/s");
          }
        }
        return command.send_object(["INCR",key])
        .then((v){
           if(v != c){
             throw "expeted $c but got $v";
           }
           return true;
        });
      });
    });
  });
}

//this one employs doWhile to allow numerous 
//commands wihout "memory leaking" 
//it uses multiple connections
Future test_long_running2(int n,int k){  
  int start = new DateTime.now().millisecondsSinceEpoch;
  int timeout = start + 5000;
  const String key = "keylr";
  RedisConnection conn = new RedisConnection();
  Completer completer = new Completer();
  conn.connect('localhost',6379).then((Command command){ 
    int N = n;
    int c = 0;
    print("started long running test of $n commands and $k connections"); 
    command.send_object(["SET",key,"0"]).then((_){
      for(int i=0;i<k;i++){
        conn.connect('localhost',6379).then((Command command){ 
          Future.doWhile((){
            c++;
            if(c>=N){
              if(c==N){
                print("done");
                completer.complete("OK");
              }
              return new Future(()=>false);
            }
            
            int now = new DateTime.now().millisecondsSinceEpoch;
            if(now > timeout){
              timeout += 5000;
              double diff = (now - start)/1000.0;
              double perf = c/diff;
              print("ping-pong test running  ${((N-c)/perf).round()}s to complete , performance ${perf.round()} ops/s");
            }
            return command.send_object(["INCR",key])
            .then((v){
               return true;
            });
          });
        });
      }
    });
  });
  return completer.future;
}

test_pubsub(){
  RedisConnection conn1 = new RedisConnection();
  RedisConnection conn2 = new RedisConnection();
  Command command; //on conn1
  PubSubCommand pubsub; //on conn2
  
  int test1cnt=3; //expecting 3 messages
  int test2cnt=1; //expecting 1 messages
  
  var testmessages =  [["PUBLISH","aaa","aa"],
    ["PUBLISH","bbb","bb"],
    ["PUBLISH","ccc","cc"]];
  
  return conn1.connect('localhost',6379)
  .then((Command cmd){
    command = cmd;
    return conn2.connect('localhost',6379);
  })
  .then((Command cmd){ 
    pubsub=new PubSubCommand(cmd);
    pubsub.psubscribe(["a*","b*","c*"]);
    //test1
    pubsub.getStream().listen((msg){
      for(var m in testmessages){
        if(msg[2] == m[1]){
          test1cnt--;
          return;
        }
      }
      throw("did not get msg");
    });
    //test2
    pubsub.getStream("a*").listen((msg){
      for(var m in testmessages){
        if(msg[2] == m[1]){
          test2cnt--;
          return;
        }
      }
      throw("did not get msg");
     });
  })
  .then((_){ 
    for(var msg in testmessages){
      command.send_object(msg);
    }
    
    Completer comp = new Completer();
    Timer timeout = new Timer(new Duration(seconds:1),(){
      conn1.close();
      conn2.close();
      if((test1cnt == 0 ) &&( test2cnt == 0)){
        comp.complete("ok");
      }else{
        comp.completeError("didnt got exepeted number of messages");
      }
    });
    return comp.future;
  });
}


Future test_incr_cas(){
   RedisConnection conn = new RedisConnection();
   String key = "keycaswewe";
   return conn.connect("localhost", 6379)
   .then((Command cmd){
     cmd.send_object(["SETNX",key,"1"]);
     return Future.doWhile((){
       cmd.send_object(["WATCH",key]);
       return cmd.send_object(["GET",key]).then((String val){
         int i = int.parse(val);
         ++i;
         return cmd.multi()
         .then((Transaction trans){
           String val = i.toString();
           trans.send_object(["SET",key,i.toString()]);
           return trans.exec().then((var res){
             if(res != null){
                return false; //terminate doWhile
             }
             return true; //try again
           });
         });
       });
     });
   });
}


Future test_incr_cas_multiple(int n){
  Queue<Future> q =new Queue();
  for(int i=0;i<n;++i){
    q.add(test_incr_cas());
  }
  return Future.wait(q);
}



Future testing_helper(Future f,String name){
  print("start  $name");
  return f.then((_)=>print("PASSED $name"),onError: (e)=>print("ERROR $name => $e"));
}

main(){
  Queue<Future> q =new Queue();
  q.add(testing_helper(test_transactions(10000), "transation"));
  q.add(testing_helper(test_pubsub(),"pubsub"));
  q.add(testing_helper(test_commands_one_by_one(),"one by one"));
  q.add(testing_helper(test_incr_cas(),"transation CAS"));
  q.add(testing_helper(test_incr_cas_multiple(10),"transation CAS multiple"));
  q.add(testing_helper(test_transactions_failing(),"transation error handling"));  
  q.add(testing_helper(test_transactions_command_usable(),"transaction release connection"));
  
  Future.wait(q).then((_){print("done");})
  .then((_){
    return testing_helper(test_muliconnections(200000,100),"testing performance multiple connections");
  })
  .then((_){
    //return testing_helper(test_long_running(2000000),"one by one for longer time");
  })
  .then((_){
    return testing_helper(test_performance(200000),"raw performance");
  });

}
