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
  noSuchMethod(_) => throw "Transaction in progress"
      "Please complete Transaction with .exec";
}

class Transaction extends Command{ 
  Queue<Completer> _queue = new Queue();
  RedisConnection _swaped_conn = null;
  Command _overrided_command;
  
  Transaction(Command command):super(command._connection){
    _overrided_command = command;
    //we override his _connection, during transaction (finding bugis easier) 
    command._connection = new _WarrningConnection();
  }
  
  Future _send(object){
    Completer c= new Completer();
    _queue.add(c);
    super._send(object).then((_){}); //todo handle error
    return c.future;
  }
  
  Future exec(){
    _overrided_command._connection = this._connection;
    return super._send(["EXEC"])
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

class TransationExecuter {
  List<String> _watchlist = null;
  Function _casf = null;
  Command _command = null;
  int _retries = 100;
  
  TransationExecuter(Command this._command){}
  
  TransationExecuter watch(List<String> list){
    _watchlist = list;
    return this;
  }
  
  TransationExecuter multi(Function f){
    _casf = f;
    return this;
  }
  
  void maxRetries(int retries){_retries = retries;}
  
  Future< List<Future> > exec(List<Object> send_objects){
    Completer completer = new Completer();
    List returnlist = new List();
    int retries_counter = _retries;
    Future.doWhile((){
      Future future = new Future(()=>"OK");
      if(_watchlist != null ){
        List watch_cmd = ["WATCH"]
        ..addAll(_watchlist);
        future = _command.send_object(watch_cmd);
      }
      if(_casf != null){
        future = future.then((_)=> _casf);
      }
      return future.then((_){
        returnlist.clear();
        return _command.multi().then((Transaction trans){
          for(var cmd in send_objects){
            returnlist.add(trans.send_object(cmd));
          }
          return trans.exec().then((v){
            if(v == "OK"){
              return false; //terminate doWhile
            }
            retries_counter --;
            return retries_counter != 0;
          }); 
        });
      });
    }).then((_){ //when doWhile completes
      if( retries_counter == 0){
        completer.completeError("Transaction could not complete after $_retries retries");
      }
      else{
        completer.complete(returnlist);
      }
    });
    return completer.future;
  }
}
