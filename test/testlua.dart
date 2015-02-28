part of testredis;

Future testluanative(){
  RedisConnection conn = new RedisConnection();
  return conn.connect('localhost',6379).then((Command command){ 
    command.send_object(["EVAL","return {KEYS[1],{KEYS[2],{ARGV[1]},ARGV[2]},2}","2","key1","key2","first",2])
    .then((response){
      print(response);
    });
  });
}