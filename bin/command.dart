part of redis;

class Command {
  RedisConnection _connection;

  Command(this._connection){}
  
  Future _send(Object ls) => _connection.sendraw(RedisSerialise.Serialise(ls));
  
  //proxy send
  Future send_object(Object v) => _send(v);
  
  void pipe_start() => _connection.disable_nagle(false); //we want to use sockets buffering
  void pipe_end() =>   _connection.disable_nagle(true);
  
  //commands
  Future set(String key, String value) => _send(["SET",key,value]);
  Future get(String key) => _send(["GET",key]);
  
  Future multi(){ //multi retun transation as future
    return _send(["MULTI"]).then((_) => new Transation(_connection));
  }
  
  //other commands are generated using  
  //noSuchMethod invocation
  
  Future noSuchMethod(Invocation invocation){
    List cmd = [MirrorSystem.getName(invocation.memberName)];
    cmd.addAll(invocation.positionalArguments);
    return _send(cmd);
  }
  
}
  