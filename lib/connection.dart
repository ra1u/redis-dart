/*
 * Free software licenced under 
 * MIT License
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;

/// Class for server connection on server
class RedisConnection {
  Socket? _socket;
  LazyStream? _stream;
  Future _future = Future.value();
  RedisParser parser = RedisParser();

  /// connect on Redis server as client
  Future<Command> connect(host, port) {
    return Socket.connect(host, port).then((Socket sock) {
      _socket = sock;
      disable_nagle(true);
      _stream = LazyStream.fromstream(_socket!);
      return Command(this);
    });
  }

  /// connect on Redis server as client
  Future<Command> connectSecure(host, port) {
    return SecureSocket.connect(host, port).then((SecureSocket sock) {
      _socket = sock;
      disable_nagle(true);
      _stream = LazyStream.fromstream(_socket!);
      return Command(this);
    });
  }

  // connect with custom socket
  Future<Command> connectWithSocket(Socket s) async {
    _socket = s;
    disable_nagle(true);
    _stream = LazyStream.fromstream(_socket!);
    return Command(this);
  }

  /// close connection to Redis server
  Future close() {
    _stream!.close();
    return _socket!.close();
  }

  //this doesnt send anything
  //it just wait something to come from socket
  //it parse it and execute future
  Future _senddummy(Parser parser) {
    _future = _future.then((_) {
      return parser.parse(_stream!);
    });
    return _future;
  }

  // return future that complets
  // when all prevous _future finished
  // ignore: unused_element
  Future _getdummy() {
    _future = _future.then((_) {
      return "dummy data";
    });
    return _future;
  }

  // ignore: unused_element
  Future _sendraw(Parser parser, List<int> data) {
    _socket!.add(data);
    return _senddummy(parser);
  }

  void disable_nagle(bool v) {
    _socket!.setOption(SocketOption.tcpNoDelay, v);
  }
}
