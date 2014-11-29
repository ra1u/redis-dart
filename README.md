redis-dart
============

[Redis](http://redis.io/) protocol  parser and client
It is designed to be fast and simple to use.

### Currently supported features:

* raw commands - this enables sending any command as raw data 
* Unicode - strings are UTF8 encoded when sending and decoded when received 
* [transactions](http://redis.io/topics/transactions) for executing multiple commands in atomic way
* [pubsub](http://redis.io/topics/pubsub) helper for dispatching messages trough single connection 
* performance - this counts as future too

## Simple

Redis protocol is composition of array, strings(and bulk) and integers.
For example executing command `SET key value` is no more that serializing
array of strings `["SET","key","value"]`. Commands can be executed by

    Future f = command.send_object(["SET","key","value"]);

This enables sending any command.

## Fast

It can made  110K SET or GET operations per second - 
tested locally on my laptop with i5 processor and [debian](https://www.debian.org/) OS,
This is code that yields such result and can give you first impression

    import 'package:redis/redis.dart';
    main(){
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


## Transactions

Transactions are started by command MULTI and then completed with command EXEC.
`.multi()` and `.exec()` and `class Transaction` are implemented as
additional helpers for checking result of each command executed during transaction.

    import 'package:redis/redis.dart';
    ...
    
    RedisConnection conn = new RedisConnection();
    conn.connect('localhost',6379).then((Command command){    
      command.multi().then((Transaction trans){
          trans.send_object(["SET","val","0"]);
          for(int i=0;i<200000;++i){
            trans.send_object(["INCR","val"]).then((v){
              assert(i==v);
            });
          }
          trans.send_object(["GET","val"]).then((v){
            print("number is now $v");
          });
          trans.exec();
      });
    });

Take note here, that Future returned by `trans.send_object()` is executed after 
`.exec()` so make sure you dont try to call `.exec()` inside of such Future, beacause
command will never complete. 



## Unicode

By default UTF8 encoding/decoding for string is used. Each string is coverted in binary 
array using UTF8 encoding. This makes ascii string compatible in both direction.


## PubSub

There is little helper that enables dispatching recevied messages. 

[PSUBSCRIBE](http://redis.io/commands/PSUBSCRIBE) on messages `a*` and `b*`
      Subscription sub = command.psubscribe(["a*","b*"]);
      
`Subscription` allows registering trough `.add(String pattern,Function callback)`
Unlike Redis rich pattern matching, this pattern allows only for optional `*` wildchar
at the end of string. 

      sub.add("abra*",(String chan,String message){
         print("on channel: $chan message: $message");
      });
      
 Here is full example from test code.
 
    import 'package:redis/redis.dart';
    main(){
      RedisConnection conn1 = new RedisConnection();
      RedisConnection conn2 = new RedisConnection();
      Command cmd1;
      Command cmd2;
      Subscription sub;
      conn1.connect('localhost',6379)
      .then((Command cmd){
        cmd1 = cmd;
        return conn2.connect('localhost',6379);
      })
      .then((Command cmd){ 
        cmd2=cmd;
        sub = cmd2.psubscribe(["a*","b*"]);
        sub.add("*",(k,v){
          print("$k $v");
         });
      })
      .then((_){ 
        cmd1.send_object(["PUBLISH","aaa","aa"]);
        cmd1.send_object(["PUBLISH","bbb","bb"]);
        cmd1.send_object(["PUBLISH","ccc","cc"]); //we are not subscibed on this
      });
    }
    
## Todo 
In near future
  - Better documentation
  - Implement all "generic commands" with named commands
  - Better error handling - that is ability to recover from error
  - Install spell checker
  
