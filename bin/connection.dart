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
  
  Future sendraw(List lst){
    _socket.add(lst);
    Completer completer = new Completer.sync();
    _future = _future.then((_) =>
        RedisParser.parseredisresponse(_stream)
        .then((v) => completer.complete(v))
    );
    return completer.future;
  }
  
  Future send(object){
    var s = RedisSerialise.Serialise(object);
    return sendraw(s);
  }
  
  void disable_nagle(bool v){
    _socket.setOption(SocketOption.TCP_NODELAY,v);
  }

}