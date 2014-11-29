/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;

class Transaction extends Command{ 
    Queue<Completer> _queue;
    Transaction(RedisConnection conn):super(conn){
      _queue = new Queue();
    }

    Future _send(object){
      Completer c= new Completer();
      _queue.add(c);
      super._send(object).then((_){}); //todo handle error
      return c.future;
    }
    
    Future exec(){
      Completer completer= new Completer();
      super._send(["EXEC"])
      .then((list){
        assert(list is List);
        assert(list.length == _queue.length);
        int len = list.length;
        for(int i=0;i<len;++i){
          Completer c =_queue.removeFirst();
          c.complete(list[i]);
       }
        completer.complete(null);
      });
      return completer.future;
    }
}