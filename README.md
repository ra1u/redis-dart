redis-dart
============

[Redis](http://redis.io/) protocol  parser and client
It is designed to be fast and simple to use.
Currently it supports

### Curretly supported features:
* raw commands
* unicode
* [transactions](http://redis.io/topics/transactions)


## fast
It can perform  110K SET or GET operations per second.
This is code that yields such result and can give you first impression

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

## Simple

Redis protocol is coposition of array, strings(and bulk) and integers.
For example executing command `SET key value` is no more that serializing
array of strings ["SET","key","value"]. Cammands can be executed by

    Future f = command.send_object(["SET","key","value"]);

This enables sending any command you need.

## More examples

### Transactions

Transactions are started by command MULTI and then complited with command EXEC.
`.multi()` and `.exec()` and `class Transaction` are implemeted as
additional helpers for checking result of each command executed during transation.

    RedisConnection conn = new RedisConnection();
    conn.connect('localhost',6379).then((Command command){    
      command.multi().then((Transation trans){
          trans.send_object(["SET","val","0"]); 
          for(int i=0;i<100000;++i){
            trans.send_object(["INCR","val"]).then((v){
              assert(i==v);
            });
          }
          trans.send_object(["GET","test"]).then((v){
            print("number is now $v");
          });
          trans.exec();
      });
    });

Take note here, that Future returned by `trans.send_object()` is executed after 
`.exec()` so make sure you dont try to call `.exec()` inside of such Future, becuase
command will never complete. 
