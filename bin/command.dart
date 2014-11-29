/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */


part of redis;

class Command {
  RedisConnection _connection;

  Command(this._connection){}
  
  Future _send(Object ls) => _connection.sendraw(RedisSerialise.Serialise(ls));
  
  //proxy send
  Future send_object(Object v) => _send(v);
  
  void pipe_start() => _connection.disable_nagle(false); //we want to use sockets buffering
  void pipe_end() =>   _connection.disable_nagle(true);
  
  //commands in future, we will add more commands
  Future set(String key, String value) => _send(["SET",key,value]);
  Future get(String key) => _send(["GET",key]);
  
  //transations
  Future multi(){ //multi retun transation as future
    return _send(["MULTI"]).then((_) => new Transaction(_connection));
  }
  
  //pubsub
  Subscription subscribe(List<String> psub){
    Subscription sub = new Subscription();
    sub._connection = _connection;
    List cmd = ["PSUBSCRIBE"];
    cmd.addAll(psub);
    _send(cmd).then((v){
      sub._conn_handler_fist();
    });
    return sub;
  }
}
  