part of redis;

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
      _stream =new LazyStreamFast.fromstream(_socket);
      return _this;
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
  
  void pipe_start(){
    _socket.setOption(SocketOption.TCP_NODELAY,false);
  }
  void pipe_end(){
    _socket.setOption(SocketOption.TCP_NODELAY,true);
  }
}