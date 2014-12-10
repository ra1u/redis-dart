/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */


part of redis;

class RedisConnection{
  Socket _socket = null;
  LazyStream _stream = null;
  Future _future = new Future.value();
  
  Future connect(host, port){
    return Socket.connect(host, port)
    .then((Socket sock){
      _socket = sock;
      disable_nagle(true);
      _stream =new LazyStreamFast.fromstream(_socket);
      return new Command(this);
    });
  }
  
  Future close(){
    return _socket.close();
  }

  //this doesnt send anything
  //it just wait something to come from socket
  //it parse it and execute future
  Future senddummy(){
    Completer completer = new Completer.sync();
    _future = _future.then((_) =>
        RedisParser.parseredisresponse(_stream)
        .then((v) => completer.complete(v))
    );
    return completer.future;
  }
  
  Future sendraw(List data){
    _socket.add(data);
    return senddummy();
  }
  
  Future send(object){
    var s = RedisSerialise.Serialise(object);
    return sendraw(s);
  }
  
  void disable_nagle(bool v){
    _socket.setOption(SocketOption.TCP_NODELAY,v);
  }

}