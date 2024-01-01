/*
 * Free software licenced under 
 * MIT License
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;

class _WarningConnection {
  noSuchMethod(_) => throw RedisRuntimeException("Transaction in progress. "
      "Please complete Transaction with .exec");
}

class Transaction extends Command {
  Queue<Completer> _queue = Queue();
  late Command _overrided_command;
  bool transaction_completed = false;

  Transaction(Command command) : super(command._connection) {
    _overrided_command = command;
    //we override his _connection, during transaction
    //it is best to point out where problem is
    command._connection = _WarningConnection();
  }

  Future send_object(object) {
    if (transaction_completed) {
      return Future.error(
          RedisRuntimeException("Transaction already completed."));
    }

    Completer c = Completer();
    _queue.add(c);
    super.send_object(object).then((msg) {
      if (msg.toString().toLowerCase() != "queued") {
        c.completeError(
            RedisException("Could not enqueue command: " + msg.toString()));
      }
    }).catchError((error) {
      c.completeError(error);
    });
    return c.future;
  }

  Future? discard() {
    _overrided_command._connection = this._connection;
    transaction_completed = true;
    return super.send_object(["DISCARD"]);
  }

  Future exec() {
    _overrided_command._connection = this._connection;
    transaction_completed = true;
    return super.send_object(["EXEC"]).then((list) {
      if (list == null || (list.length == 1 && list[0] == null)) {
        //we got explicit error from redis
        while (_queue.isNotEmpty) {
          _queue.removeFirst();
        }
        // return Future.error(TransactionException("transaction error "));
        throw TransactionException("transaction error ");
        //return null;
      } else {
        if (list.length != _queue.length) {
          int? diff = list.length - _queue.length;
          //return
          throw RedisRuntimeException(
              "There was $diff command(s) executed during transcation,"
              "not going trough Transation handler");
        }
        int len = list.length;
        for (int i = 0; i < len; ++i) {
          Completer c = _queue.removeFirst();
          c.complete(list[i]);
        }
        return "OK";
      }
    });
  }
}
