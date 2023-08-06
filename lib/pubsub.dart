part of redis;

class _WarningPubSubInProgress extends RedisConnection {
  RedisConnection _connection;
  _WarningPubSubInProgress(this._connection) {}

  _err() => throw "PubSub on this connection in progress"
      "It is not allowed to issue commands trough this handler";

  // swap this relevant methods in connection with exception
  // ignore: unused_element
  Future _sendraw(Parser parser, List<int> data) => _err();

  // ignore: unused_element
  Future _getdummy() => _err();
  Future _senddummy(Parser parser) => _err();

  // this fake PubSub connection can be closed
  Future close() {
    return this._connection.close();
  }
}

class PubSub {
  late Command _command;
  Map<List<String>, void Function(dynamic, String?)> _onMessageListeners = {};

  bool streamAlreadyListened = false;

  StreamController<List> _stream_controller = StreamController<List>();

  PubSub(Command command) {
    _command = Command.from(command);
    command.send_nothing()!.then((_) {
      //override socket with warning
      command._connection = _WarningPubSubInProgress(_command._connection);
      // listen and process forever
      return Future.doWhile(() {
        return _command._connection
            ._senddummy(_command.parser)
            .then<bool>((var data) {
          try {
            _stream_controller.add(data);
            return true; // run doWhile more
          } catch (e) {
            try {
              _stream_controller.addError(e);
            } catch (_) {
              // we could not notify stream that we have error
            }
            // stop doWhile()
            _stream_controller.close();
            return false;
          }
        }).catchError((e) {
          try {
            _stream_controller.addError(e);
          } catch (_) {
            // we could not notify stream that we have error
          }
          // stop doWhile()
          _stream_controller.close();
          return false;
        });
      });
    });
  }

  Stream getStream() {
    return _stream_controller.stream;
  }

  /// Subscribes the client to the specified channels.
  /// ```
  /// subscriber.subscribe(['chat']);
  /// subscriber.subscribe(['chat'],
  ///   onMessage: (dynamic message, String? channel) {
  ///     print(message);
  ///     print(channel);
  ///   },
  /// );
  /// ```
  /// If you would like to handle on message via Stream,
  /// onMessage callback can be optional
  void subscribe(List<String> s,
      {void Function(dynamic message, String? channel)? onMessage}) {
    _sendCommandAndList("SUBSCRIBE", s);
    if (onMessage != null) {
      /// register onMessage callback to `_onMessageListeners`
      _onMessageListeners[s] = onMessage;
      _listenForNewMessage();
    }
  }

  /// handle new message via stream and
  /// return result to registered onMessage callbacks.
  void _listenForNewMessage() {
    if (streamAlreadyListened) return;
    streamAlreadyListened = true;
    getStream().listen((msg) {
      var kind = msg[0];
      if (kind != 'message') return;
      var channel = msg[1];
      var message = msg[2];
      Function(dynamic, String?)? onMessageCallback =
          _findOnMessageCallback(channel);
      if (onMessageCallback != null) {
        onMessageCallback(message, channel);
      }
    });
  }

  /// get onMessage callback related to the cannel
  Function(dynamic, String?)? _findOnMessageCallback(String? channel) {
    List<List<String>> channelsLists = _onMessageListeners.keys.toList();
    channelsLists =
        channelsLists.where((element) => element.contains(channel)).toList();
    if (channelsLists.isNotEmpty) {
      List<String>? channels = channelsLists.first;
      return _onMessageListeners[channels];
    }
    return null;
  }

  void psubscribe(List<String> s) {
    _sendCommandAndList("PSUBSCRIBE", s);
  }

  void unsubscribe(List<String> s) {
    _sendCommandAndList("UNSUBSCRIBE", s);
  }

  void punsubscribe(List<String> s) {
    _sendCommandAndList("PUNSUBSCRIBE", s);
  }

  void _sendCommandAndList(String cmd, List<String> s) {
    List list = [cmd];
    list.addAll(s);
    _command._connection._socket.add(_command.serializer.serialize(list));
  }
}
