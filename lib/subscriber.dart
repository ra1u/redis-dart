
part of redis;

//it used to delete subscription
//has no constructor.
class SubHandle{
  var _handle;
}

class Subscription{
  Trie _trie = new Trie();
  
  SubHandle add(String pattern,Function cb){
    var r = _trie.add(pattern,cb);
    SubHandle s = new SubHandle();
    s._handle = r;
    return s;
  }
  
  void remove(SubHandle handle){
    _trie.remove(handle._handle);
  }
}

class PubSubCommand{
  Command _command;
  _SubscriptionDispatcher _sub;
  
  PubSubCommand(Command command){
    _command=new  Command(command._connection);
    _sub = new _SubscriptionDispatcher(command._connection);
    //processing ping makes sure that there is no 
    //more data on socket to process
    command.send_object(["PING"]).then((_){
      _sub.KickListening();
      command._connection = null; 
    });
  }
  
  Subscription subscribe(List<String> s){
    return _sub.subscribe(s);
  }
  
  Subscription psubscribe(List<String> s){
    return _sub.psubscribe(s);
  }
  
  void unsubscribe(List<String> s){
    List cmd = ["UNSUBSCRIBE"];
    cmd.add(s);
    _sub.sendobject(cmd);
  }

  void punsubscribe(List<String> s){
    List cmd = ["PUNSUBSCRIBE"];
    cmd.addAll(s);
    _sub.sendobject(cmd);
  }
  
} 

class _SubscriptionDispatcher{
  Subscription _sub = new Subscription();
  Subscription _psub = new Subscription();
  RedisConnection _connection;
  
  _SubscriptionDispatcher(this._connection){}
  
  void _conn_handler(var data){
    _connection.senddummy().then(_conn_handler);
    int len= data.length;
    switch(data[0]){
      case "message":
        _sub._trie.send(data[1],data[2]);
        break;
      case "pmessage":
        _psub._trie.send(data[2],data[3]);
        break;
    }
  }
  
  void KickListening(){
    _connection.senddummy().then(this._conn_handler);
  }
  
  Subscription subscribe(List s){
    List cmd = ["SUBSCRIBE"];
    cmd.addAll(s);
    _connection._socket.add(RedisSerialise.Serialise(cmd));
    return _sub;
  }
  
  Subscription psubscribe(List s){
    List cmd = ["PSUBSCRIBE"];
    cmd.addAll(s);
    sendobject(cmd);
    return _psub;
  }
  
  void sendobject(Object cmd){
    _connection._socket.add(RedisSerialise.Serialise(cmd));
  }
}



