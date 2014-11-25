part of redis;


class Transation{
    RedisConnection _conn;
    Queue<Completer> _queue;
    Transation(this._conn){
      _queue = new Queue();
    }
    
    Future multi(){
      return _conn.send(["MULTI"]);
    }

    Future send(object){
      Completer c= new Completer();
      _queue.add(c);
      _conn.send(object).then((_){}); //todo handle error
      return c.future;
    }
    
    Future exec(){
      Completer completer= new Completer();
      _conn.send(["EXEC"])
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