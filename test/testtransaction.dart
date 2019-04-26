part of testredis;


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
          command2.send_object(["SET",key,"10"]); //out of transaction set
          for(int i=1;i<=N;++i){
            trans.send_object(["INCR",key]).then((v){
              if(v!=i){
                throw("transation value is $v instead of $i");
              }
            });
            //here we INCR value out of transaction
            command2.send_object(["INCR",key]);
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

//this doesnt use Cas class, but does same functionality
Future test_incr_fakecas(){
   RedisConnection conn = new RedisConnection();
   String key = "keycaswewe";
   return conn.connect("localhost", 6379)
   .then((Command cmd){
     cmd.send_object(["SETNX",key,"1"]);
     return Future.doWhile((){
       cmd.send_object(["WATCH",key]);
       return cmd.send_object(["GET",key]).then((val){
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

Future test_incr_fakecas_multiple(int n){
  Queue<Future> q =new Queue();
  for(int i=0;i<n;++i){
    q.add(test_incr_fakecas());
  }
  return Future.wait(q);
}
