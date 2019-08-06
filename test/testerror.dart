part of testredis;

Future testError() {

  RedisConnection conn = new RedisConnection();
  return conn.connect('localhost',6379).then((Command command)  {
      command.send_object("GARBAGE").then((val) {
        throw "Expected thrown Error, not value";
      })
      .catchError((error) {
        return true;
      });
  });

}