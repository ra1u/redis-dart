Redis client for dart
=====================

[Redis](http://redis.io/) protocol  parser and client writent in [dart language](https://www.dartlang.org)  
It is designed to be both fast and simple to use.

### Currently supported features:

* [transactions](#transactions) wrapper for executing multiple commands in atomic way
* [pubsub](#pubsub) helper with aditional internal dispatching
* [unicode](#unicode) - strings are UTF8 encoded when sending and decoded when received
* [performance](#fast) - this counts as feature too
* raw commands - this enables sending any command as raw data :)


## Simple

Redis protocol is composition of array, strings(and bulk) and integers.
For example executing command `SET key value` is no more that serializing
array of strings `["SET","key","value"]`. Commands can be executed by

    Future f = command.send_object(["SET","key","value"]);

This enables sending any command.
Before sending commands one need to open connection to redis. I will
assume that you are running redis server localy on port 6379.
In this example we will open connecton, execute command 'SET key 0'
and then print result.

    import 'package:redis/redis.dart';
    ...
    RedisConnection conn = new RedisConnection();
    conn.connect('localhost',6379).then((Command command){
        command.send_object(["SET","key","0"]).then((var response)
            print(response);
        )
    }

Due to simple implementation it is possible to execute command on different ways.
One an most straightforward way is one after another

    RedisConnection conn = new RedisConnection();
    conn.connect('localhost',6379).then((Command command){
      command.send_object(["SET","key","0"])
      .then((var response){
        assert(response == 'OK');
        return command.send_object(["INCR","key"]);
      })
      .then((var response){
        assert(response == 1);  
        return command.send_object(["INCR","key"]);
      })
      .then((var response){
        assert(response == 2);
        return command.send_object(["INCR","key"]);
      })
      .then((var response){
        assert(response == 3);
        return command.send_object(["GET","key"]);
      })
      .then((var response){
        return print(response); // 3
      });
    });


Other possibility is to execute commands one by one without waiting for previous
command to complete. We can send all commands  without need to wait for
result and we can be still sure, that response handled by `Future` will be
completed in correct order.

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

Difference is that there are 5 commands in last examples
and only one on previous example.

## Fast

Tested on laptop can execute and process 130K INCR operations per second.

This is code that yields such result

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

We are not just sending 200K commands here, but also checking result of every send command.

Using `command.pipe_start();` and  `command.pipe_end();` is nothing more
that enabling and disabling [Nagle's algorhitm](https://en.wikipedia.org/wiki/Nagle%27s_algorithm)
on socket. By default it is disabled to achieve shortest possible latency at expense
of having more TCP packets and extra overhead. Enabling Nagle's algorithm
during transactions can achieve greater data throughput and less overhead.

## [Transactions](http://redis.io/topics/transactions)

Transactions by redis protocol
are started by command MULTI and then completed with command EXEC.
`.multi()`, `.exec()` and `class Transaction` are implemented as
additional helpers for checking result of each command executed during transaction.

    Future<Transaction> Command.multi();

Executing `multi()` will return Future with `Transaction`. This class should be used
to execute commands by calling `.send_object`. It returns Future that
is called after calling `.exec()`.

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

It is not possible to write code that depends on result of previous command 
during transaction. In such cases user should employ technique CAS as described 
http://redis.io/topics/transactions#cas
Here is example of INCR command witout using INCR method as explain in prevous link

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


## Unicode

By default UTF8 encoding/decoding for string is used. Each string is converted in binary
array using UTF8 encoding. This makes ascii string compatible in both direction.


## [PubSub](http://redis.io/topics/pubsub)

PubSub is helper for dispatching received messages.
First, create new `PubSubCommand` from existing `Command`

    PubSubCommand pubsub=new PubSubCommand(command);

Once `PubSubCommand` is created, old `Command` is invalidated and should not be used
on same connection. `PubSubCommand` allows commands

    void subscribe(List<String> channels)
    void psubscribe(List<String> channels)
    void unsubscribe(List<String> channels)
    void punsubscribe(List<String> channels)

and additional `Stream getStream([String pattern = "*"])`

`getStream` returns `Stream` that sends streams according to optionally provided pattern
Unlike Redis rich pattern matching, this pattern allows only for optional `*` wildchar
at the end of string.

Example for receiving and printing all messages

    pubsub.getStream().listen((message){
      print("message: $message");
    });

 Here is complete example from test code.

    import 'package:redis/redis.dart';

    main(){
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
        pubsub.getStream().listen((msg){
          print("Message for \"*\"  - msg: $msg");
         });

        pubsub.getStream("a*").listen((msg){
          print("Message for \"a*\" - msg: $msg");
        });
      })
      .then((_){
        command.send_object(["PUBLISH","aaa","aa"]);
        command.send_object(["PUBLISH","bbb","bb"]);
        command.send_object(["PUBLISH","ccc","cc"]);
      });
    }

Output is

    Message for "*"  - msg: [pmessage, a*, aaa, aa]
    Message for "a*" - msg: [pmessage, a*, aaa, aa]
    Message for "*"  - msg: [pmessage, *, aaa, aa]
    Message for "a*" - msg: [pmessage, *, aaa, aa]
    Message for "*"  - msg: [pmessage, b*, bbb, bb]
    Message for "*"  - msg: [pmessage, *, bbb, bb]
    Message for "*"  - msg: [pmessage, *, ccc, cc]

## Todo
In near future:

- Better documentation
- Implement all "generic commands" with named
 commands
- Better error handling - that is ability to recover from error
- Spell check code

## Changes

### 0.4.1
- Command  raise error if used during transaction.

### 0.4.0
- PubSub interface is made simpler but backward incompatible :(
- README is updated
