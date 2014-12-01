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
  
  Subscription getSubscription(){
   return _sub._sub; //haha
  }
  
  void subscribe(List<String> s){
    sendcmd_and_list("PSUBSCRIBE",s);
  }
  
  void  psubscribe(List<String> s){
    sendcmd_and_list("PSUBSCRIBE",s);
  }
  
  void unsubscribe(List<String> s){
    sendcmd_and_list("UNSUBSCRIBE",s);
  }

  void punsubscribe(List<String> s){
    sendcmd_and_list("PUNSUBSCRIBE",s);
  }
  
  void sendcmd_and_list(String cmd,List<String> s){
    List list = [cmd];
    list.addAll(s);
    _sub.sendobject(list);
  }
  
} 

class _SubscriptionDispatcher{
  Subscription _sub = new Subscription();
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
        _sub._trie.send(data[2],data[3]);
        break;
    }
  }
  
  void KickListening(){
    _connection.senddummy().then(this._conn_handler);
  }
  
  void sendobject(Object cmd){
    _connection._socket.add(RedisSerialise.Serialise(cmd));
  }
}



