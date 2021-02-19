/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;

/// Class for server connection on server
class RedisConnection {
  Socket _socket = null;
  LazyStream _stream = null;
  Future _future = new Future.value();
  RedisParser parser = new RedisParser();

  /// connect on Redis server as client
  Future<Command> connect(host, port) {
    return Socket.connect(host, port).then((Socket sock) {
      _socket = sock;
      disable_nagle(true);
      _stream = new LazyStream.fromstream(_socket);
      return new Command(this);
    });
  }

  /// connect on Redis server as client
  Future<Command> connectSecure(host, port) {
    return SecureSocket.connect(host, port).then((SecureSocket sock) {
      _socket = sock;
      disable_nagle(true);
      _stream = new LazyStream.fromstream(_socket);
      return new Command(this);
    });
  }

  /// close connection to Redis server
  Future close() {
    _stream.close();
    return _socket.close();
  }

  //this doesnt send anything
  //it just wait something to come from socket
  //it parse it and execute future
  Future _senddummy() {
    _future = _future.then((_) {
      return RedisParser.parseredisresponse(_stream);
    });
    return _future;
  }

  // return future that complets
  // when all prevous _future finished
  Future _getdummy() {
    _future = _future.then((_) {
      return "dummy data";
    });
    return _future;
  }

  Future _sendraw(List data) {
    _socket.add(data);
    return _senddummy();
  }

  void disable_nagle(bool v) {
    _socket.setOption(SocketOption.TCP_NODELAY, v);
  }
}
