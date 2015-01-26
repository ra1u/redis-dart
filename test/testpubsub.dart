part of testredis;

Future test_pubsub(){
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