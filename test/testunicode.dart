part of testredis;


Future test_unicode(){
  RedisConnection conn = new RedisConnection();
  var teststr =  "中华人民共和国";
  return conn.connect('localhost',6379).then((Command command){
    return command.send_object(["SET","test",teststr])
      .then( (resp){
         assert(resp == "OK");
         return command.send_object(["GET","test"])
         .then((v){
           if(teststr != v){
             throw("wrong value, expected $teststr got $v" );
           }
        });
    });
  });
}