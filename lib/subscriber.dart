
part of redis;

//it used to delete subscription
//has no constructor.
class SubHandle{
  var _handle;
}

class Subscription{
  Trie _trie;
  RedisConnection _connection;
  Subscription(){
    _trie = new Trie();
  }
  
  SubHandle add(String pattern,Function cb){
    var r = _trie.add(pattern,cb);
    SubHandle s = new SubHandle();
    s._handle = r;
    return s;
  }
  
  void remove(SubHandle handle){
    _trie.remove(handle._handle);
  }
  
  void _conn_handler_fist(){
    _connection.senddummy().then(this._conn_handler);
  }
  
  void _conn_handler(var data){
    _connection.senddummy().then(_conn_handler);
    if((data.length == 4 ) && (data[0]=="pmessage")){
      _trie.send(data[2], data[3]);
    }
  }
}


