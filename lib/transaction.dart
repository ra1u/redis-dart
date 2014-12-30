/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;

class _WarrningConnection {
  noSuchMethod(_) => throw "Transaction in progress. "
      "Please complete Transaction with .exec";
}

class Transaction extends Command{ 
  Queue<Completer> _queue = new Queue();
  RedisConnection _swaped_conn = null;
  Command _overrided_command;
  
  Transaction(Command command):super(command._connection){
    _overrided_command = command;
    //we override his _connection, during transaction 
    //it is best to point out where problem is
    command._connection = new _WarrningConnection();
  }
  
  Future send_object(object){
    Completer c= new Completer();
    _queue.add(c);
    super.send_object(object).then((_){}); //todo handle error
    return c.future;
  }
  
  Future exec(){
    _overrided_command._connection = this._connection;
    return super.send_object(["EXEC"])
    .then((list){
      
      if(list == null){ //we got explicit error from redis
        while(_queue.isNotEmpty){
          Completer c =_queue.removeFirst();
          c.complete(new RedisError("transation terminated"));
          return null;
        }
      }
      else{
        if(list.length != _queue.length){
          int diff = list.length - _queue.length;
          throw "There was $diff command(s) executed during transcation,"
                 "not going trough Transation handler";
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
