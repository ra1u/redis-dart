part of redis;

class _WarrningPubSubInProgress {
  noSuchMethod(_) => throw "PubSub on this connaction in progress"
      "It is not allowed to issue commands trough this handler";
}

class PubSub {
  late Command _command;
  StreamController<List> _stream_controler = StreamController<List>();

  PubSub(Command command) {
    _command = Command.from(command);
    command.send_nothing()!.then((_) {
      //override socket with warrning
      command._connection = _WarrningPubSubInProgress();
      // listen and process forever
      return Future.doWhile(() {
        return _command._connection._senddummy(_command.parser).then<bool>((var data) {
          _stream_controler.add(data);
          return true;
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
    _command._connection._socket.add(RedisSerialise.Serialise(list));
  }
}
