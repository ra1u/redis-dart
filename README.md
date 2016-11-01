Redis client for dart
=====================

[![Join the chat at https://gitter.im/ra1u/redis-dart](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ra1u/redis-dart?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[Redis](http://redis.io/) protocol  parser and client writent in [dart language](https://www.dartlang.org)  
It is fast and simple by design. It requres no external package to run.

### Supported features:

* [transactions](#transactions) and  [CAS](#cas) (check-and-set) pattern
* [pubsub](#pubsub) 
* [unicode](#unicode)
* [performance](#fast) and [simplicity](#Simple)


## Simple

Redis client is simple serialiser and desierialiser of [redis protocol](http://redis.io/topics/protocol).
There are also some addictional helping functon and classes available to make
using redis features easier.

Redis protocol is composition of array, strings(and bulk) and integers.
For example executing command [SET](http://redis.io/commands/set) is no more that serializing
array of strings `["SET","key","value"]`. Commands can be executed by

    Future f = command.send_object(["SET","key","value"]);

This enables sending any command.
Before sending commands one need to open connection to redis. I will
assume that you are running redis server locally on port 6379.
In this example we will open connection, execute command 'SET key 0'
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

### Generic

Redis responses and request can be arbitrarly nested. 
Mapping

| Redis         | Dart          |
| ------------- |:-------------:| 
| String        | String        | 
| Integer       | Integer       |  
| Array         | List          |   
| Error         | RedisError    |  

\* Both simple string and bulk string from redis are serialied to dart string.
String from dart to redis is converted to bulk string. UTF8 encoding is used
in both directions.

Lists can be nested. This is usefull when executing [EVAL](http://redis.io/commands/EVAL) command

    command.send_object(["EVAL","return {KEYS[1],{KEYS[2],{ARGV[1]},ARGV[2]},2}","2","key1","key2","first","second"])
    .then((response){
      print(response);
    });
    
result in

    [key1, [key2, [first], second], 2]


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
    
### [CAS](http://redis.io/topics/transactions#cas)

It is impossible to write code that depends on result of previous command 
during transaction, because all commands are executed at once.
To overcome this case, user should employ technique
[CAS](http://redis.io/topics/transactions#cas). `Cas` is convenience class for simplifying this pattern.

`Cas` constructor requires `Command` as argument.  

Cas implements two methods `watch()` and  `multiAndExec()`.  
`watch` takes two arguments. First argument is list of keys to watch and
second argument is handler to call and to proceed with CAS.

for example:

    cas.watch(["key1,key2,key3"],(){
      //body of CAS
    });`

Failure happens if watched key is modified out of transaction. When this happens
 handler is called until final transaction completes.
 `multiAndExec` is used to complete transation. Method takes handler
 where argument is `Transaction`. 
 
For example:
 
    //last part in body of CAS
    cas.multiAndExec((Transaction trans){
      trans.send_object(["SET","key1",v1]);
      trans.send_object(["SET","key2",v2]);
      trans.send_object(["SET","key2",v2]);
    });

imagine we have the need to atomically increment the value of a key by 1 
(let's suppose Redis doesn't have [INCR](http://redis.io/commands/incr)).

    Cas cas = new Cas(command);
    cas.watch(["key"], (){
      command.send_object(["GET","key"]).then((String val){
        int i = int.parse(val);
        i++;
        cas.multiAndExec((Transaction trans){
          trans.send_object(["SET","key",i.toString()]);
        });
      });
    });

## Unicode

By default UTF8 encoding/decoding for string is used. Each string is converted in binary
array using UTF8 encoding. This makes ascii string compatible in both direction.


## [PubSub](http://redis.io/topics/pubsub)

PubSub is helper for dispatching received messages.
First, create new `PubSub` from existing `Command`

    PubSub pubsub=new PubSub(command);

Once `PubSub` is created, `Command` is invalidated and should not be used
on same connection. `PubSub` allows commands

    void subscribe(List<String> channels)
    void psubscribe(List<String> channels)
    void unsubscribe(List<String> channels)
    void punsubscribe(List<String> channels)

and additional `Stream getStream()`

`getStream` returns [`Stream`](https://api.dartlang.org/stable/dart-async/Stream-class.html)

Example for receiving and printing messages

    pubsub.getStream().listen((message){
      print("message: $message");
    });

Sending messages can be done from different connection for example

    command.send_object(["PUBLISH","monkey","banana"]);



## Todo
In near future:

- Better documentation
- Implement all "generic commands" with named
 commands
- Better error handling - that is ability to recover from error
- Spell check code

## Changes

### 0.4.5
- unicode bugfix -> https://github.com/ra1u/redis-dart/issues/4
- update PubSub doc
- improve tests

### 0.4.4
- bugfix for subscribe -> https://github.com/ra1u/redis-dart/issues/3
- performance improvement
- add PubSub class (simpler/shorter/faster?  PubSubCommand)
- doc update and example of EVAL

### 0.4.3
- Cas helper
- improved unit tests

### 0.4.2
- Improved performance by 10%
- Pubsub interface uses Stream
- Better test coverage
- Improved documentation

### 0.4.1
- Command  raise error if used during transaction.

### 0.4.0
- PubSub interface is made simpler but backward incompatible :(
- README is updated
