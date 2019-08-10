/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;

class _WarningConnection {
  noSuchMethod(_) =>
      throw RedisError("Transaction in progress. "
          "Please complete Transaction with .exec");
}

class Transaction extends Command{ 
  Queue<Completer> _queue = new Queue();
  Command _overrided_command;
  bool transaction_completed = false;
  
  Transaction(Command command):super(command._connection){
    _overrided_command = command;
    //we override his _connection, during transaction 
    //it is best to point out where problem is
    command._connection = new _WarningConnection();

  }
  
  Future send_object(object){
    if (transaction_completed) {
      throw RedisError("Transaction already completed.");
    }

    Completer c= new Completer();
    _queue.add(c);
    super.send_object(object).then((msg) {
      if (msg.toString().toLowerCase() != "queued") {
        c.completeError(
            RedisError("Could not enqueue command: " + msg.toString()));
      }
    }, onError: (error) => c.completeError(error));
    return c.future;
  }
  
  Future exec(){
    _overrided_command._connection = this._connection;
    transaction_completed = true;
    return super.send_object(["EXEC"])
    .then((list){
      
      if(list == null){ //we got explicit error from redis
        while(_queue.isNotEmpty){
          Completer c =_queue.removeFirst();
          c.complete(new RedisError("Transaction terminated"));
          return null;
        }
        return null;
      }
      else{
        if(list.length != _queue.length){
          int diff = list.length - _queue.length;
          throw RedisError(
              "There was $diff command(s) executed during transcation,"
                  "not going trough Transation handler");
        }
        int len = list.length;
        for(int i=0;i<len;++i){
          Completer c =_queue.removeFirst();
          c.complete(list[i]);
        }
        return "OK";
      }
    });
  }
}
