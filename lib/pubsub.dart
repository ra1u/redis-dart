part of redis;

class _WarrningPubSubInProgress extends RedisConnection {
  RedisConnection _connection;
  _WarrningPubSubInProgress(this._connection) {}
  
  _err() => throw "PubSub on this connaction in progress"
    "It is not allowed to issue commands trough this handler";

  // swap this relevant methods in Conenction with exception
  Future _sendraw(Parser parser,List<int> data) => _err();
  Future _getdummy() => _err();
  Future _senddummy(Parser parser) => _err();

  // this fake PubSub connection can be closed
  Future close() {
    return this._connection.close();
  }  
}

class PubSub {
  late Command _command;
  StreamController<List> _stream_controler = StreamController<List>();

  PubSub(Command command) {
    _command = Command.from(command);
    command.send_nothing()!.then((_) {
      //override socket with warrning
      command._connection = _WarrningPubSubInProgress(_command._connection);
      // listen and process forever
      return Future.doWhile(() {
        return _command._connection._senddummy(_command.parser).then<bool>((var data) {
           try{
             _stream_controler.add(data);
             return true; // run doWhile more
           } catch(e){
             try{
               _stream_controler.addError(e);
             } catch(_){
               // we could not notfy stream that we have eror
             }
             // stop doWhile()
             return false;
           }
        }).catchError((e){
          try{
            _stream_controler.addError(e);
          } catch(_){
            // we could not notfy stream that we have eror
          }
          // stop doWhile()
          return false;
        });
      });
    });
  }

  Stream getStream() {
    return _stream_controler.stream;
  }

  void subscribe(List<String> s) {
    _sendcmd_and_list("SUBSCRIBE", s);
  }

  void psubscribe(List<String> s) {
    _sendcmd_and_list("PSUBSCRIBE", s);
  }

  void unsubscribe(List<String> s) {
    _sendcmd_and_list("UNSUBSCRIBE", s);
  }

  void punsubscribe(List<String> s) {
    _sendcmd_and_list("PUNSUBSCRIBE", s);
  }

  void _sendcmd_and_list(String cmd, List<String> s) {
    List list = [cmd];
    list.addAll(s);
    _command._connection._socket.add(_command.serializer.serialize(list));
  }
}
