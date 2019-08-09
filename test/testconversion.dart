part of testredis;

Future testConversion() {

  RedisConnection conn = new RedisConnection();
  return conn.connect('localhost',6379).then((Command command)  {
      command.send_object(["SADD", "test_list", 1]).then((val) {
        if(val is RedisError) {
          throw "Expected redis-dart to convert integers to bulk strings when contained in array.";
        }
        return true;
      })
      .catchError((error) {
        throw "Expected redis-dart to convert integers to bulk strings when contained in array.";
      });
  });

}