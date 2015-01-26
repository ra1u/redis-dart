part of testredis;

Future test_performance(int n){
  int N = n;
  int rec=0;
  int start;
  RedisConnection conn = new RedisConnection();
  Duration zero = new Duration(seconds:0);
  return conn.connect('localhost',6379).then((Command command){
    start =  new DateTime.now().millisecondsSinceEpoch;
    //command.pipe_start();
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
      double diff = (new DateTime.now().millisecondsSinceEpoch - start)/1000.0;
      double perf = N/diff;
      print("  $N operations done in $diff s\n  performance $perf/s");
    });
    return r;
  });
}

Future test_muliconnections(int commands,int connections){
  int N = commands;
  int K = connections;
  int start;
  int c=0;
  
  start =  new DateTime.now().millisecondsSinceEpoch;
  Completer completer = new Completer();
  RedisConnection conn = new RedisConnection();
  conn.connect('localhost',6379).then((Command command){
    print("  multiple connections test started - $K connections, $N commands");
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
              print("  $N operations done in $diff s\n  performance $perf/s");
              command.get("var").then((v){
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
    print("  started long running test of $n commands"); 
      return Future.doWhile((){
        c++;
        if(c>=N){
          print("  done");
          int now = new DateTime.now().millisecondsSinceEpoch;
          double diff = (now - start)/1000.0;
          double perf = c/diff;
          print("  ping-pong test performance ${perf.round()} ops/s");
          return new Future(()=>false);
        }
        if(c%40000 == 0){
          int now = new DateTime.now().millisecondsSinceEpoch;
          if(now > timeout){
            timeout += 5000;
            double diff = (now - start)/1000.0;
            double perf = c/diff;
            print("  ping-pong test running  ${((N-c)/perf).round()}s to complete , performance ${perf.round()} ops/s");
          }
        }
        return command.send_object(["PING"])
        .then((v){
           if(v != "PONG"){
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
Future test_long_running2(int n,int k){  
  int start = new DateTime.now().millisecondsSinceEpoch;
  int timeout = start + 5000;
  const String key = "keylr";
  RedisConnection conn = new RedisConnection();
  Completer completer = new Completer();
  conn.connect('localhost',6379).then((Command command){ 
    int N = n;
    int c = 0;
    print("  started long running test of $n commands and $k connections"); 
    command.send_object(["SET",key,"0"]).then((_){
      for(int i=0;i<k;i++){
        conn.connect('localhost',6379).then((Command command){ 
          Future.doWhile((){
            c++;
            if(c>=N){
              if(c==N){
                print(" done");
                completer.complete("OK");
              }
              return new Future(()=>false);
            }
            
            int now = new DateTime.now().millisecondsSinceEpoch;
            if(now > timeout){
              timeout += 5000;
              double diff = (now - start)/1000.0;
              double perf = c/diff;
              print("  ping-pong test running  ${((N-c)/perf).round()}s to complete , performance ${perf.round()} ops/s");
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