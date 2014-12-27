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

  Command(this._connection){}
  
  Future _send(Object ls) => _connection._sendraw(RedisSerialise.Serialise(ls));
  
  /// Serialise and send data to server  
  /// 
  /// Data can be any object recognised by Redis
  /// List, integer, Bulk, null 
  /// Redis command is List<String>
  /// example SET
  /// 
  ///     send_object(["SET","key","value"]);
  Future send_object(Object v) => _send(v);
  
  /// return future that completes when
  /// all prevous packets are processed
  Future send_nothing() => _connection._getdummy();
  
  /// Set socket settings for sending transations
  /// 
  ///  This is optimisation and not requrement. 
  void pipe_start() => _connection.disable_nagle(false); //we want to use sockets buffering
  /// Requred to be called after last piping command
  void pipe_end() =>   _connection.disable_nagle(true);
  
  //commands in future, we will add more commands
  Future set(String key, String value) => _send(["SET",key,value]);
  Future get(String key) => _send(["GET",key]);
  
  /// Transations are started with multi and completed with exec()
  Future<Transaction> multi(){ //multi retun transation as future
    return _send(["MULTI"]).then((_) => new Transaction(this));
  }
  
}
  