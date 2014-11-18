part of redis_parser;

class RedisConnection{
  Socket _socket = null;
  LazyStream _stream = null;
  Future _future = new Future.value();
  Future connect(host, port){
    RedisConnection _this = this;
    return Socket.connect(host, port)
    .then((Socket sock){
      _socket = sock;
      _socket.setOption(SocketOption.TCP_NODELAY,true);
      _stream =new LazyStream.fromstream(_socket.expand((v)=>(v)));
      return _this;
    });
  }
  
  Future sendstring(String lst){
    _socket.write(lst);
    Completer completer = new Completer();
    _future = _future.then((_) =>
        RedisParser.parseredisresponse(_stream)
        .then((v) => completer.complete(v))
    );
    return completer.future;
  }
  
  Future send(object){
    var s = RedisSerialise.Serialise(object);
    return sendstring(s);
  }
}