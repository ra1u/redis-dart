/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import '../lib/redis.dart';



test_parser(){
  List data =  new Utf8Encoder().convert("*3\r\n*1\r\n:3\r\n+Foo\r\n+Barzor\r\n ");
  var stream = new LazyStream.fromstream(new Stream.fromIterable(data));  
  
  RedisParser.parseredisresponse(stream).then((v) {
    print("$v");
  });
}
test_performance(){
  const int N = 200000;
  int start;
  RedisConnection conn = new RedisConnection();
  conn.connect('localhost',6379).then((Command command){
    print("test started, please wait ...");
    start =  new DateTime.now().millisecondsSinceEpoch;
    command.pipe_start();
    for(int i=1;i<N;i++){ 
      command.set("test $i","$i")
      .then((v){
        assert(v=="OK");
      });
    }
    //last command will be executed and then processed last
    command.set("test $N","$N").then((v){
      assert(v=="OK"); 
      double diff = (new DateTime.now().millisecondsSinceEpoch - start)/1000.0;
      double perf = N/diff;
      print("$N operations done in $diff s\nperformance $perf/s");
    });
    command.pipe_end();
  });
}

test_performance2(){
    const int N = 200000;
    int start;
    RedisConnection conn = new RedisConnection();
    conn.connect('localhost',6379).then((Command command){
      print("test started, please wait ...");
      start =  new DateTime.now().millisecondsSinceEpoch;
      command.pipe_start();
      command.send_object(["SET","test","0"]);
      for(int i=1;i<=N;i++){ 
        command.send_object(["INCR","test"])
        .then((v){
          if(i != v)
            throw("wrong received value, we got $v");
        });
      }
      //last command will be executed and then processed last
      command.send_object(["GET","test"]).then((v){
        print(v); 
        double diff = (new DateTime.now().millisecondsSinceEpoch - start)/1000.0;
        double perf = N/diff;
        print("$N operations done in $diff s\nperformance $perf/s");
      });
      command.pipe_end();
    });
}

test_muliconnections(){
  const int N = 2000000;
  const int K = 10;
  int start;
  int c=0;
  
  print("test started, please wait ...");
  start =  new DateTime.now().millisecondsSinceEpoch;
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
            }
          });
        }
        command.pipe_end();
      });
    }
  });
}


test_transactions(){
  RedisConnection conn = new RedisConnection();
  RedisConnection conn2 = new RedisConnection();
  int N=2000000;
  conn.connect('localhost',6379).then((Command command){   
    conn2.connect('localhost',6379).then((Command command2){ 
      command.multi().then((Transaction trans){
          trans.send_object(["SET","val","0"]);
          for(int i=1;i<=N;++i){
            trans.send_object(["INCR","val"]).then((v){
              assert(v==i);
            });
            command2.send_object(["INCR","val"]).then((v){
              assert(true);
            });
          }
          trans.send_object(["GET","val"]).then((v){
            print("number is now $v");
          });
          trans.exec();
          command.send_object(["GET","val"]).then((v){
            print("number2 is now $v");
          });
      });
    });
  });
}

test_commands_one_by_one(){  
    RedisConnection conn = new RedisConnection();
    conn.connect('localhost',6379).then((Command command){ 
    int N = 100000;
    //chain futures one after another
    Future future = new Future(()=>"OK");
      for(int i=0;i<N;i++){
        future = future.then((v){
          assert(v=="OK");
          return command.set("key","val $i");
        });
      }
      //process last invoke
      future.then((v){
        assert(v=="OK");
        print("done");
      });
    });
}

hi_world(){
  String s = "bućke";
  for(int i=0;i<s.length;++i){
    print(UTF8.encode(s[i]));
  }
}

test_pubsub(){
  int N = 100000;
  RedisConnection conn1 = new RedisConnection();
  RedisConnection conn2 = new RedisConnection();
  Command command; //on conn1
  PubSubCommand pubsub; //on conn2
  
  conn1.connect('localhost',6379)
  .then((Command cmd){
    command = cmd;
    return conn2.connect('localhost',6379);
  })
  .then((Command cmd){ 
    pubsub=new PubSubCommand(cmd);
    pubsub.psubscribe(["a*","b*","*"]);
    Subscription sub = pubsub.getSubscription();
    sub.add("*",(k,v){
      print("$k $v");
     });
    pubsub.unsubscribe(["a*"]);
  })
  .then((_){ 
    command.send_object(["PUBLISH","aaa","aa"]);
    command.send_object(["PUBLISH","bbb","bb"]);
    command.send_object(["PUBLISH","ccc","cc"]); 
  });
}

test_pg(){
    RedisConnection conn = new RedisConnection();
    conn.connect('localhost',6379).then((Command command){
      command.send_object(["SET","key","0"])
      .then((var response){
        assert(response == 'OK');
      });
      command.send_object(["INCR","key"])
      .then((var response){
        assert(response == 1);  
      });
      command.send_object(["INCR","key"])
      .then((var response){
        assert(response == 2);
      });
      command.send_object(["INCR","key"])
      .then((var response){
        assert(response == 3);
      });
      command.send_object(["GET","key"])
      .then((var response){
         print(response); // 3
      });
    });
}


main(){
  //test_muliconnections();
  test_transactions();
}
