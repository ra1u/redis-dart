part of testredis;

Future test_pubsub() {
  RedisConnection conn1 = new RedisConnection();
  RedisConnection conn2 = new RedisConnection();
  Command command; //on conn1
  PubSubCommand pubsub; //on conn2

  int test1cnt = 3; //expecting 3 messages
  int test2cnt = 1; //expecting 1 messages

  var testmessages = [["PUBLISH", "aaa", "aa"], 
                      ["PUBLISH", "bbb", "bb"], 
                      ["PUBLISH", "ccc", "cc"]];

  return conn1.connect('localhost', 6379).then((Command cmd) {
    command = cmd;
    return conn2.connect('localhost', 6379);
  }).then((Command cmd) {
    pubsub = new PubSubCommand(cmd);
    pubsub.psubscribe(["a*", "b*", "c*"]);
    //test1
    pubsub.getStream().listen((msg) {
      for (var m in testmessages) {
        if (msg[2] == m[1]) {
          test1cnt--;
          return;
        }
      }
      throw ("did not get msg");
    });
    //test2
    pubsub.getStream("a*").listen((msg) {
      for (var m in testmessages) {
        if (msg[2] == m[1]) {
          test2cnt--;
          return;
        }
      }
      throw ("did not get msg");
    });
  }).then((_) {
    for (var msg in testmessages) {
      command.send_object(msg);
    }

    Completer comp = new Completer();
    Timer timeout = new Timer(new Duration(seconds: 1), () {
      conn1.close();
      conn2.close();
      if ((test1cnt == 0) && (test2cnt == 0)) {
        comp.complete("ok");
      } else {
        comp.completeError("didnt got exepeted number of messages");
      }
    });
    return comp.future;
  });
}

// helper function to check
// if Stream data is same as provided test Iterable
Future _test_rec_msg(Stream s, List l) {
  var it = l.iterator;
  return s
      .take(l.length)
      .every((v) => it.moveNext() && (it.current.toString() == v.toString()));
}

Future test_pubsub2() {
  Command command; //on conn1 tosend commands
  Stream pubsubstream; //on conn2 to rec c

  RedisConnection conn = new RedisConnection();
  return conn.connect('localhost', 6379).then((Command cmd) {
    command = cmd;
    RedisConnection conn = new RedisConnection();
    return conn.connect('localhost', 6379);
  }).then((Command cmd) {
    PubSubCommand pubsub = new PubSubCommand(cmd);
    pubsub.subscribe(["monkey"]);
    pubsubstream = pubsub.getStream();
    return pubsubstream; //TODO fix logic correct, no just working
  }).then((_) {
    //bussy wait for prevous to be subscibed
    return Future.doWhile(() {
      return command.send_object(["PUBSUB", "NUMSUB", "monkey"])
          .then((v) => v[1] == 0);
    }).then((_) {
      //at thuis point one is subscribed
      return command.send_object(["PUBLISH", "monkey", "banana"])
          .then((_) => command.send_object(["PUBLISH", "monkey", "peanut"]))
          .then((_) => command.send_object(["PUBLISH", "lion", "zebra"]));
    });
  }).then((_) {
    var expect = [["message", "monkey", "banana"],["message", "monkey", "peanut"]];
    return  _test_rec_msg(pubsubstream,expect)
    .then((bool r){
       if(r != true)
         throw "errror test_pubsub2";
    });

  });
}

Future test_pubsub_performance(int N) {
  Command command; //on conn1 tosend commands
  Stream pubsubstream; //on conn2 to rec c
  int start;
  RedisConnection conn = new RedisConnection();
  return conn.connect('localhost', 6379).then((Command cmd) {
    command = cmd;
    RedisConnection conn = new RedisConnection();
    return conn.connect('localhost', 6379);
  }).then((Command cmd) {
    PubSubCommand pubsub = new PubSubCommand(cmd);
    pubsub.subscribe(["monkey"]);
    pubsubstream = pubsub.getStream();
    return pubsubstream;
  }).then((_) {
    //bussy wait for prevous to be subscibed
    return Future.doWhile(() {
      return command.send_object(["PUBSUB", "NUMSUB", "monkey"])
          .then((v) => v[1] == 0);
    }).then((_) {
      //at thuis point one is subscribed
      start = new DateTime.now().millisecondsSinceEpoch;
      for(int i=0;i<N;++i){
        command.send_object(["PUBLISH", "monkey", "banana"]);
      }
    });
  }).then((_) {
    int counter = 0;
    var expected = ["message", "monkey", "banana"];
    var subscription;
    Completer comp = new Completer();
    subscription = pubsubstream.listen((var data){
      /*
      if(data.length != expected.length)
          throw "wrong length";
      for(int i = 0;i<expected.length;++i){
        if(data[i] != expected[i]){
          throw "wrong length";
        }
      }*/
      counter++;
      if(counter == N){
        int now = new DateTime.now().millisecondsSinceEpoch;
        double diff = (now - start)/1000.0;
        double perf = N/diff;
        print("  pubsub perf complete complete , performance ${perf.round()} ops/s");
        subscription.cancel();
        comp.complete("OK"); 
      }
    });
    return comp.future;
  });
}
