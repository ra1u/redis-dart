/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;

class Command {
  /*RedisConnection*/ var _connection;

  Command(this._connection) {}

  /// get connection
  RedisConnection get connection => _connection;

  /// Serialise and send data to server
  ///
  /// Data can be any object recognised by Redis
  /// List, integer, Bulk, null and composite of those
  /// Redis command is List<String>
  ///
  /// example SET:
  ///     send_object(["SET","key","value"]);
  Future send_object(Object obj) {
    try {
      // RedisSerialise.Serialise
      return _connection._sendraw(RedisSerialise.Serialise(obj));
    } catch (e) {
      return Future.error(e);
    }
  }

  /// return future that completes when
  /// all prevous packets are processed
  Future? send_nothing() => _connection._getdummy();

  /// Set socket settings for sending transations
  ///
  ///  This is optimisation and not requrement.
  void pipe_start() =>
      _connection.disable_nagle(false); //we want to use sockets buffering
  /// Requred to be called after last piping command
  void pipe_end() => _connection.disable_nagle(true);

  /// Set String value given a key
  Future set(String key, String value) => send_object(["SET", key, value]);

  /// Get value given a key
  Future get(String key) => send_object(["GET", key]);

  /// Transations are started with multi and completed with exec()
  Future<Transaction> multi() {
    //multi retun transation as future
    return send_object(["MULTI"]).then((_) => Transaction(this));
  }
}
