part of redis;

//command  changer
//for example
//.get(arg) changes to
//to connnection.send(["GET",arg]);
//this way we automaticaly support all commands in dumb way.

class CommandGeneric{
  RedisConnection _connection;
  CommandGeneric(this._connection){}
  Future noSuchMethod(Invocation invocation){
    List cmd = [MirrorSystem.getName(invocation.memberName)];
    cmd.addAll(invocation.positionalArguments);
    return _connection.send(cmd);
  }
}


class Command{
  Function _callaback;
  Command(this._callaback){}
  Future _cls(List<String> ls) => _callaback(RedisSerialise.Serialise(ls));
  
  Future set(String key, String value) => _cls(["SET",key,value]);
  Future get(String key, String value) => _cls(["GET",key,value]);

}
  