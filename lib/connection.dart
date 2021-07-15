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
  final Socket _socket;
  final LazyStream _stream;
  var _future = Future.value();

  /// create a RedisConnection and return a Command
  static Future<Command> connect(host, int port) async {
    return Command._(RedisConnection._(await Socket.connect(host, port)));
  }

  /// create a secure RedisConnection and return a Command
  static Future<Command> connectSecure(host, int port) async {
    return Command._(RedisConnection._(await SecureSocket.connect(host, port)));
  }

  /// private constructor
  RedisConnection._(this._socket) : _stream = LazyStream.fromstream(_socket) {
    disable_nagle(true);
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
  // ignore: unused_element
  Future _getdummy() {
    _future = _future.then((_) {
      return "dummy data";
    });
    return _future;
  }

  // ignore: unused_element
  Future _sendraw(List<int> data) {
    _socket.add(data);
    return _senddummy();
  }

  void disable_nagle(bool v) {
    _socket.setOption(SocketOption.tcpNoDelay, v);
  }
}
